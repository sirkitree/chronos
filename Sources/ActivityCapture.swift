import Foundation
import AppKit
import Cocoa

final class ActivityCapture: @unchecked Sendable {
    private let database: Database
    private let accessibilityCapture: AccessibilityCapture
    private var isMonitoring = false
    private var lastActiveApp: AppInfo?
    private var timer: Timer?
    
    init(database: Database) {
        self.database = database
        self.accessibilityCapture = AccessibilityCapture()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("Starting activity monitoring...")
        
        // Set up NSWorkspace notifications
        setupWorkspaceNotifications()
        
        // Start periodic polling
        startPeriodicPolling()
        
        // Capture initial state
        captureCurrentActivity()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        print("Stopping activity monitoring...")
        
        // Remove notifications
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        // Stop timer
        timer?.invalidate()
        timer = nil
    }
    
    private func setupWorkspaceNotifications() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Monitor app activation
        notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
        
        // Monitor app deactivation
        notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppDeactivation(notification)
        }
        
        // Monitor app launch
        notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunch(notification)
        }
        
        // Monitor app termination
        notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppTermination(notification)
        }
    }
    
    private func startPeriodicPolling() {
        // Poll every 5 seconds to ensure we don't miss anything
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.captureCurrentActivity()
        }
    }
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appInfo = AppInfo(
            bundleId: app.bundleIdentifier ?? "unknown",
            name: app.localizedName ?? "Unknown App"
        )
        
        logActivity(app: appInfo, isActive: true)
        lastActiveApp = appInfo
    }
    
    private func handleAppDeactivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appInfo = AppInfo(
            bundleId: app.bundleIdentifier ?? "unknown",
            name: app.localizedName ?? "Unknown App"
        )
        
        logActivity(app: appInfo, isActive: false)
    }
    
    private func handleAppLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appInfo = AppInfo(
            bundleId: app.bundleIdentifier ?? "unknown",
            name: app.localizedName ?? "Unknown App"
        )
        
        print("App launched: \(appInfo.name)")
    }
    
    private func handleAppTermination(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let appInfo = AppInfo(
            bundleId: app.bundleIdentifier ?? "unknown",
            name: app.localizedName ?? "Unknown App"
        )
        
        print("App terminated: \(appInfo.name)")
    }
    
    private func captureCurrentActivity() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        let appInfo = AppInfo(
            bundleId: frontmostApp.bundleIdentifier ?? "unknown",
            name: frontmostApp.localizedName ?? "Unknown App"
        )
        
        // Only log if this is a different app than before
        if lastActiveApp?.bundleId != appInfo.bundleId {
            logActivity(app: appInfo, isActive: true)
            lastActiveApp = appInfo
        }
    }
    
    private func logActivity(app: AppInfo, isActive: Bool) {
        // Try to get window title using Accessibility API
        let windowTitle = accessibilityCapture.hasPermission() ? 
            accessibilityCapture.getFrontmostWindowTitle() : nil
        
        let event = ActivityEvent(
            app: app,
            window: windowTitle,
            url: nil,    // Will be filled in by browser integration later
            isActive: isActive,
            isAFK: false // Will be determined by idle detection later
        )
        
        let success = database.insertActivity(
            timestamp: event.timestamp,
            bundleId: event.app.bundleId,
            appName: event.app.name,
            windowTitle: event.window,
            url: event.url,
            isAfk: event.isAFK
        )
        
        if success {
            print("Logged activity: \(app.name) (\(isActive ? "active" : "inactive"))")
        } else {
            print("Failed to log activity for: \(app.name)")
        }
    }
    
    func getCurrentApp() -> AppInfo? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        return AppInfo(
            bundleId: frontmostApp.bundleIdentifier ?? "unknown",
            name: frontmostApp.localizedName ?? "Unknown App"
        )
    }
    
    func getRunningApps() -> [AppInfo] {
        return NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular else { return nil }
            
            return AppInfo(
                bundleId: app.bundleIdentifier ?? "unknown",
                name: app.localizedName ?? "Unknown App"
            )
        }
    }
}