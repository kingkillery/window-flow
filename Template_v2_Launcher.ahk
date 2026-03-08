; ####################################################################
; # AUTO-LAUNCHER FOR V2 SCRIPT                                     #
; # This v1 script checks for AHK v2 and relaunches with correct version #
; ####################################################################

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Check if we're already running v2 (shouldn't happen but just in case)
if (A_AhkVersion >= "2.0") {
    MsgBox, 0, Success, Already running AutoHotkey v2!
    ExitApp
}

; Define possible AHK v2 paths
AHK_V2_Paths := []
AHK_V2_Paths.Push("C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe")
AHK_V2_Paths.Push(A_AppData . "\..\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe")
AHK_V2_Paths.Push("C:\Program Files\AutoHotkey\v2\AutoHotkey.exe")
AHK_V2_Paths.Push("C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe")

; Find first existing v2 path
FoundPath := ""
For index, path in AHK_V2_Paths {
    if (FileExist(path)) {
        FoundPath := path
        Break
    }
}

; If v2 found, launch the script with it
if (FoundPath != "") {
    ; Get the actual script to run (Template.ahk)
    ScriptPath := A_ScriptDir . "\Template.ahk"
    
    if (!FileExist(ScriptPath)) {
        MsgBox, 48, Error, Template_Fixed.ahk not found!`n`nExpected at:`n%ScriptPath%
        ExitApp
    }
    
    ; Show launching message
    TrayTip, Launching, Starting Template.ahk with AutoHotkey v2..., 2
    
    ; Launch with v2 and close this v1 script
    Run, "%FoundPath%" "%ScriptPath%"
    
    Sleep, 500  ; Brief delay to ensure launch
    ExitApp
}
else {
    ; No v2 found, show error
    MsgBox, 48, AutoHotkey v2 Required, 
    (
AutoHotkey v2 is not installed!

This script requires AutoHotkey v2.0 or later.
Current version: %A_AhkVersion% (v1)

Please download and install AutoHotkey v2 from:
https://www.autohotkey.com/download/ahk-v2.exe

After installation, the script will work correctly.

Checked locations:
- C:\Program Files\AutoHotkey\v2\
- %A_AppData%\..\Local\Programs\AutoHotkey\v2\
- C:\Program Files (x86)\AutoHotkey\v2\
    )
    ExitApp
}
