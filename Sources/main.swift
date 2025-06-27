import Foundation

print("ChronoGuard - Privacy-first activity tracker")
print("Initializing database...")

let database = Database()
print("Database initialized with \(database.getActivityCount()) existing activity records")

// Test database functionality
let testApp = AppInfo(bundleId: "com.apple.Terminal", name: "Terminal")
let testEvent = ActivityEvent(app: testApp, window: "Terminal — zsh", isActive: true, isAFK: false)

if database.insertActivity(
    timestamp: testEvent.timestamp,
    bundleId: testEvent.app.bundleId,
    appName: testEvent.app.name,
    windowTitle: testEvent.window,
    url: testEvent.url,
    isAfk: testEvent.isAFK
) {
    print("Successfully logged test activity")
} else {
    print("Failed to log test activity")
}

print("Total records: \(database.getActivityCount())")

// Show today's summary
let today = DateFormatter().string(from: Date())
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd"
let todayString = formatter.string(from: Date())

let summary = database.getDailySummary(date: todayString)
print("\nToday's activity summary:")
for (app, seconds) in summary {
    let minutes = seconds / 60
    print("  \(app): \(minutes) minutes")
}

database.close()
