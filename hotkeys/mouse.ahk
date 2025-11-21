#Requires AutoHotkey v2.0
SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # MOUSE BUTTON HOTKEYS MODULE                                      #
; # Purpose: Mouse button remapping and combinations                 #
; ####################################################################

; XButton2 (mouse forward button) → Enter (with wildcards to avoid conflicts)
XButton2::
{
    ; Use SendInput to avoid conflicts with normal Enter key operation
    SendInput "{Enter}"
}

; XButton1 (mouse back button) → Ctrl+Win+Space (emoji picker)
XButton1::
{
    Send "^#{Space}"
}

; Ctrl+RButton → Win+Tab (Task View)
^RButton::Send "#{Tab}"

; Ctrl+XButton1 → Win+Ctrl+Left (switch virtual desktop left)
^XButton1::
{
    Send "#^{Left}"
}

; Ctrl+XButton2 → Win+Ctrl+Right (switch virtual desktop right)
^XButton2::
{
    Send "#^{Right}"
}
