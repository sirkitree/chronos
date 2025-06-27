import Foundation

struct ActivityEvent {
    let timestamp: Int64
    let app: AppInfo
    let window: String?
    let url: String?
    let isActive: Bool
    let isAFK: Bool
    
    init(app: AppInfo, window: String? = nil, url: String? = nil, isActive: Bool = true, isAFK: Bool = false) {
        self.timestamp = Int64(Date().timeIntervalSince1970)
        self.app = app
        self.window = window
        self.url = url
        self.isActive = isActive
        self.isAFK = isAFK
    }
}

struct AppInfo {
    let bundleId: String
    let name: String
    
    init(bundleId: String, name: String) {
        self.bundleId = bundleId
        self.name = name
    }
}