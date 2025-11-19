#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; ####################################################################
; # SECURITY FIX TEST SCRIPT                                          #
; # Purpose: Validates that the INCO_PW environment variable fix works #
; ####################################################################

; Load environment
LoadDotEnv()

; Test the security fix
^!+i::
    MsgBox, 64, Security Fix Test, Testing INCO_PW environment variable...

    ; Test direct environment variable access
    EnvGet, testPassword, INCO_PW
    if (testPassword = "") {
        MsgBox, 16, SECURITY ERROR, INCO_PW environment variable not found!`n`nPlease check your .env file.
        return
    }

    ; Test the secure sending function
    if (IsFunc("SendSecretFromEnv")) {
        MsgBox, 64, Success, INCO_PW found in environment!`n`nPassword length: %StrLen(testPassword)% characters`n`nFunction SendSecretFromEnv is available.`n`nThe security fix is working correctly.

        ; Optional: Test the actual function (will type the password)
        MsgBox, 36, Test Typing, Would you like to test the actual password typing?`n`n(This will type the password to the active window.)
        IfMsgBox, Yes
        {
            SendSecretFromEnv("INCO_PW", "Enter your INCO password")
            MsgBox, 64, Test Complete, Password typed to active window.
        }
    } else {
        MsgBox, 48, Warning, SendSecretFromEnv function not available.`n`nEnvironment variable is loaded, but the enhanced security module may not be included.
    }
return

; Show environment variables for debugging
^!+e::
    envVars := "Environment Variables:`n`n"
    varsToCheck := ["INCO_PW", "OPENAI_API_KEY", "OPENROUTER_API_KEY", "PROMPTOPT_MODE"]

    for index, varName in varsToCheck {
        EnvGet, value, %varName%
        if (value != "") {
            if (InStr(varName, "KEY") || varName = "INCO_PW") {
                ; Mask sensitive values
                masked := SubStr(value, 1, 3) . "***" . SubStr(value, StrLen(value)-2)
                envVars .= varName . ": " . masked . " (length: " . StrLen(value) . ")`n"
            } else {
                envVars .= varName . ": " . value . "`n"
            }
        } else {
            envVars .= varName . ": [NOT SET]`n"
        }
    }

    MsgBox, 64, Environment Debug, %envVars%
return

; Exit script
^!+x::
    ExitApp
return

; Show help
^!+h::
    helpText =
    (
Security Fix Test Script - Hotkeys:

Ctrl+Alt+Shift+I : Test INCO_PW environment variable
Ctrl+Alt+Shift+E : Show environment variables (debug)
Ctrl+Alt+Shift+X : Exit this test script
Ctrl+Alt+Shift+H : Show this help

The main security fix has been applied to hotstrings/general.ahk
The hardcoded password has been replaced with environment variable INCO_PW

Test the incopw hotstring in any text editor to verify it works.
    )
    MsgBox, 64, Help, %helpText%
return

; Auto-show help on launch
MsgBox, 64, Security Fix Test, Security Fix Test Script Loaded!`n`nPress Ctrl+Alt+Shift+H for help.`n`nPress Ctrl+Alt+Shift+I to test the fix.