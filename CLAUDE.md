# Window-Flow Dynamic - Developer Guide

## Environment
- **Language**: AutoHotkey v2.0+
- **Platform**: Windows 10/11
- **Entry Point**: `Window-Flow-Dynamic.ahk`

## Commands
- **Run**: Double-click `Window-Flow-Dynamic.ahk` or run `AutoHotkey.exe Window-Flow-Dynamic.ahk`
- **Edit**: Open in VS Code or text editor.
- **Reload**: Right-click tray icon -> Reload (or restart script).

## Code Style Guidelines
- **Syntax**: Strict AutoHotkey v2.0. Do not use v1 syntax.
- **Naming**:
  - Global variables: `g_` prefix (e.g., `g_Slots`, `g_DashboardGui`).
  - Functions: PascalCase (e.g., `ActivateSlot`).
  - Variables: camelCase (e.g., `slotIndex`).
- **Structure**:
  1. Directives (`#Requires`, `#SingleInstance`)
  2. Global Variables
  3. Initialization
  4. Hotkeys
  5. Functions (Logic, UI, Helpers)

## UI Design System
- **Theme**: Cyberpunk / Dark Mode
- **Background**: `0x1a1a1a` (Dark Grey)
- **Text**: `0xffffff` (White)
- **Accent**: `0x00f3ff` (Neon Blue) for active elements/headers.
- **Fonts**: Segoe UI. Use `SetFont` for sizing and styling.

## Key Architecture
- **Dynamic Assignment**: No hardcoded window lists. Users assign slots at runtime.
- **Persistence**: Data is saved to `settings.ini`.
- **Monitors**: Uses `MonitorGet` (ByRef) and `WinMove` to handle multi-monitor positioning.
