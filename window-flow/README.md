# Window-Flow Native AHK v2

A high-performance, native Windows desktop automation tool for rapid context switching between application windows. Built entirely in AutoHotkey v2 with no web dependencies.

## Overview

Window-Flow replaces the web-based interface with a native Windows tray application that provides instant access to your frequently used applications through a full-screen overlay. Perfect for power users who need lightning-fast window switching on their primary display.

## Features

- **Native Windows UI**: No browser, Electron, or web dependencies
- **System Tray Integration**: Lives in your system tray for easy access
- **Full-Screen Overlay**: Covers primary monitor for distraction-free switching
- **Global Hotkeys**: Works from any application
- **Mouse Wheel Navigation**: Scroll through agents with Ctrl+Alt+Wheel
- **Configurable Agents**: Easy setup for any Windows application
- **Keyboard Navigation**: Arrow keys, Enter, and Escape support
- **Multi-Monitor Support**: Focuses on primary display
- **Real-time Configuration**: Reload config without restarting

## Installation

### Prerequisites

- **AutoHotkey v2.0+** - Download from [autohotkey.com](https://www.autohotkey.com/)
- Windows 10 or Windows 11

### Setup

1. Download all files to a folder (e.g., `C:\Window-Flow\`)
2. Ensure these files are present:
   - `Window-Flow-v2.ahk` (main script)
   - `config.ahk` (configuration)
   - `README.md` (this file)

3. Double-click `Window-Flow-v2.ahk` to launch
4. The app will appear in your system tray

### Autostart (Optional)

To start Window-Flow automatically with Windows:

1. Press `Win+R`, type `shell:startup`, and press Enter
2. Create a shortcut to `Window-Flow-v2.ahk` in this folder
3. Window-Flow will now launch when Windows starts

## Usage

### Basic Operation

1. **Toggle UI**: Press `Ctrl+Alt+Space` to show/hide the switcher
2. **Navigate**: Use arrow keys or mouse wheel to select agents
3. **Activate**: Press `Enter` or click on an agent to switch
4. **Dismiss**: Press `Esc`, `Space`, or click outside to hide

### Navigation Methods

| Method | Action |
|--------|--------|
| **Arrow Keys** | Navigate up/down/left/right through agents |
| **Mouse Wheel** | `Ctrl+Alt+WheelUp/Down` to cycle agents |
| **Mouse Click** | Click any agent button to activate |
| **Agent Hotkeys** | Use configured shortcuts (e.g., `Alt+C` for Cursor) |

### Tray Menu

Right-click the system tray icon for:
- Show/Hide Window Flow
- Reload Configuration
- Edit Configuration
- Exit Application

## Configuration

### Editing Agents

Open `config.ahk` to modify your agent definitions. Each agent requires:

```autohotkey
"agent_id", {
    name: "Display Name",           ; Name shown in UI
    icon: "🎨",                     ; Emoji or symbol
    processName: "app.exe",         ; Windows executable name
    category: "Category",           ; Group for organization
    shortcut: "Alt+Key"             ; Optional hotkey
}
```

### Adding New Agents

1. Find the executable name using Task Manager
2. Add entry to `AGENTS` map in `config.ahk`
3. Reload configuration from tray menu
4. Test with your new hotkey or the main UI

### Customizing Hotkeys

Edit these variables in `config.ahk`:

```autohotkey
global TOGGLE_HOTKEY := "^!Space"        ; Ctrl+Alt+Space
global WHEEL_MODIFIER := "^!Alt"         ; Ctrl+Alt+Wheel
global ACTIVATE_KEY := "Enter"           ; Enter to activate
```

### UI Appearance

Customize colors and styling:

```autohotkey
global UI_BG_COLOR := "0x0a0a0a"         ; Background
global SELECTED_COLOR := "0x00f3ff"      ; Selection highlight
global TEXT_COLOR := "0xffffff"          ; Text color
```

## Agent Examples

### Development Tools
```autohotkey
"cursor", {
    name: "Cursor",
    icon: "⌨️",
    processName: "Cursor.exe",
    category: "Development",
    shortcut: "Alt+C"
}
```

### Browsers
```autohotkey
"browser", {
    name: "Browser",
    icon: "🌐", 
    processName: "chrome.exe",  ; or firefox.exe, msedge.exe
    category: "Browsing",
    shortcut: "Alt+B"
}
```

### Communication
```autohotkey
"slack", {
    name: "Slack",
    icon: "💬",
    processName: "Slack.exe",
    category: "Communication",
    shortcut: "Alt+L"
}
```

## Troubleshooting

### Agent Not Found

If you get "Agent not found" errors:

1. **Verify Process Name**: Check Task Manager for exact executable name
2. **Case Sensitivity**: Process names are case-sensitive
3. **Launch First**: Ensure the application is running before switching

### Hotkey Conflicts

If hotkeys don't work:

1. **Check Conflicts**: Other apps might use the same hotkeys
2. **Admin Rights**: Some apps require admin privileges for global hotkeys
3. **Reload Config**: Use tray menu to reload configuration

### UI Issues

If the overlay doesn't appear correctly:

1. **Multi-Monitor**: Ensure primary monitor is set correctly
2. **Screen Resolution**: UI adapts to your primary monitor resolution
3. **Restart**: Close and restart the application

## Performance

Window-Flow is optimized for speed:
- **Instant Activation**: No loading times or web dependencies
- **Minimal Memory**: Lightweight native Windows application
- **Throttled Input**: Mouse wheel throttled to prevent over-scrolling
- **Efficient Rendering**: Simple GUI with no animations or effects

## Security

- **No Network Access**: Completely offline operation
- **No External Dependencies**: Only uses AutoHotkey built-in functions
- **Local Configuration**: All settings stored in local files
- **No Data Collection**: No telemetry or usage tracking

## Advanced Usage

### Multiple Instances

The script uses `#SingleInstance Force` to prevent multiple copies. If you need different configurations:

1. Copy the entire folder to a new location
2. Modify the `config.ahk` in each folder
3. Run each instance separately

### Scripting Integration

You can integrate Window-Flow with other AHK scripts:

```autohotkey
; Activate specific agent from another script
#Include Window-Flow-v2.ahk
ActivateAgent("cursor")  ; Switch to Cursor
```

### Custom Launch Logic

Enhance the `ActivateAgent()` function for custom behavior:
- Launch applications if not running
- Set specific window positions
- Apply window configurations
- Handle multiple windows of same process

## File Structure

```
Window-Flow/
├── Window-Flow-v2.ahk    # Main application script
├── config.ahk            # Configuration file
├── README.md             # This documentation
└── icon.ico              # Optional tray icon
```

## Version History

- **v2.0**: Complete rewrite in AHK v2 with native UI
- **v1.x**: Web-based implementation (deprecated)

## Support

For issues and questions:

1. Check this README for troubleshooting
2. Review `config.ahk` for configuration options
3. Test with minimal agent configuration
4. Verify AutoHotkey v2 installation

## License

This project is provided as-is for personal and professional use. Modify and distribute freely.

---

**Window-Flow Native** - Built for speed, designed for productivity.
