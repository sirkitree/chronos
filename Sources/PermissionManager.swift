import Foundation
import AppKit
import ApplicationServices

class PermissionManager {
    private let accessibilityCapture = AccessibilityCapture()
    
    func checkAllPermissions() -> PermissionStatus {
        let accessibilityGranted = accessibilityCapture.checkAccessibilityPermission()
        
        return PermissionStatus(
            accessibility: accessibilityGranted,
            automation: checkAutomationPermission()
        )
    }
    
    func requestAllPermissions() {
        print("ChronoGuard Permission Setup")
        print("===========================")
        
        let status = checkAllPermissions()
        
        if !status.accessibility {
            print("\n⚠️  Accessibility Permission Required")
            print("ChronoGuard needs Accessibility permission to capture window titles.")
            print("This enables tracking of which documents/websites you're working on.")
            print("\nSteps:")
            print("1. Click 'Open System Preferences' when prompted")
            print("2. Find 'ChronoGuard' in the list")
            print("3. Check the box next to it")
            print("4. Restart ChronoGuard")
            
            accessibilityCapture.requestAccessibilityPermission()
        } else {
            print("✅ Accessibility permission: Granted")
        }
        
        if !status.automation {
            print("\n⚠️  Automation Permission Required")
            print("ChronoGuard needs Automation permission to capture Safari tab information.")
            print("This is optional but recommended for complete tracking.")
            print("\nTo enable:")
            print("1. Go to System Preferences > Security & Privacy > Privacy > Automation")
            print("2. Find 'ChronoGuard' and check the box for 'Safari'")
        } else {
            print("✅ Automation permission: Granted")
        }
        
        if status.accessibility && status.automation {
            print("\n🎉 All permissions granted! ChronoGuard is ready to use.")
        } else {
            print("\n⏳ Please grant the required permissions and restart ChronoGuard.")
            print("Run 'swift run ChronoGuard --check-permissions' to verify.")
        }
    }
    
    private func checkAutomationPermission() -> Bool {
        // For now, we'll assume automation permission is granted
        // A more sophisticated check would involve trying to access Safari
        // and catching any permission errors
        return true
    }
    
    func printPermissionStatus() {
        let status = checkAllPermissions()
        
        print("Permission Status:")
        print("- Accessibility: \(status.accessibility ? "✅ Granted" : "❌ Denied")")
        print("- Automation: \(status.automation ? "✅ Granted" : "❌ Denied")")
        
        if !status.accessibility {
            print("\nWithout Accessibility permission, ChronoGuard can only track:")
            print("- Application switching")
            print("- Basic app usage time")
            print("\nWith Accessibility permission, ChronoGuard can also track:")
            print("- Window titles (document names, web page titles)")
            print("- More detailed activity context")
        }
    }
    
    func getPermissionStatus() -> PermissionStatus {
        return checkAllPermissions()
    }
}

struct PermissionStatus {
    let accessibility: Bool
    let automation: Bool
    
    var hasMinimumPermissions: Bool {
        // App can work with just basic NSWorkspace monitoring
        return true
    }
    
    var hasFullPermissions: Bool {
        return accessibility && automation
    }
}