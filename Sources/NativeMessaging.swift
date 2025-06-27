import Foundation

class NativeMessagingHost {
    private let database: Database
    private var isRunning = false
    
    init(database: Database) {
        self.database = database
    }
    
    func startHost() {
        guard !isRunning else { return }
        isRunning = true
        
        print("Starting native messaging host...")
        
        // Set up stdin/stdout for communication
        let stdin = FileHandle.standardInput
        let stdout = FileHandle.standardOutput
        
        // Send initial ready message
        sendMessage([
            "type": "ready",
            "message": "ChronoGuard native host ready",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ], to: stdout)
        
        // Start message processing loop
        processMessages(from: stdin, to: stdout)
    }
    
    private func processMessages(from input: FileHandle, to output: FileHandle) {
        while isRunning {
            do {
                // Read message length (first 4 bytes)
                let lengthData = input.readData(ofLength: 4)
                guard lengthData.count == 4 else {
                    print("Failed to read message length")
                    break
                }
                
                let messageLength = lengthData.withUnsafeBytes { bytes in
                    bytes.load(as: UInt32.self).littleEndian
                }
                
                // Read message content
                let messageData = input.readData(ofLength: Int(messageLength))
                guard messageData.count == messageLength else {
                    print("Failed to read complete message")
                    break
                }
                
                // Parse JSON message
                if let json = try JSONSerialization.jsonObject(with: messageData) as? [String: Any] {
                    handleMessage(json, output: output)
                }
                
            } catch {
                print("Error processing message: \(error)")
                break
            }
        }
    }
    
    private func handleMessage(_ message: [String: Any], output: FileHandle) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "tab_activity":
            handleTabActivity(message)
            
        case "page_load":
            handlePageLoad(message)
            
        case "page_visibility":
            handlePageVisibility(message)
            
        case "url_change":
            handleUrlChange(message)
            
        case "activity_check":
            handleActivityCheck(message)
            
        case "connection":
            handleConnection(message, output: output)
            
        case "open_app":
            handleOpenApp(output: output)
            
        case "open_reports":
            handleOpenReports(output: output)
            
        case "get_status":
            handleGetStatus(output: output)
            
        default:
            print("Unknown message type: \(type)")
        }
    }
    
    private func handleTabActivity(_ message: [String: Any]) {
        guard let url = message["url"] as? String,
              let title = message["title"] as? String,
              let timestamp = message["timestamp"] as? Int64 else {
            return
        }
        
        // Create Chrome app info
        let chromeApp = AppInfo(bundleId: "com.google.Chrome", name: "Google Chrome")
        
        // Store activity with URL information
        let success = database.insertActivity(
            timestamp: timestamp / 1000, // Convert from milliseconds
            bundleId: chromeApp.bundleId,
            appName: chromeApp.name,
            windowTitle: title,
            url: url,
            isAfk: false
        )
        
        if success {
            print("Logged Chrome activity: \(title)")
        }
    }
    
    private func handlePageLoad(_ message: [String: Any]) {
        // Page loads are handled as tab activities
        handleTabActivity(message)
    }
    
    private func handlePageVisibility(_ message: [String: Any]) {
        guard let visible = message["visible"] as? Bool else { return }
        
        // Could be used to track when user switches away from browser
        print("Page visibility changed: \(visible ? "visible" : "hidden")")
    }
    
    private func handleUrlChange(_ message: [String: Any]) {
        // URL changes in SPAs are handled as tab activities
        handleTabActivity(message)
    }
    
    private func handleActivityCheck(_ message: [String: Any]) {
        guard let isActive = message["isActive"] as? Bool else { return }
        
        // Could be used to update activity status
        if !isActive {
            print("User inactive in browser tab")
        }
    }
    
    private func handleConnection(_ message: [String: Any], output: FileHandle) {
        print("Chrome extension connected")
        
        // Send acknowledgment
        sendMessage([
            "type": "connection_ack",
            "message": "Connection established",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ], to: output)
    }
    
    private func handleOpenApp(output: FileHandle) {
        // This could bring the app to foreground or show a specific view
        print("Request to open app received")
        
        sendMessage([
            "type": "app_opened",
            "message": "App brought to foreground",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ], to: output)
    }
    
    private func handleOpenReports(output: FileHandle) {
        // This could open the reports view or generate a quick report
        print("Request to open reports received")
        
        // Generate today's quick stats
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let summary = database.getDailySummary(date: today)
        let totalMinutes = summary.reduce(0) { $0 + $1.seconds } / 60
        
        sendMessage([
            "type": "reports_data",
            "message": "Reports generated",
            "data": [
                "date": today,
                "totalMinutes": totalMinutes,
                "appCount": summary.count
            ],
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ], to: output)
    }
    
    private func handleGetStatus(output: FileHandle) {
        sendMessage([
            "type": "status_response",
            "connected": true,
            "message": "ChronoGuard is running",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ], to: output)
    }
    
    private func sendMessage(_ message: [String: Any], to output: FileHandle) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let messageLength = UInt32(jsonData.count).littleEndian
            
            // Write message length (4 bytes)
            let lengthData = withUnsafeBytes(of: messageLength) { Data($0) }
            output.write(lengthData)
            
            // Write message content
            output.write(jsonData)
            
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func stopHost() {
        isRunning = false
        print("Native messaging host stopped")
    }
}

// Native messaging manifest generator
class NativeMessagingManifest {
    static func generateManifest() -> [String: Any] {
        // Get the path to the ChronoGuard executable
        let executablePath = ProcessInfo.processInfo.arguments[0]
        
        return [
            "name": "com.chronoguard.native",
            "description": "ChronoGuard Native Messaging Host",
            "path": executablePath,
            "type": "stdio",
            "allowed_origins": [
                "chrome-extension://chronoguard-extension-id/"
            ]
        ]
    }
    
    static func installManifest() {
        let manifest = generateManifest()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
            
            // Get Chrome's native messaging hosts directory
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let manifestsDir = homeDir
                .appendingPathComponent("Library")
                .appendingPathComponent("Application Support")
                .appendingPathComponent("Google")
                .appendingPathComponent("Chrome")
                .appendingPathComponent("NativeMessagingHosts")
            
            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(at: manifestsDir, withIntermediateDirectories: true)
            
            // Write manifest file
            let manifestFile = manifestsDir.appendingPathComponent("com.chronoguard.native.json")
            try jsonData.write(to: manifestFile)
            
            print("Native messaging manifest installed at: \(manifestFile.path)")
            
        } catch {
            print("Failed to install native messaging manifest: \(error)")
        }
    }
}