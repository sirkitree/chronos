import Foundation
import AppKit

print("ChronoGuard - Privacy-first activity tracker v0.1.0")
print("===================================================")

// Handle command line arguments
let args = CommandLine.arguments
if args.contains("--check-permissions") {
    let permissionManager = PermissionManager()
    permissionManager.printPermissionStatus()
    exit(0)
}

if args.contains("--setup-permissions") {
    let permissionManager = PermissionManager()
    permissionManager.requestAllPermissions()
    exit(0)
}

print("Initializing database...")
let database = Database()
print("Database initialized with \(database.getActivityCount()) existing activity records")

// Check permissions
let permissionManager = PermissionManager()
let permissions = permissionManager.getPermissionStatus()

print("\nPermission Status:")
print("- Accessibility: \(permissions.accessibility ? "✅ Granted" : "❌ Denied")")
print("- Automation: \(permissions.automation ? "✅ Granted" : "❌ Denied")")

if !permissions.accessibility {
    print("\n⚠️  Limited functionality without Accessibility permission")
    print("Run with --setup-permissions to configure")
}

// Initialize activity capture and idle detection
let activityCapture = ActivityCapture(database: database)
let idleDetection = IdleDetection()

print("\nCurrent running apps:")
let runningApps = activityCapture.getRunningApps()
for app in runningApps.prefix(5) {
    print("  - \(app.name) (\(app.bundleId))")
}

if let currentApp = activityCapture.getCurrentApp() {
    print("\nCurrently active app: \(currentApp.name)")
    
    // Check if user is idle
    let isIdle = idleDetection.isUserIdle()
    let idleTime = idleDetection.getIdleTime()
    print("User idle status: \(isIdle ? "IDLE" : "ACTIVE") (idle for \(Int(idleTime))s)")
}

print("\nStarting 30-second monitoring demo...")
print("(Press Ctrl+C to stop early)")
activityCapture.startMonitoring()

// Set up signal handling for graceful shutdown
signal(SIGINT) { _ in
    print("\nShutting down gracefully...")
    exit(0)
}

// Run for 30 seconds to demonstrate
DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
    activityCapture.stopMonitoring()
    
    // Show updated summary
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())
    
    let summary = database.getDailySummary(date: todayString)
    print("\nToday's activity summary:")
    for (app, seconds) in summary {
        let minutes = seconds / 60
        print("  \(app): \(minutes) minutes")
    }
    
    print("\nTotal records: \(database.getActivityCount())")
    print("Demo completed successfully!")
    database.close()
    exit(0)
}

// Keep the app running
RunLoop.main.run()
