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

- **Zero Network Requests**: Complete offline operation
- **Local SQLite Storage**: Data never leaves your Mac
- **Optional Database Encryption**: SQLCipher with AES-256
- **Configurable Tracking**: Granular control over what gets tracked
- **Complete Data Purge**: Built-in data deletion tools

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

## Development Status

🚧 **In Development** - This project is currently in the planning phase.

### Roadmap

- **Alpha** (6 weeks): Core tracking engine + SQLite storage
- **Beta** (4 weeks): Terminal UI + permission wizard  
- **RC1** (3 weeks): Web dashboard + encryption
- **GA** (2 weeks): Automated installer + documentation

## Documentation

- [Product Requirements Document](PRD.md) - Comprehensive project specifications
- [Development Guide](CLAUDE.md) - Technical guidance for contributors

## License

TBD

## Contributing

This project is in early development. Contribution guidelines will be established as the codebase matures.