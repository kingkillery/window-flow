#Requires AutoHotkey v2.0

; Test script for mouse hotkeys and Enter key
; This will show tooltips when hotkeys are triggered

; Alt+RButton → Copy test
!RButton::
{
    ToolTip("Alt+RButton detected - Copy test successful!")
    SetTimer(RemoveToolTip, -2000)
    Send("^c")
}

; Alt+LButton → Paste test
!LButton::
{
    ToolTip("Alt+LButton detected - Paste test successful!")
    SetTimer(RemoveToolTip, -2000)
    Send("^v")
}

; Enter key test
Enter::
{
    ToolTip("Enter key detected - working normally!")
    SetTimer(RemoveToolTip, -1000)
    Send("{Enter}")
}

; XButton2 test (mouse forward)
XButton2::
{
    ToolTip("XButton2 detected - mapped to Enter!")
    SetTimer(RemoveToolTip, -2000)
    SendInput("{Enter}")
}

; Ctrl+Alt+T to test if script is running
^!t::
{
    ToolTip("Test script is active! Try Alt+RButton, Alt+LButton, and Enter keys.")
    SetTimer(RemoveToolTip, -3000)
}

RemoveToolTip() {
    ToolTip()
}

; Show startup message
ToolTip("Hotkey test script loaded! Press Ctrl+Alt+T to test.", 3000)
SetTimer(RemoveToolTip, -3000)