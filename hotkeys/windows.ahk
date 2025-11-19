#Requires AutoHotkey v2.0
SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # WINDOW MANAGEMENT HOTKEYS MODULE                                 #
; # Purpose: Window switching, tab management, clipboard utilities   #
; ####################################################################

; -------------------------------------------------------------------
; Helper Function: ActivateWindowUnderMouse()
; Purpose : Activates the window currently under the mouse cursor
;           if it's not already the active window.
; -------------------------------------------------------------------
ActivateWindowUnderMouse() {
    MouseGetPos ,, &WinID
    if !WinActive(WinID)
        WinActivate WinID
}

; Ctrl+Wheel Down → Activate window under mouse + Ctrl+PgDn (next tab)
^WheelDown::
{
    ActivateWindowUnderMouse()
    Send "^{PgDn}"
}

; Ctrl+Wheel Up → Activate window under mouse + Ctrl+PgUp (previous tab)
^WheelUp::
{
    ActivateWindowUnderMouse()
    Send "^{PgUp}"
}

; Ctrl+Shift+RButton → Close current tab (Ctrl+W)
^+RButton::Send "^w"

; MButton → Hold Ctrl+Win+Alt while MButton is held down
MButton::
{
    Send "{Ctrl down}{LWin down}{Alt down}"
    KeyWait "MButton"
    Send "{Ctrl up}{LWin up}{Alt up}"
}

; Alt+Wheel Down → Backspace
!WheelDown:: Send "{Backspace}"

; Ctrl+` (grave/tilde key) → Enter
^SC029::Send "{Enter}"

; Home → Exit app
Home::ExitApp
