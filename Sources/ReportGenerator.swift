import Foundation
import SQLite

class ReportGenerator {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func generateDailyReport(date: String) -> DailyReport {
        let summary = database.getDailySummary(date: date)
        let totalSeconds = summary.reduce(0) { $0 + $1.seconds }
        let totalMinutes = totalSeconds / 60
        let totalHours = Double(totalMinutes) / 60.0
        
        return DailyReport(
            date: date,
            totalActiveTime: TimeInterval(totalSeconds),
            appActivities: summary.map { AppActivity(name: $0.app, seconds: $0.seconds) },
            summary: DailySummary(
                totalHours: totalHours,
                topApps: summary.prefix(5).map { ($0.app, $0.seconds) },
                productivityScore: calculateProductivityScore(for: summary)
            )
        )
    }
    
    func generateWeeklyReport(startDate: String) -> WeeklyReport {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = dateFormatter.date(from: startDate) else {
            return WeeklyReport(weekStarting: startDate, dailyReports: [], weeklyTotals: [:])
        }
        
        var dailyReports: [DailyReport] = []
        var weeklyTotals: [String: Int64] = [:]
        
        for i in 0..<7 {
            let currentDate = Calendar.current.date(byAdding: .day, value: i, to: start)!
            let dateString = dateFormatter.string(from: currentDate)
            
            let dailyReport = generateDailyReport(date: dateString)
            dailyReports.append(dailyReport)
            
            // Aggregate weekly totals
            for activity in dailyReport.appActivities {
                weeklyTotals[activity.name, default: 0] += activity.seconds
            }
        }
        
        return WeeklyReport(
            weekStarting: startDate,
            dailyReports: dailyReports,
            weeklyTotals: weeklyTotals
        )
    }
    
    func generateProductivityReport(date: String) -> ProductivityReport {
        let summary = database.getDailySummary(date: date)
        
        let categorizedApps = categorizeApps(summary)
        let totalActiveTime = summary.reduce(0) { $0 + $1.seconds }
        
        let productiveTime = categorizedApps.productive.reduce(0) { $0 + $1.seconds }
        let neutralTime = categorizedApps.neutral.reduce(0) { $0 + $1.seconds }
        let distractingTime = categorizedApps.distracting.reduce(0) { $0 + $1.seconds }
        
        let productivityScore = totalActiveTime > 0 ? 
            Double(productiveTime) / Double(totalActiveTime) * 100 : 0
        
        return ProductivityReport(
            date: date,
            productivityScore: productivityScore,
            productiveTime: TimeInterval(productiveTime),
            neutralTime: TimeInterval(neutralTime),
            distractingTime: TimeInterval(distractingTime),
            topProductiveApps: categorizedApps.productive.prefix(3).map { $0.app },
            topDistractingApps: categorizedApps.distracting.prefix(3).map { $0.app }
        )
    }
    
    private func calculateProductivityScore(for activities: [(app: String, seconds: Int64)]) -> Double {
        let categorized = categorizeApps(activities)
        let totalTime = activities.reduce(0) { $0 + $1.seconds }
        let productiveTime = categorized.productive.reduce(0) { $0 + $1.seconds }
        
        return totalTime > 0 ? Double(productiveTime) / Double(totalTime) * 100 : 0
    }
    
    private func categorizeApps(_ activities: [(app: String, seconds: Int64)]) -> CategorizedApps {
        var productive: [(app: String, seconds: Int64)] = []
        var neutral: [(app: String, seconds: Int64)] = []
        var distracting: [(app: String, seconds: Int64)] = []
        
        for activity in activities {
            let category = AppCategory.categorize(appName: activity.app)
            switch category {
            case .productive:
                productive.append(activity)
            case .neutral:
                neutral.append(activity)
            case .distracting:
                distracting.append(activity)
            }
        }
        
        return CategorizedApps(
            productive: productive.sorted { $0.seconds > $1.seconds },
            neutral: neutral.sorted { $0.seconds > $1.seconds },
            distracting: distracting.sorted { $0.seconds > $1.seconds }
        )
    }
    
    func exportCSV(report: DailyReport) -> String {
        var csv = "App,Minutes,Hours,Percentage\n"
        let totalSeconds = report.totalActiveTime
        
        for activity in report.appActivities {
            let minutes = activity.seconds / 60
            let hours = Double(activity.seconds) / 3600.0
            let percentage = totalSeconds > 0 ? Double(activity.seconds) / totalSeconds * 100 : 0
            
            csv += "\"\(activity.name)\",\(minutes),\(String(format: "%.2f", hours)),\(String(format: "%.1f", percentage))\n"
        }
        
        return csv
    }
    
    func exportJSON(report: DailyReport) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(report)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to encode report\"}"
        }
    }
}

// MARK: - Data Models

struct DailyReport: Codable {
    let date: String
    let totalActiveTime: TimeInterval
    let appActivities: [AppActivity]
    let summary: DailySummary
}

struct WeeklyReport: Codable {
    let weekStarting: String
    let dailyReports: [DailyReport]
    let weeklyTotals: [String: Int64]
}

struct ProductivityReport: Codable {
    let date: String
    let productivityScore: Double
    let productiveTime: TimeInterval
    let neutralTime: TimeInterval
    let distractingTime: TimeInterval
    let topProductiveApps: [String]
    let topDistractingApps: [String]
}

struct AppActivity: Codable {
    let name: String
    let seconds: Int64
    
    var minutes: Int64 { seconds / 60 }
    var hours: Double { Double(seconds) / 3600.0 }
}

struct DailySummary: Codable {
    let totalHours: Double
    let topApps: [(String, Int64)]
    let productivityScore: Double
    
    private enum CodingKeys: String, CodingKey {
        case totalHours, productivityScore
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalHours, forKey: .totalHours)
        try container.encode(productivityScore, forKey: .productivityScore)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalHours = try container.decode(Double.self, forKey: .totalHours)
        productivityScore = try container.decode(Double.self, forKey: .productivityScore)
        topApps = [] // Simplified for decoding
    }
    
    init(totalHours: Double, topApps: [(String, Int64)], productivityScore: Double) {
        self.totalHours = totalHours
        self.topApps = topApps
        self.productivityScore = productivityScore
    }
}

struct CategorizedApps {
    let productive: [(app: String, seconds: Int64)]
    let neutral: [(app: String, seconds: Int64)]
    let distracting: [(app: String, seconds: Int64)]
}

enum AppCategory {
    case productive
    case neutral
    case distracting
    
    static func categorize(appName: String) -> AppCategory {
        let lowercased = appName.lowercased()
        
        // Productive apps
        if lowercased.contains("xcode") || 
           lowercased.contains("terminal") ||
           lowercased.contains("warp") ||
           lowercased.contains("iterm") ||
           lowercased.contains("sublime") ||
           lowercased.contains("code") ||
           lowercased.contains("intellij") ||
           lowercased.contains("notion") ||
           lowercased.contains("obsidian") ||
           lowercased.contains("figma") ||
           lowercased.contains("sketch") {
            return .productive
        }
        
        // Distracting apps
        if lowercased.contains("safari") ||
           lowercased.contains("chrome") ||
           lowercased.contains("youtube") ||
           lowercased.contains("netflix") ||
           lowercased.contains("slack") ||
           lowercased.contains("discord") ||
           lowercased.contains("telegram") ||
           lowercased.contains("whatsapp") ||
           lowercased.contains("twitter") ||
           lowercased.contains("facebook") ||
           lowercased.contains("instagram") {
            return .distracting
        }
        
        // Everything else is neutral
        return .neutral
    }
}