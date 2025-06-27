import Foundation

class CommandLineInterface {
    private let database: Database
    private let reportGenerator: ReportGenerator
    private let permissionManager: PermissionManager
    
    init() {
        self.database = Database()
        self.reportGenerator = ReportGenerator(database: database)
        self.permissionManager = PermissionManager()
    }
    
    func run() {
        let args = CommandLine.arguments
        
        // Handle version
        if args.contains("--version") || args.contains("-v") {
            printVersion()
            return
        }
        
        // Handle help
        if args.contains("--help") || args.contains("-h") {
            printHelp()
            return
        }
        
        // Handle permission commands
        if args.contains("--check-permissions") {
            permissionManager.printPermissionStatus()
            return
        }
        
        if args.contains("--setup-permissions") {
            permissionManager.requestAllPermissions()
            return
        }
        
        // Handle report commands
        if let reportIndex = args.firstIndex(of: "report") {
            handleReportCommand(args: Array(args.dropFirst(reportIndex + 1)))
            return
        }
        
        // Handle monitor command
        if args.contains("monitor") {
            handleMonitorCommand(args: args)
            return
        }
        
        // Handle native messaging
        if args.contains("--native-messaging") {
            handleNativeMessaging()
            return
        }
        
        // Handle Chrome extension installation
        if args.contains("--install-chrome-extension") {
            handleChromeExtensionInstall()
            return
        }
        
        // Default behavior - show help
        printUsage()
    }
    
    private func handleReportCommand(args: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        var date = today
        var format = "table"
        var reportType = "daily"
        
        // Parse arguments
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--date", "-d":
                if i + 1 < args.count {
                    date = args[i + 1]
                    i += 1
                }
            case "--format", "-f":
                if i + 1 < args.count {
                    format = args[i + 1]
                    i += 1
                }
            case "--type", "-t":
                if i + 1 < args.count {
                    reportType = args[i + 1]
                    i += 1
                }
            default:
                break
            }
            i += 1
        }
        
        switch reportType {
        case "daily":
            generateDailyReport(date: date, format: format)
        case "weekly":
            generateWeeklyReport(startDate: date, format: format)
        case "productivity":
            generateProductivityReport(date: date, format: format)
        default:
            print("Unknown report type: \(reportType)")
            print("Available types: daily, weekly, productivity")
        }
    }
    
    private func generateDailyReport(date: String, format: String) {
        let report = reportGenerator.generateDailyReport(date: date)
        
        switch format {
        case "json":
            print(reportGenerator.exportJSON(report: report))
        case "csv":
            print(reportGenerator.exportCSV(report: report))
        case "table", "default":
            printDailyReportTable(report: report)
        default:
            print("Unknown format: \(format)")
            print("Available formats: table, json, csv")
        }
    }
    
    private func generateWeeklyReport(startDate: String, format: String) {
        let report = reportGenerator.generateWeeklyReport(startDate: startDate)
        
        switch format {
        case "json":
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(report),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        case "table", "default":
            printWeeklyReportTable(report: report)
        default:
            print("Weekly reports support: table, json")
        }
    }
    
    private func generateProductivityReport(date: String, format: String) {
        let report = reportGenerator.generateProductivityReport(date: date)
        
        switch format {
        case "json":
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(report),
               let json = String(data: data, encoding: .utf8) {
                print(json)
            }
        case "table", "default":
            printProductivityReportTable(report: report)
        default:
            print("Productivity reports support: table, json")
        }
    }
    
    private func printDailyReportTable(report: DailyReport) {
        print("ChronoGuard Daily Report - \(report.date)")
        print(String(repeating: "=", count: 50))
        print("Total Active Time: \(formatDuration(report.totalActiveTime))")
        print("Productivity Score: \(String(format: "%.1f", report.summary.productivityScore))%")
        print()
        
        print("Application Activity:")
        print(String(repeating: "-", count: 50))
        print(String(format: "%-30s %10s %8s", "Application", "Time", "Percent"))
        print(String(repeating: "-", count: 50))
        
        for activity in report.appActivities.prefix(10) {
            let percentage = report.totalActiveTime > 0 ? 
                Double(activity.seconds) / report.totalActiveTime * 100 : 0
            print(String(format: "%-30s %10s %7.1f%%", 
                  String(activity.name.prefix(30)), 
                  formatDuration(TimeInterval(activity.seconds)),
                  percentage))
        }
        
        if report.appActivities.count > 10 {
            print("... and \(report.appActivities.count - 10) more applications")
        }
    }
    
    private func printWeeklyReportTable(report: WeeklyReport) {
        print("ChronoGuard Weekly Report - Week of \(report.weekStarting)")
        print(String(repeating: "=", count: 60))
        
        for dailyReport in report.dailyReports {
            print("\(dailyReport.date): \(formatDuration(dailyReport.totalActiveTime))")
        }
        
        print()
        print("Weekly Totals:")
        print(String(repeating: "-", count: 40))
        
        let sortedTotals = report.weeklyTotals.sorted { $0.value > $1.value }
        for (app, seconds) in sortedTotals.prefix(10) {
            print(String(format: "%-25s %s", String(app.prefix(25)), formatDuration(TimeInterval(seconds))))
        }
    }
    
    private func printProductivityReportTable(report: ProductivityReport) {
        print("ChronoGuard Productivity Report - \(report.date)")
        print(String(repeating: "=", count: 50))
        print("Productivity Score: \(String(format: "%.1f", report.productivityScore))%")
        print()
        
        print("Time Breakdown:")
        print("- Productive: \(formatDuration(report.productiveTime))")
        print("- Neutral: \(formatDuration(report.neutralTime))")
        print("- Distracting: \(formatDuration(report.distractingTime))")
        print()
        
        if !report.topProductiveApps.isEmpty {
            print("Top Productive Apps:")
            for app in report.topProductiveApps {
                print("  • \(app)")
            }
            print()
        }
        
        if !report.topDistractingApps.isEmpty {
            print("Top Distracting Apps:")
            for app in report.topDistractingApps {
                print("  • \(app)")
            }
        }
    }
    
    private func handleMonitorCommand(args: [String]) {
        var duration: TimeInterval = 30 // Default 30 seconds
        
        if let durationIndex = args.firstIndex(of: "--duration"),
           durationIndex + 1 < args.count,
           let parsedDuration = TimeInterval(args[durationIndex + 1]) {
            duration = parsedDuration
        }
        
        print("Starting ChronoGuard monitoring for \(Int(duration)) seconds...")
        print("Press Ctrl+C to stop early")
        
        let activityCapture = ActivityCapture(database: database)
        activityCapture.startMonitoring()
        
        // Set up signal handling
        signal(SIGINT) { _ in
            print("\nStopping monitoring...")
            exit(0)
        }
        
        // Run for specified duration using DispatchQueue.main.asyncAfter
        let targetDuration = duration
        DispatchQueue.main.asyncAfter(deadline: .now() + targetDuration) {
            activityCapture.stopMonitoring()
            print("Monitoring completed!")
            exit(0)
        }
        
        RunLoop.main.run()
    }
    
    private func handleNativeMessaging() {
        print("Starting ChronoGuard native messaging host...")
        
        let nativeHost = NativeMessagingHost(database: database)
        
        // Set up signal handling for graceful shutdown
        signal(SIGINT) { _ in
            print("\nShutting down native messaging host...")
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            print("\nShutting down native messaging host...")
            exit(0)
        }
        
        // Start the native messaging host
        nativeHost.startHost()
    }
    
    private func handleChromeExtensionInstall() {
        print("Installing Chrome extension native messaging manifest...")
        
        // Install the native messaging manifest
        NativeMessagingManifest.installManifest()
        
        print("✅ Native messaging manifest installed")
        print("")
        print("Next steps:")
        print("1. Install the Chrome extension from: ./chrome-extension/")
        print("2. Load it as an unpacked extension in Chrome Developer Mode")
        print("3. Grant any required permissions")
        print("4. The extension will automatically connect to ChronoGuard")
        print("")
        print("To start the native messaging host:")
        print("  chronoguard --native-messaging")
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func printVersion() {
        print("ChronoGuard v0.1.0")
        print("Privacy-first local activity tracker for macOS")
    }
    
    private func printUsage() {
        print("Usage: chronoguard [command] [options]")
        print()
        print("Commands:")
        print("  monitor                      Start activity monitoring")
        print("  report                       Generate activity reports")
        print("  --setup-permissions          Setup required macOS permissions")
        print("  --check-permissions          Check current permission status")
        print("  --native-messaging           Start native messaging host for Chrome extension")
        print("  --install-chrome-extension   Install Chrome extension manifest")
        print("  --help, -h                  Show this help message")
        print("  --version, -v               Show version information")
        print()
        print("For more details, run: chronoguard --help")
    }
    
    private func printHelp() {
        print("ChronoGuard - Privacy-first local activity tracker")
        print()
        printUsage()
        print()
        print("Monitor Options:")
        print("  --duration SECONDS   Set monitoring duration (default: 30)")
        print()
        print("Report Options:")
        print("  --type TYPE         Report type: daily, weekly, productivity")
        print("  --date DATE         Date in YYYY-MM-DD format (default: today)")
        print("  --format FORMAT     Output format: table, json, csv")
        print()
        print("Chrome Extension:")
        print("  --install-chrome-extension   Install native messaging manifest")
        print("  --native-messaging           Start host for Chrome extension")
        print()
        print("Examples:")
        print("  chronoguard monitor --duration 60")
        print("  chronoguard report --type daily --date 2025-06-27")
        print("  chronoguard report --type weekly --format json")
        print("  chronoguard report --type productivity --format csv")
        print("  chronoguard --install-chrome-extension")
        print("  chronoguard --native-messaging")
    }
}