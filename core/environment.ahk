SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # CORE ENVIRONMENT MODULE                                          #
; # Purpose: Environment loading, secret handling, helper functions  #
; ####################################################################

; -------------------------------------------------------------------
; Function: LoadDotEnv()
; Purpose : Loads environment variables from .env file in script root
;           Supports quoted strings (double or single quotes)
;           Skips comments (lines starting with #) and empty lines
; -------------------------------------------------------------------
LoadDotEnv() {
    file := A_ScriptDir . "\.env"
    if !FileExist(file)
        return
    Loop Read file
    {
        line := Trim(A_LoopReadLine)
        if (line = "")
            continue
        if (SubStr(line, 1, 1) = "#")
            continue
        pos := InStr(line, "=")
        if (!pos)
            continue
        key := Trim(SubStr(line, 1, pos-1))
        val := Trim(SubStr(line, pos+1))
        dq := Chr(34)
        if (SubStr(val, 1, 1) = dq && SubStr(val, StrLen(val)) = dq)
            val := SubStr(val, 2, StrLen(val)-2)
        else if (SubStr(val, 1, 1) = "'" && SubStr(val, StrLen(val)) = "'")
            val := SubStr(val, 2, StrLen(val)-2)
        if (key != "")
            EnvSet(key, val)
    }
}

; -------------------------------------------------------------------
; Function: SendSecretFromEnv(varName, promptText)
; Purpose : Safely sends a secret from environment variable only
;           Shows tooltip if env var is not set
;           SECURITY: Never prompts user or logs secrets
; -------------------------------------------------------------------
SendSecretFromEnv(varName, promptText) {
    val := EnvGet(varName)
    if (val = "") {
        ToolTip("Env var not set: " varName, A_ScreenWidth-420, A_ScreenHeight-80)
        SetTimer __HideTipSec, -1200
        return
    }
    SendText val
}

; -------------------------------------------------------------------
; Function: SendHotstringText(text)
; Purpose : Sends text using clipboard paste method (more reliable for
;           complex text with special characters). Temporarily replaces
;           clipboard content, pastes, then restores original content.
; -------------------------------------------------------------------
SendHotstringText(text) {
    ClipSaved := SaveClipboard()
    A_Clipboard := text
    if ClipWait(2) {
        Send "^v"
    }
    Sleep 100
    RestoreClipboard(ClipSaved)
}

; -------------------------------------------------------------------
; Label: __HideTipSec
; Purpose: Timer callback to hide tooltip after security messages
; -------------------------------------------------------------------
__HideTipSec() {
    ToolTip()
}

; -------------------------------------------------------------------
; Function: SaveClipboard()
; Purpose : Saves current clipboard content for later restoration
; Returns : ClipboardAll data
; -------------------------------------------------------------------
SaveClipboard() {
    return ClipboardAll
}

; -------------------------------------------------------------------
; Function: RestoreClipboard(ByRef savedClip)
; Purpose : Restores previously saved clipboard content
; -------------------------------------------------------------------
RestoreClipboard(&savedClip) {
    A_Clipboard := savedClip
    savedClip := ""
}
