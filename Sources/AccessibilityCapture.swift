import Foundation
import ApplicationServices
import AppKit

class AccessibilityCapture {
    private var hasAccessibilityPermission = false
    
    init() {
        _ = checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() -> Bool {
        hasAccessibilityPermission = AXIsProcessTrusted()
        return hasAccessibilityPermission
    }
    
    func requestAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        
        if !hasAccessibilityPermission {
            print("Accessibility permission required. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility")
            print("Note: You may need to add this application to the Accessibility list manually.")
        }
    }
    
    func getWindowTitle(for app: NSRunningApplication) -> String? {
        guard hasAccessibilityPermission else {
            return nil
        }
        
        guard app.bundleIdentifier != nil else {
            return nil
        }
        
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success,
              let windows = windowsRef as? [AXUIElement],
              !windows.isEmpty else {
            return nil
        }
        
        // Get the first window (usually the frontmost)
        let firstWindow = windows[0]
        
        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(firstWindow, kAXTitleAttribute as CFString, &titleRef)
        
        guard titleResult == .success,
              let title = titleRef as? String else {
            return nil
        }
        
        return title
    }
    
    func getFrontmostWindowTitle() -> String? {
        guard hasAccessibilityPermission else {
            return nil
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        return getWindowTitle(for: frontmostApp)
    }
    
    func getWindowInfo(for app: NSRunningApplication) -> WindowInfo? {
        guard hasAccessibilityPermission else {
            return nil
        }
        
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success,
              let windows = windowsRef as? [AXUIElement],
              !windows.isEmpty else {
            return nil
        }
        
        let firstWindow = windows[0]
        
        // Get window title
        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(firstWindow, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleResult == .success) ? (titleRef as? String) : nil
        
        // Get window position
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(firstWindow, kAXPositionAttribute as CFString, &positionRef)
        var position: CGPoint = .zero
        
        if positionResult == .success,
           let positionValue = positionRef {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }
        
        // Get window size
        var sizeRef: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(firstWindow, kAXSizeAttribute as CFString, &sizeRef)
        var size: CGSize = .zero
        
        if sizeResult == .success,
           let sizeValue = sizeRef {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        return WindowInfo(
            title: title,
            position: position,
            size: size,
            isMainWindow: true
        )
    }
    
    func hasPermission() -> Bool {
        return hasAccessibilityPermission
    }
}

struct WindowInfo {
    let title: String?
    let position: CGPoint
    let size: CGSize
    let isMainWindow: Bool
}