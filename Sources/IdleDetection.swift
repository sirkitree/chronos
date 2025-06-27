import Foundation
import CoreGraphics
import IOKit
import IOKit.pwr_mgt

class IdleDetection {
    private var lastEventTime: CFAbsoluteTime = 0
    private let idleThreshold: TimeInterval = 300 // 5 minutes in seconds
    
    init() {
        updateLastEventTime()
    }
    
    func isUserIdle() -> Bool {
        updateLastEventTime()
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeSinceLastEvent = currentTime - lastEventTime
        
        return timeSinceLastEvent > idleThreshold
    }
    
    func getIdleTime() -> TimeInterval {
        updateLastEventTime()
        let currentTime = CFAbsoluteTimeGetCurrent()
        return currentTime - lastEventTime
    }
    
    private func updateLastEventTime() {
        // Get system idle time using CGEventSource
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: .mouseMoved
        )
        
        let keyboardIdleTime = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: .keyDown
        )
        
        // Use the minimum idle time (most recent activity)
        let recentIdleTime = min(idleTime, keyboardIdleTime)
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        lastEventTime = currentTime - recentIdleTime
    }
    
    func getIdleThreshold() -> TimeInterval {
        return idleThreshold
    }
    
    func setIdleThreshold(_ threshold: TimeInterval) {
        // Note: This would normally update the threshold, but for now we keep it simple
        print("Idle threshold change requested: \(threshold)s (current: \(idleThreshold)s)")
    }
}