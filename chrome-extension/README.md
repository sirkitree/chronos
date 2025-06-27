# ChronoGuard Chrome Extension

Privacy-first browser activity tracking extension for ChronoGuard macOS app.

## Features

- **Tab Activity Tracking**: Captures URLs and page titles when you switch tabs
- **Real-time Monitoring**: Tracks active tab changes and page navigation
- **Privacy Protected**: All data sent directly to local ChronoGuard app via native messaging
- **Zero Cloud Data**: No data leaves your device - everything stays local
- **Single Page App Support**: Tracks URL changes in SPAs via history API monitoring

## Installation

### Prerequisites

1. **ChronoGuard macOS App**: Must be installed and running
2. **Chrome Browser**: Version 88+ recommended

### Installation Steps

1. **Install the native messaging manifest**:
   ```bash
   chronoguard --install-chrome-extension
   ```

2. **Load the extension in Chrome**:
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode" (toggle in top right)
   - Click "Load unpacked"
   - Select the `chrome-extension` folder from this project

3. **Grant permissions**:
   - The extension will request permissions for:
     - `activeTab`: To detect tab switches
     - `tabs`: To read tab URLs and titles  
     - `nativeMessaging`: To communicate with ChronoGuard app

4. **Start native messaging host**:
   ```bash
   chronoguard --native-messaging
   ```

## How It Works

### Data Flow

```
Chrome Tab Activity → Extension → Native Messaging → ChronoGuard App → SQLite Database
```

### Tracked Data

- **URL**: Current page URL (sanitized - no query parameters with sensitive data)
- **Title**: Page title as shown in browser tab
- **Timestamp**: When the activity occurred
- **Visibility**: Whether the tab is currently visible/active

### Privacy Features

- **Local Only**: All communication happens locally between extension and app
- **No Network Requests**: Extension never sends data to external servers
- **URL Sanitization**: Removes sensitive query parameters before logging
- **Filtered URLs**: Ignores chrome:// and extension pages

## Extension Files

- **`manifest.json`**: Extension configuration and permissions
- **`background.js`**: Service worker handling tab monitoring and native messaging
- **`content.js`**: Content script for detecting in-page activity
- **`popup.html/js`**: Extension popup interface
- **`icons/`**: Extension icons (16x16, 32x32, 48x48, 128x128)

## Usage

1. **Automatic Tracking**: Once installed, the extension automatically tracks your browsing
2. **View Status**: Click the extension icon to see connection status
3. **Access Reports**: Use popup to quickly open ChronoGuard app or reports

## Troubleshooting

### Extension Not Connecting

1. Ensure ChronoGuard app is running
2. Check that native messaging host is started:
   ```bash
   chronoguard --native-messaging
   ```
3. Verify manifest is installed:
   ```bash
   ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/
   ```

### No Data Being Logged

1. Check extension permissions in Chrome
2. Verify popup shows "Connected" status
3. Look for errors in Chrome Developer Tools > Extensions

### Permission Issues

1. Reload the extension in `chrome://extensions/`
2. Grant all requested permissions
3. Restart Chrome and ChronoGuard app

## Development

### Building from Source

The extension is pure JavaScript - no build process required.

### Testing

1. Load extension in developer mode
2. Open Chrome Developer Tools
3. Check Console tab for any errors
4. Test tab switching and verify data in ChronoGuard app

### Native Messaging Protocol

Messages sent to ChronoGuard app:

```json
{
  "type": "tab_activity",
  "url": "https://example.com/page",
  "title": "Page Title",
  "timestamp": 1640995200000,
  "tabId": 123,
  "windowId": 1
}
```

## Security

- **Minimal Permissions**: Only requests necessary permissions
- **Local Communication**: Uses Chrome's native messaging API for secure local communication
- **No External Dependencies**: Self-contained extension with no external API calls
- **Privacy First**: Designed to never transmit data outside your device

## Version History

- **v0.1.0**: Initial release with basic tab tracking and native messaging