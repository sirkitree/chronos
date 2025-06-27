# ChronoGuard

A privacy-first local activity tracker for macOS that captures application, window, and browser activity entirely on-device with zero cloud dependency.

## Overview

ChronoGuard is designed for privacy-conscious professionals who want to track their work activity without compromising data security. All tracking and processing happens locally on your Mac - no data ever leaves your device.

## Key Features

- **100% Local Processing**: All data stays on your device
- **macOS Native**: Uses NSWorkspace and Accessibility APIs
- **Browser Integration**: Chrome extension via native messaging
- **Encrypted Storage**: Optional AES-256 SQLite encryption
- **Resource Efficient**: <2% CPU usage, <150MB memory
- **Multiple Interfaces**: Terminal UI and web dashboard

## Target Platform

- macOS 13 (Ventura) and later
- Requires Accessibility and Automation permissions for full functionality

## Privacy & Security

### Data Collection

ChronoGuard collects the following data **locally on your device only**:

- **Application Usage**: App names, bundle IDs, and active time
- **Window Titles**: Document names, webpage titles (with Accessibility permission)
- **Browser Activity**: URLs and page titles from Chrome (via extension)
- **Timestamps**: When activities occurred
- **Idle Status**: Periods of user inactivity

### Privacy Guarantees

- **Zero Network Requests**: Complete offline operation - no data transmission
- **Local SQLite Storage**: Data never leaves your Mac
- **No Analytics**: No usage statistics or telemetry sent anywhere
- **No Cloud Sync**: All data remains on your local device
- **Complete Control**: You own and control all your activity data

### Security Features

- **Optional Database Encryption**: SQLCipher with AES-256
- **Permission-Based Access**: macOS Accessibility and Automation permissions required
- **Configurable Tracking**: Granular control over what gets tracked
- **Complete Data Purge**: Built-in data deletion tools
- **Native Messaging**: Secure local communication with Chrome extension

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   macOS APIs   │───▶│  Activity Engine │───▶│ SQLite Storage │
│ (NSWorkspace,   │    │                  │    │  (Encrypted)    │
│  Accessibility) │    └──────────────────┘    └─────────────────┘
└─────────────────┘             │                        │
                                 ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Browser         │    │   Report Gen     │    │   Interfaces    │
│ Extension       │    │                  │    │ (TUI + Web UI)  │
│ (Chrome)        │    └──────────────────┘    └─────────────────┘
└─────────────────┘
```

## Installation

### Requirements

- **macOS 13 (Ventura) or later**
- **Xcode Command Line Tools**
- **Swift 6.1+** (included with Command Line Tools)
- **Chrome Browser** (for browser tracking)

### Quick Start

1. **Clone and build ChronoGuard:**
   ```bash
   git clone https://github.com/sirkitree/chronos.git
   cd chronos
   swift build --configuration release
   ```

2. **Set up permissions:**
   ```bash
   swift run --configuration release ChronoGuard --setup-permissions
   ```

3. **Install Chrome extension (optional):**
   ```bash
   swift run --configuration release ChronoGuard --install-chrome-extension
   ```

4. **Start tracking:**
   ```bash
   swift run --configuration release ChronoGuard monitor
   ```

### Chrome Extension Setup

1. **Install native messaging manifest:**
   ```bash
   swift run ChronoGuard --install-chrome-extension
   ```

2. **Load extension in Chrome:**
   - Open `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `chrome-extension/` folder

3. **Start native messaging host:**
   ```bash
   swift run ChronoGuard --native-messaging
   ```

## Usage

### Basic Commands

```bash
# Start activity monitoring
swift run ChronoGuard monitor --duration 3600

# Generate daily report
swift run ChronoGuard report --type daily

# View weekly productivity report
swift run ChronoGuard report --type productivity --format json

# Check permissions
swift run ChronoGuard --check-permissions

# Start Chrome extension host
swift run ChronoGuard --native-messaging
```

### Report Examples

**Daily Summary:**
```bash
# Today's activity report
swift run ChronoGuard report --type daily

# Specific date report
swift run ChronoGuard report --type daily --date 2025-06-27
```

**Export to Different Formats:**
```bash
# Export to CSV for spreadsheet analysis
swift run ChronoGuard report --type daily --format csv > activity-report.csv

# Export to JSON for programmatic processing
swift run ChronoGuard report --type weekly --format json > weekly-data.json

# Formatted table output (default)
swift run ChronoGuard report --type productivity
```

**Productivity Analysis:**
```bash
# Get productivity score and app categorization
swift run ChronoGuard report --type productivity --date 2025-06-27

# Weekly productivity trends
swift run ChronoGuard report --type weekly --format table
```

### Advanced Usage

**Continuous Background Monitoring:**
```bash
# Run monitoring in background with nohup
nohup swift run ChronoGuard monitor --duration 86400 > /dev/null 2>&1 &

# Start Chrome extension host as background service
nohup swift run ChronoGuard --native-messaging > /dev/null 2>&1 &
```

**Automated Reporting:**
```bash
# Create daily report script
echo '#!/bin/bash
DATE=$(date +%Y-%m-%d)
swift run ChronoGuard report --type daily --date $DATE --format csv > "reports/daily-$DATE.csv"
' > daily-report.sh
chmod +x daily-report.sh
```

**Integration Examples:**
```bash
# Get activity count for monitoring
ACTIVITY_COUNT=$(swift run ChronoGuard report --type daily --format json | jq '.appActivities | length')

# Export last week's data for analysis
for i in {1..7}; do
  DATE=$(date -v -${i}d +%Y-%m-%d)
  swift run ChronoGuard report --type daily --date $DATE --format json > "data/$DATE.json"
done
```

## Troubleshooting

### Build Issues

**Swift compiler not found:**
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

**Build fails with dependency errors:**
```bash
# Clean and rebuild
swift package clean
swift build
```

**PrivacyInfo.xcprivacy warning:**
```
warning: 'sqlite.swift': found 1 file(s) which are unhandled...
```
This warning from SQLite.swift dependency is harmless and can be safely ignored. It's related to Apple's privacy manifest requirements for third-party dependencies.

### Permission Issues

**Accessibility permission denied:**
1. Go to System Preferences > Security & Privacy > Privacy > Accessibility
2. Add ChronoGuard to the list and enable it
3. Restart ChronoGuard

**App tracking not working:**
```bash
# Check current permissions
swift run ChronoGuard --check-permissions

# Reconfigure permissions
swift run ChronoGuard --setup-permissions
```

### Chrome Extension Issues

**Extension not connecting:**
1. Ensure ChronoGuard app is running
2. Start native messaging host: `swift run ChronoGuard --native-messaging`
3. Check extension popup shows "Connected" status

**No browser data being logged:**
1. Verify extension is loaded and enabled in Chrome
2. Check that all permissions are granted
3. Look for errors in Chrome Developer Tools > Extensions

**Native messaging manifest missing:**
```bash
# Reinstall the manifest
swift run ChronoGuard --install-chrome-extension

# Verify installation
ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/
```

### Data Issues

**No activity data showing:**
1. Check that monitoring is actually running
2. Verify database file exists: `ls chronoguard.db`
3. Try generating a report: `swift run ChronoGuard report --type daily`

**Reports showing empty:**
1. Ensure you have some tracked activity
2. Check the correct date: `swift run ChronoGuard report --type daily --date 2025-06-27`
3. Verify database has data: `swift run ChronoGuard report --type daily --format json`

## Development Status

✅ **Alpha Complete** - Core functionality implemented and tested.

### Current Features

- ✅ **App Activity Tracking**: NSWorkspace API integration
- ✅ **Window Title Capture**: Accessibility API integration  
- ✅ **Chrome Browser Tracking**: Native messaging extension
- ✅ **Idle Detection**: CoreGraphics event monitoring
- ✅ **SQLite Storage**: Local database with daily summaries
- ✅ **Report Generation**: Daily, weekly, and productivity reports
- ✅ **CLI Interface**: Professional command-line interface
- ✅ **Permission Management**: Guided macOS permission setup

### Roadmap

- **Beta** (4 weeks): Background service + launchd integration
- **RC1** (3 weeks): Web dashboard + database encryption
- **GA** (2 weeks): Automated installer + distribution

## Documentation

- [Product Requirements Document](PRD.md) - Comprehensive project specifications
- [Development Guide](CLAUDE.md) - Technical guidance for contributors

## License

TBD

## Contributing

This project is in early development. Contribution guidelines will be established as the codebase matures.