import Foundation
import SQLite

class Database {
    private var db: Connection?
    private let dbPath: String
    
    // Table definitions
    private let activity = Table("activity")
    private let id = Expression<Int64>("id")
    private let timestamp = Expression<Int64>("timestamp")
    private let appBundleId = Expression<String>("app_bundle_id")
    private let appName = Expression<String>("app_name")
    private let windowTitle = Expression<String?>("window_title")
    private let url = Expression<String?>("url")
    private let isAfk = Expression<Bool>("is_afk")
    
    init(path: String = "chronoguard.db") {
        self.dbPath = path
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            db = try Connection(dbPath)
            createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }
    
    private func createTables() {
        do {
            try db?.run(activity.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(timestamp)
                table.column(appBundleId)
                table.column(appName)
                table.column(windowTitle)
                table.column(url)
                table.column(isAfk, defaultValue: false)
                table.unique([timestamp, appBundleId])
            })
            
            // Create indexes for performance
            try db?.run("CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON activity(timestamp)")
            try db?.run("CREATE INDEX IF NOT EXISTS idx_activity_app_bundle_id ON activity(app_bundle_id)")
            try db?.run("CREATE INDEX IF NOT EXISTS idx_activity_date ON activity(date(timestamp, 'unixepoch'))")
            
            // Create daily summary view
            try db?.run("""
                CREATE VIEW IF NOT EXISTS daily_summary AS
                SELECT 
                    strftime('%Y-%m-%d', timestamp, 'unixepoch') AS day,
                    app_name,
                    app_bundle_id,
                    SUM(CASE WHEN NOT is_afk THEN 300 ELSE 0 END) AS seconds_active,
                    COUNT(*) AS event_count
                FROM activity
                GROUP BY day, app_bundle_id
                ORDER BY day DESC, seconds_active DESC
            """)
            
        } catch {
            print("Table creation failed: \(error)")
        }
    }
    
    func insertActivity(timestamp: Int64, bundleId: String, appName: String, windowTitle: String? = nil, url: String? = nil, isAfk: Bool = false) -> Bool {
        do {
            let insert = activity.insert(or: .ignore,
                self.timestamp <- timestamp,
                self.appBundleId <- bundleId,
                self.appName <- appName,
                self.windowTitle <- windowTitle,
                self.url <- url,
                self.isAfk <- isAfk
            )
            try db?.run(insert)
            return true
        } catch {
            print("Insert failed: \(error)")
            return false
        }
    }
    
    func getDailySummary(date: String) -> [(app: String, seconds: Int64)] {
        var results: [(app: String, seconds: Int64)] = []
        
        do {
            let query = """
                SELECT app_name, seconds_active 
                FROM daily_summary 
                WHERE day = ? 
                ORDER BY seconds_active DESC
            """
            
            if let db = db {
                for row in try db.prepare(query, [date]) {
                    results.append((
                        app: row[0] as! String,
                        seconds: row[1] as! Int64
                    ))
                }
            }
        } catch {
            print("Daily summary query failed: \(error)")
        }
        
        return results
    }
    
    func getActivityCount() -> Int {
        do {
            return try db?.scalar(activity.count) ?? 0
        } catch {
            print("Count query failed: \(error)")
            return 0
        }
    }
    
    func close() {
        db = nil
    }
}