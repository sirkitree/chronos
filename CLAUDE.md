# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChronoGuard is a privacy-first local activity tracker for macOS that captures application, window, and browser activity entirely on-device with zero cloud dependency. The project targets macOS 13+ and focuses on military-grade privacy with local SQLite storage.

## Architecture Components

The implemented system consists of:

- **Activity Capture Engine**: NSWorkspace APIs and Accessibility APIs for app/window tracking
- **Data Storage**: SQLite with daily summary views and activity indexing
- **CLI Interface**: Professional command-line interface with comprehensive reporting
- **Chrome Extension**: Native messaging extension for browser tab tracking
- **Permission Management**: Guided macOS Accessibility permission setup
- **Report Generation**: Daily, weekly, and productivity analysis with multiple export formats

## Development Commands

The project uses Swift Package Manager for building and development:

```bash
# Build the project
swift build
swift build --configuration release

# Run ChronoGuard
swift run ChronoGuard [command] [options]

# Development and testing
swift run ChronoGuard --help
swift run ChronoGuard --check-permissions
swift run ChronoGuard monitor --duration 30

# Chrome extension setup
swift run ChronoGuard --install-chrome-extension
swift run ChronoGuard --native-messaging

# Report generation
swift run ChronoGuard report --type daily
swift run ChronoGuard report --type weekly --format json
swift run ChronoGuard report --type productivity --format csv

# Database inspection
sqlite3 chronoguard.db "SELECT * FROM activity LIMIT 10;"
sqlite3 chronoguard.db "SELECT * FROM daily_summary WHERE day = date('now');"
```

## Key Technical Constraints

- **Privacy First**: All data processing must remain local - no network requests allowed
- **macOS Integration**: Heavy use of macOS-specific APIs (NSWorkspace, Accessibility, CoreGraphics)
- **Permission Dependent**: Core functionality requires Accessibility permissions for window title capture
- **Resource Limits**: Must maintain <2% CPU usage and <150MB memory ceiling  
- **SQLite Schema**: Uses strict mode with timestamp-based activity events and indexed queries
- **Chrome Only**: Browser integration focused on Chrome via native messaging (no Safari/Firefox)

## Chrome Extension Architecture

The implemented native messaging system includes:
- **Chrome Extension**: Complete extension with manifest v3, background service worker, content scripts
- **Native Messaging Host**: Swift implementation in `NativeMessaging.swift` for bidirectional communication
- **Tab Activity Capture**: Real-time URL and title tracking with SPA navigation support
- **Privacy Protection**: URL sanitization and filtered tracking (excludes chrome:// pages)
- **Installation Automation**: `--install-chrome-extension` command for manifest setup

## Database Schema

Implemented SQLite schema with optimizations:

```sql
-- Core activity table (implemented in Database.swift)
CREATE TABLE activity (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  app_bundle_id TEXT NOT NULL,
  app_name TEXT NOT NULL,
  window_title TEXT,
  url TEXT,
  is_afk BOOLEAN DEFAULT 0,
  UNIQUE(timestamp, app_bundle_id)
) STRICT;

-- Performance indexes
CREATE INDEX idx_activity_timestamp ON activity(timestamp);
CREATE INDEX idx_activity_app_bundle_id ON activity(app_bundle_id);
CREATE INDEX idx_activity_date ON activity(date(timestamp, 'unixepoch'));

-- Daily summary view for reporting
CREATE VIEW daily_summary AS
SELECT 
    strftime('%Y-%m-%d', timestamp, 'unixepoch') AS day,
    app_name,
    app_bundle_id,
    SUM(CASE WHEN NOT is_afk THEN 300 ELSE 0 END) AS seconds_active,
    COUNT(*) AS event_count
FROM activity
GROUP BY day, app_bundle_id
ORDER BY day DESC, seconds_active DESC;
```

## Security Requirements

- **Database Security**: SQLite with strict mode, ready for SQLCipher encryption (planned for RC1)
- **Network Isolation**: Zero network requests, all data processing local-only
- **Permission Control**: macOS Accessibility permissions required for window title capture
- **Chrome Extension Security**: Native messaging provides secure local communication channel
- **Data Privacy**: Complete local data control with no external dependencies

## Development Phases

1. **Alpha** ✅ **COMPLETED**: Core tracking engine + SQLite storage + Chrome extension
   - NSWorkspace API integration for app tracking
   - Accessibility API for window title capture  
   - Chrome extension with native messaging
   - SQLite database with reporting views
   - Professional CLI interface with comprehensive reporting
   - Permission management and guided setup

2. **Beta** (In Progress): Background service + launchd integration
   - Persistent background monitoring
   - System service integration
   - Resource monitoring and optimization
   - Crash recovery mechanisms

3. **RC1** (Planned): Web dashboard + encryption
   - Local web interface at localhost:9173
   - SQLCipher database encryption
   - Enhanced configuration options

4. **GA** (Planned): Automated installer + distribution
   - macOS app bundle and installer
   - App Store preparation
   - Complete documentation

## Current Implementation Status

### Core Components Implemented

- **`Sources/main.swift`**: Entry point running CommandLineInterface
- **`Sources/CommandLineInterface.swift`**: Professional CLI with help, commands, and argument parsing
- **`Sources/Database.swift`**: SQLite integration with activity storage and daily summaries  
- **`Sources/ActivityCapture.swift`**: NSWorkspace API integration for app monitoring
- **`Sources/AccessibilityCapture.swift`**: macOS Accessibility API for window titles
- **`Sources/IdleDetection.swift`**: CoreGraphics event source for user idle detection
- **`Sources/PermissionManager.swift`**: Guided macOS permission setup and checking
- **`Sources/ReportGenerator.swift`**: Daily/weekly/productivity report generation with export
- **`Sources/NativeMessaging.swift`**: Chrome extension communication host
- **`Package.swift`**: Swift Package Manager configuration with SQLite.swift dependency

### Chrome Extension Files

- **`chrome-extension/manifest.json`**: Chrome extension manifest v3 configuration
- **`chrome-extension/background.js`**: Service worker for tab monitoring and native messaging
- **`chrome-extension/content.js`**: Content script for in-page activity detection  
- **`chrome-extension/popup.html/js`**: Extension popup interface
- **`chrome-extension/README.md`**: Extension installation and troubleshooting guide

### Key Features Working

- ✅ Real-time app switching detection and logging
- ✅ Window title capture with Accessibility permissions
- ✅ Chrome tab URL/title tracking via native messaging
- ✅ Idle time detection and activity status
- ✅ SQLite storage with indexed queries and views
- ✅ Report generation in table, JSON, and CSV formats
- ✅ Productivity analysis with app categorization
- ✅ Permission setup and status checking
- ✅ Chrome extension installation and host management

### Architecture Pattern

The codebase follows a modular Swift architecture:
- **CLI Interface Layer**: User interaction and command processing
- **Business Logic Layer**: Activity capture, data processing, and reporting  
- **Data Layer**: SQLite database with structured schema
- **Integration Layer**: macOS APIs and Chrome extension communication
- **Configuration Layer**: Permission management and system setup