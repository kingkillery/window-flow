# Window-Flow Dynamic

Native Windows window switcher built with C# and WinForms. Press `Ctrl + Alt + Space` to open a live list of currently running windows, assign them into saved slots, and cycle those slots with `Ctrl + Alt + WheelUp` / `Ctrl + Alt + WheelDown`.

## Features

- **Live Window Picker**: Shows currently running windows on demand from a global hotkey.
- **Saved Slot Cycling**: Assign chosen windows to slots and cycle them in slot order with `Ctrl + Alt + WheelUp` / `Ctrl + Alt + WheelDown`.
- **Fast Native Activation**: Window bring-to-foreground behavior runs from C# for quick switching.
- **Per-Slot Monitor Controls**: Choose target monitor (Auto, Mouse, or specific monitor) for each saved slot or one-off activation.
- **Maximize + Opacity**: Optional maximize and alpha controls are available per launch.
- **Tray Background Service**: Runs in the background with a system tray icon and hotkey support.
- **Native Fallback**: CLI mode remains for compatibility with older scripts.

## Requirements

- Windows 10 or 11
- .NET Framework (csc from `Framework64\v4.0.30319` used by this repo)

## Installation & Usage

1. Build the app:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-switcher.ps1
```

2. Launch the app:

```powershell
& ".\\bin\\WindowFlow.Switcher.exe"
```

3. Open the picker:

```powershell
# Use hotkey
& ".\\bin\\WindowFlow.Switcher.exe" --help
```

- Press `Ctrl + Alt + Space` for normal operation.
- Use the `Wheel slot` dropdown plus `Save Slot` in the picker to define the cycle order.
- After saving slots, use `Ctrl + Alt + WheelUp` and `Ctrl + Alt + WheelDown` to cycle only those chosen windows.
- If the hotkey path is blocked, run once with `--open` to force the picker open at startup.

```powershell
& ".\\bin\\WindowFlow.Switcher.exe" --open
```

## Controls

| Shortcut               | Action                                      |
| ---------------------- | ------------------------------------------- |
| **Ctrl + Alt + Space** | Open the running window picker. |
| **Ctrl + Alt + WheelUp** | Activate the previous saved slot. |
| **Ctrl + Alt + WheelDown** | Activate the next saved slot. |
| **Esc**                | Close the picker. |
| **Enter / Double click** | Activate selected window. |

## Files

* `src/WindowFlow.Switcher/Program.cs`: Native WinForms launcher + switcher.
* `scripts/build-switcher.ps1`: Builds `bin/WindowFlow.Switcher.exe`.
* `Window-Flow-Dynamic.ahk`: Legacy AHK script retained for historical reference only.

