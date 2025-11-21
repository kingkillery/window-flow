#Requires AutoHotkey v2.0
SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # MEDIA CONTROL HOTKEYS MODULE                                     #
; # Purpose: Media playback and volume control via mouse/keyboard    #
; ####################################################################

; Ctrl+Alt+Shift+Wheel Down → Volume Down by 10
^!+WheelDown::SoundSetVolume -10

; Ctrl+Alt+Shift+Wheel Up → Volume Up by 10
^!+WheelUp::SoundSetVolume +10

; Ctrl+Alt+MButton → Media Play/Pause
^!MButton::Media_Play_Pause

; Ctrl+Alt+RButton → Media Next Track
^!RButton::Media_Next

; Ctrl+Alt+LButton → Media Previous Track
^!LButton::Media_Prev

; Alt+MButton → Alt+L (may be app-specific)
!MButton::
{
    Send "!l"
}
