# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChronoGuard is a privacy-first local activity tracker for macOS that captures application, window, and browser activity entirely on-device with zero cloud dependency. The project targets macOS 13+ and focuses on military-grade privacy with local SQLite storage.

## Architecture Components

Based on PRD.md, the system consists of:

- **Activity Capture Engine**: Uses NSWorkspace APIs, Accessibility APIs, and JXA scripts
- **Data Storage**: SQLite 3.40+ with optional SQLCipher encryption
- **User Interfaces**: Terminal UI (TUI) and local web dashboard (localhost:9173)
- **Browser Integration**: Native messaging extensions for Chrome/Firefox
- **Permission Management**: Handles macOS Accessibility and Automation permissions

## Development Commands

Since this is a new project, common commands will likely include:

```bash
# macOS development (when implemented)
xcodebuild -project ChronoGuard.xcodeproj -scheme ChronoGuard build
xcodebuild test -project ChronoGuard.xcodeproj -scheme ChronoGuard

# Node.js components (if any)
npm install
npm run build
npm test
npm run lint

# Database management
sqlite3 chronoguard.db < schema.sql
```

## Key Technical Constraints

- **Privacy First**: All data processing must remain local - no network requests allowed
- **macOS Integration**: Heavy use of macOS-specific APIs (NSWorkspace, Accessibility, JXA)
- **Permission Dependent**: Core functionality requires Accessibility and Automation permissions
- **Resource Limits**: Must maintain <2% CPU usage and <150MB memory ceiling
- **SQLite Schema**: Uses strict mode with timestamp-based activity events

## Browser Extension Architecture

The system requires native messaging between browser extensions and the main application:
- Extensions capture tab URLs and titles
- Native messaging protocol communicates with main app
- Supports user-configurable include/exclude URL patterns

## Database Schema

Core activity table structure:
```sql
CREATE TABLE activity (
  id INTEGER PRIMARY KEY,
  timestamp INTEGER NOT NULL,
  app_bundle_id TEXT NOT NULL,
  app_name TEXT NOT NULL,
  window_title TEXT,
  url TEXT,
  is_afk BOOLEAN DEFAULT 0,
  UNIQUE(timestamp, app_bundle_id)
) STRICT;
```

## Security Requirements

- Optional AES-256 database encryption via SQLCipher
- Network isolation enforced by macOS firewall
- Configurable tracking granularity (apps, windows, URLs)
- Complete data purge capability

## Development Phases

1. **Alpha**: Core tracking engine + SQLite storage (6 weeks)
2. **Beta**: TUI + permission wizard (4 weeks) 
3. **RC1**: Web dashboard + encryption (3 weeks)
4. **GA**: Automated installer + documentation (2 weeks)