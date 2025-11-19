#Requires AutoHotkey v2.0

; ===================================================================
; Window-Flow Launcher
; Simple launcher that ensures proper setup and runs main script
; ===================================================================

; Check if main script exists
if !FileExist("Window-Flow-v2.ahk") {
    MsgBox("Error: Window-Flow-v2.ahk not found!`n`nPlease ensure all files are in the same directory.", "Window-Flow Error", "Icon!")
    ExitApp
}

; Check if config exists
if !FileExist("config.ahk") {
    MsgBox("Warning: config.ahk not found!`n`nRunning with default configuration.", "Window-Flow Warning", "Icon!")
}

; Run the main script
Run("Window-Flow-v2.ahk")
ExitApp()
