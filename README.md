# Window-Flow Dynamic

A lightweight, dynamic window manager for Windows, built with AutoHotkey v2. Assign applications to slots on the fly and switch between them instantly using mouse wheel shortcuts.

## Features

- **Dynamic Assignment**: Assign any open window to one of 6 slots via a dashboard UI.
- **Instant Switching**: Cycle through assigned windows using `Ctrl + Alt + MouseWheel`.
- **Monitor Management**: Force windows to appear on specific monitors (or follow the mouse) when activated.
- **Persistence**: Save assignments so your setup is remembered after a restart.
- **Auto-Elevation**: Automatically runs as Administrator to ensure it can manage all windows.

## Requirements

- [AutoHotkey v2.0+](https://www.autohotkey.com/v2/)
- Windows 10 or 11

## Installation & Usage

1. Ensure AutoHotkey v2 is installed.
2. Download `Window-Flow-Dynamic.ahk`.
3. Double-click the script to run it.

## Controls

| Shortcut | Action |
|----------|--------|
| **Ctrl + Alt + Space** | Toggle the Dashboard to view/configure slots |
| **Ctrl + Alt + WheelUp** | Cycle to the previous slot |
| **Ctrl + Alt + WheelDown** | Cycle to the next slot |
| **Esc** | Close Dashboard / Cancel Capture |

## How to Use

1. **Open the Dashboard**: Press `Ctrl + Alt + Space`.
2. **Assign a Window**:
   - Click the **Set** button next to an empty slot (or overwrite an existing one).
   - The dashboard will hide. Click on the window you want to assign.
3. **Configure Options**:
   - **Save Checkbox**: If checked, the app remembers the process name (e.g., `chrome.exe`). If you close the app and reopen it later, Window-Flow will try to find it again.
   - **Monitor Button**: Click the "Auto" button to cycle through modes:
     - **Auto**: Windows appear where they were.
     - **Mon 1 / Mon 2**: Force window to center on a specific monitor.
     - **Mouse**: Force window to center on the monitor where your mouse currently is.

## Files

- `Window-Flow-Dynamic.ahk`: The main application script.
- `settings.ini`: Automatically generated file that stores your slot configurations.

---
*Generated with [Claude Code](https://claude.com/claude-code)*
