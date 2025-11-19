^+!f:: ; Ctrl+Alt+Shift+F
; === Level 1 Certificate of Completion Autofill Script (AHK v1) ===
; For: Work Order #13969221 (PPL / Ambia Energy, 1434 N BROAD ST ALLENTOWN PA)
; Start with cursor in the first field ("Name")
; Each value typed, waits 0.5s, then Tabs to next field

values =
(
MIMI SHELLY
1434 N BROAD ST
ALLENTOWN
PA
18104
Kelsey Dillingham
335 S 560 W ST
Lindon
UT
84042
(877) 412-7929
(877) 412-7929
processing@ambiasolar.com

1434 N BROAD ST
ALLENTOWN
PA
18104
N BROAD ST
PPL Electric Utilities
*****03003
300748803
Enphase
Solar
28
Enphase Energy
IQ8HC-72-M-DOM-US
11.5
Ambia Energy, LLC
335 S 560 W ST
Lindon
UT
84042
Kelsey Dillingham
(877) 412-7929
(877) 412-7929
processing@ambiasolar.com

MIMI SHELLY
10/09/2025
MIMI SHELLY
Customer

Electric Pros LLC
123 Electrician Way
Allentown
PA
18104
Tom Engler
(877) 412-7929
(877) 412-7929
tpengler@pplweb.com

Mark Dahl
10/09/2025
Mark Dahl
Customer

Allentown
Thomas Engler
10/09/2025
MIMI SHELLY
Customer
)

SetKeyDelay, 500, 50
Loop, Parse, values, `n, `r
{
    if (A_LoopField != "")
    {
        SendInput, %A_LoopField%
        Sleep, 500
    }
    SendInput, {Tab}
    Sleep, 500
}
return

^Esc::ExitApp  ; Ctrl+Esc to exit
