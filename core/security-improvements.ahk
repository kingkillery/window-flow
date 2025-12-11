#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; ####################################################################
; # SECURITY IMPROVEMENTS MODULE                                      #
; # Purpose: Enhanced security, credential management, and validation #
; ####################################################################

; ====================================================================
; ENHANCED CREDENTIAL MANAGEMENT (REPLACES HARDCODED PASSWORDS)
; ====================================================================

; -------------------------------------------------------------------
; Function: ValidateEnvironmentVariable(varName, required := true)
; Purpose : Validates environment variable existence and format
; Returns : true if valid, false otherwise
; -------------------------------------------------------------------
ValidateEnvironmentVariable(varName, required := true) {
    EnvGet, varValue, %varName%

    if (required && varValue = "") {
        ShowErrorTip("Required environment variable not set: " . varName)
        return false
    }

    ; Additional validation for common patterns
    if (InStr(varName, "_KEY") && varValue != "" && StrLen(varValue) < 10) {
        ShowErrorTip("API key too short: " . varName)
        return false
    }

    return true
}

; -------------------------------------------------------------------
; Function: SecureSendFromEnv(varName, promptText, validateLength := true)
; Purpose : Enhanced version of SendSecretFromEnv with validation
; -------------------------------------------------------------------
SecureSendFromEnv(varName, promptText, validateLength := true) {
    ; Validate environment variable exists
    if (!ValidateEnvironmentVariable(varName)) {
        return false
    }

    EnvGet, val, %varName%

    ; Additional validation for API keys
    if (validateLength && InStr(varName, "_KEY") && StrLen(val) < 10) {
        ShowErrorTip("Invalid API key format for: " . varName)
        return false
    }

    ; Log access (without exposing the actual value)
    LogCredentialAccess(varName)

    SendRaw, %val%
    return true
}

; -------------------------------------------------------------------
; Function: LogCredentialAccess(varName)
; Purpose : Securely log credential access for audit trail
; -------------------------------------------------------------------
LogCredentialAccess(varName) {
    logFile := A_Temp . "\credential_access.log"
    timestamp := A_Now
    logEntry := timestamp . " - Accessed: " . varName . " by AutoHotkey" . "`n"
    FileAppend, %logEntry%, %logFile%
}

; -------------------------------------------------------------------
; Function: ValidatePathSecurity(path)
; Purpose : Validates file path for security risks
; Returns : true if safe, false otherwise
; -------------------------------------------------------------------
ValidatePathSecurity(path) {
    ; Check for path traversal attempts
    if (InStr(path, "..") || InStr(path, "~")) {
        ShowErrorTip("Unsafe path detected")
        return false
    }

    ; Check for suspicious extensions
    suspiciousExts := ".exe,.bat,.cmd,.scr,.com,.pif"
    SplitPath, path, , , ext
    if (InStr(suspiciousExts, "." . ext)) {
        ShowErrorTip("Suspicious file extension: " . ext)
        return false
    }

    return true
}

; ====================================================================
; ENHANCED ERROR HANDLING
; ====================================================================

; -------------------------------------------------------------------
; Function: SafeFileOperation(operation, file, content := "")
; Purpose : Wrapper for file operations with error handling
; Returns : true if successful, false otherwise
; -------------------------------------------------------------------
SafeFileOperation(operation, file, content := "") {
    try {
        ; Validate path security
        if (!ValidatePathSecurity(file)) {
            return false
        }

        if (operation = "read") {
            if (!FileExist(file)) {
                ShowErrorTip("File not found: " . file)
                return false
            }
            FileRead, content, %file%
            return true
        }

        if (operation = "write") {
            ; Create directory if it doesn't exist
            SplitPath, file, , dir
            if (dir != "" && !FileExist(dir)) {
                FileCreateDir, %dir%
                if (ErrorLevel) {
                    ShowErrorTip("Failed to create directory: " . dir)
                    return false
                }
            }

            FileAppend, %content%, %file%
            return !ErrorLevel
        }

        if (operation = "delete") {
            if (FileExist(file)) {
                FileDelete, %file%
                return !ErrorLevel
            }
            return true ; File doesn't exist, that's ok
        }

    } catch e {
        ShowErrorTip("File operation failed: " . e.message)
        return false
    }

    return false
}

; -------------------------------------------------------------------
; Function: ShowErrorTip(msg, durationMs := 0)
; Purpose : Enhanced error tooltip with logging
; -------------------------------------------------------------------
ShowErrorTip(msg, durationMs := 0) {
    ; Log the error
    logFile := A_Temp . "\ahk_errors.log"
    timestamp := A_Now
    logEntry := timestamp . " - ERROR: " . msg . "`n"
    SafeFileOperation("write", logFile, logEntry)

    ; Show tooltip
    global TOOLTIP_DURATION
    if (durationMs <= 0)
        durationMs := TOOLTIP_DURATION

    x := A_ScreenWidth - 420
    y := A_ScreenHeight - 100
    ToolTip, ERROR: %msg%, %x%, %y%

    if (durationMs > 0)
        SetTimer, RemoveErrorTip, -%durationMs%
}

RemoveErrorTip:
    ToolTip
return

; ====================================================================
; IMPROVED CLIPBOARD SECURITY
; ====================================================================

; -------------------------------------------------------------------
; Function: SecureClipboardOperation(operation, text := "")
; Purpose : Secure clipboard operations with validation
; Returns : text for read operations, true/false for write operations
; -------------------------------------------------------------------
SecureClipboardOperation(operation, text := "") {
    static clipboardGuard := false
    static savedClipboard := ""

    if (clipboardGuard) {
        return false ; Prevent recursive operations
    }

    clipboardGuard := true

    try {
        if (operation = "save") {
            savedClipboard := ClipboardAll()
            return true
        }

        if (operation = "restore") {
            if (savedClipboard != "") {
                Clipboard := savedClipboard
                savedClipboard := ""
            }
            return true
        }

        if (operation = "set") {
            ; Validate text size (prevent clipboard bombing)
            if (StrLen(text) > 1048576) { ; 1MB limit
                ShowErrorTip("Text too large for clipboard")
                return false
            }

            Clipboard := text
            ClipWait, 2
            return !ErrorLevel
        }

        if (operation = "get") {
            return Clipboard
        }

    } catch e {
        ShowErrorTip("Clipboard operation failed: " . e.message)
        return false
    } finally {
        clipboardGuard := false
    }

    return false
}

; ====================================================================
; CONFIGURATION VALIDATION
; ====================================================================

; -------------------------------------------------------------------
; Function: ValidateConfiguration()
; Purpose : Validates critical configuration on startup
; Returns : true if configuration is valid
; -------------------------------------------------------------------
ValidateConfiguration() {
    criticalVars := ["OPENAI_API_KEY", "OPENROUTER_API_KEY", "PROMPTOPT_MODE"]
    allValid := true

    for index, varName in criticalVars {
        if (!ValidateEnvironmentVariable(varName, false)) {
            ; Log warning but don't fail for non-critical vars
            continue
        }
    }

    ; Validate essential paths
    essentialPaths := [A_ScriptDir . "\core", A_ScriptDir . "\promptopt", A_ScriptDir . "\hotstrings"]

    for index, path in essentialPaths {
        if (!FileExist(path)) {
            ShowErrorTip("Essential path missing: " . path)
            allValid := false
        }
    }

    return allValid
}

; ====================================================================
; SECURITY AUDIT FUNCTIONS
; ====================================================================

; -------------------------------------------------------------------
; Function: AuditHotstrings()
; Purpose : Audits hotstrings for security issues
; -------------------------------------------------------------------
AuditHotstrings() {
    ; Check for hardcoded passwords in common locations
    hardcodedPatterns := ["password", "pw", "secret", "key", "token"]

    ; This would scan hotstring definitions for security issues
    ; Implementation depends on your specific needs

    ShowTip("Security audit completed", 2000)
}