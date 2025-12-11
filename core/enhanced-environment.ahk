SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # ENHANCED ENVIRONMENT MODULE                                       #
; # Purpose: Improved environment loading with caching and validation  #
; # Replaces: core/environment.ahk                                      #
; ####################################################################

; ====================================================================
; GLOBAL VARIABLES FOR ENVIRONMENT CACHING
; ====================================================================
global _EnvCache := {}
global _EnvLoaded := false
global _ConfigPath := A_ScriptDir . "\.env"

; ====================================================================
; ENHANCED ENVIRONMENT LOADING WITH CACHING
; ====================================================================

; -------------------------------------------------------------------
; Function: LoadDotEnv()
; Purpose : Enhanced .env loader with caching, validation, and error handling
;           Supports quoted strings, comments, and environment variable expansion
; -------------------------------------------------------------------
LoadDotEnv() {
    global _EnvCache, _EnvLoaded, _ConfigPath

    ; Skip if already loaded
    if (_EnvLoaded) {
        return true
    }

    if (!FileExist(_ConfigPath)) {
        ShowTip("No .env file found at: " . _ConfigPath, 1000)
        return false
    }

    try {
        FileRead, fileContent, %_ConfigPath%

        ; Validate file size (prevent processing extremely large files)
        if (StrLen(fileContent) > 65536) { ; 64KB limit
            ShowErrorTip(".env file too large (>64KB)")
            return false
        }

        lines := StrSplit(fileContent, "`n")
        validEntries := 0

        for index, line in lines {
            line := Trim(line)

            ; Skip empty lines and comments
            if (line = "" || SubStr(line, 1, 1) = "#") {
                continue
            }

            ; Parse key=value pairs
            pos := InStr(line, "=")
            if (!pos) {
                continue ; Skip malformed lines
            }

            key := Trim(SubStr(line, 1, pos - 1))
            val := Trim(SubStr(line, pos + 1))

            ; Validate key format
            if (!RegExMatch(key, "^[A-Za-z_][A-Za-z0-9_]*$")) {
                ShowErrorTip("Invalid environment variable name: " . key)
                continue
            }

            ; Handle quoted values
            val := ParseQuotedValue(val)

            ; Environment variable expansion (${VAR} syntax)
            val := ExpandEnvironmentVariables(val)

            ; Cache and set the environment variable
            _EnvCache[key] := val
            EnvSet(key, val)
            validEntries++
        }

        _EnvLoaded := true
        ShowTip("Loaded " . validEntries . " environment variables", 1000)
        return true

    } catch e {
        ShowErrorTip("Failed to load .env file: " . e.message)
        return false
    }
}

; -------------------------------------------------------------------
; Function: ParseQuotedValue(value)
; Purpose : Handles quoted and unquoted values
; Returns : Parsed string value
; -------------------------------------------------------------------
ParseQuotedValue(value) {
    dq := Chr(34)
    sq := "'"

    ; Handle double quotes
    if (SubStr(value, 1, 1) = dq && SubStr(value, StrLen(value)) = dq) {
        return SubStr(value, 2, StrLen(value) - 2)
    }

    ; Handle single quotes
    if (SubStr(value, 1, 1) = sq && SubStr(value, StrLen(value)) = sq) {
        return SubStr(value, 2, StrLen(value) - 2)
    }

    return value
}

; -------------------------------------------------------------------
; Function: ExpandEnvironmentVariables(text)
; Purpose : Expands ${VAR} references within environment variable values
; Returns : Text with expanded variables
; -------------------------------------------------------------------
ExpandEnvironmentVariables(text) {
    ; Simple ${VAR} expansion
    while (RegExMatch(text, "\$\{([A-Za-z_][A-Za-z0-9_]*)\}", match)) {
        varName := match1
        EnvGet, varValue, %varName%
        text := StrReplace(text, match, varValue)
    }

    return text
}

; ====================================================================
; ENHANCED ENVIRONMENT VARIABLE ACCESS
; ====================================================================

; -------------------------------------------------------------------
; Function: GetEnvVar(varName, defaultValue := "")
; Purpose : Cached environment variable access with default values
; Returns : Environment variable value or default
; -------------------------------------------------------------------
GetEnvVar(varName, defaultValue := "") {
    global _EnvCache

    ; Load environment if not already loaded
    if (!_EnvLoaded) {
        LoadDotEnv()
    }

    ; Return cached value if available
    if (_EnvCache.HasKey(varName)) {
        return _EnvCache[varName]
    }

    ; Fallback to direct environment variable access
    EnvGet, value, %varName%
    if (value != "") {
        _EnvCache[varName] := value
        return value
    }

    return defaultValue
}

; -------------------------------------------------------------------
; Function: SetEnvVar(varName, value)
; Purpose : Sets and caches environment variable
; Returns : true if successful
; -------------------------------------------------------------------
SetEnvVar(varName, value) {
    global _EnvCache

    try {
        ; Validate variable name
        if (!RegExMatch(varName, "^[A-Za-z_][A-Za-z0-9_]*$")) {
            ShowErrorTip("Invalid environment variable name: " . varName)
            return false
        }

        ; Set in cache and system
        _EnvCache[varName] := value
        EnvSet(varName, value)
        return true
    } catch e {
        ShowErrorTip("Failed to set environment variable: " . e.message)
        return false
    }
}

; ====================================================================
; CONFIGURATION VALIDATION UTILITIES
; ====================================================================

; -------------------------------------------------------------------
; Function: ValidateRequiredVars(requiredVars*)
; Purpose : Validates that all required environment variables are set
; Returns : Object with validation results
; -------------------------------------------------------------------
ValidateRequiredVars(requiredVars*) {
    result := {valid: true, missing: [], present: []}

    for index, varName in requiredVars {
        value := GetEnvVar(varName)
        if (value = "") {
            result.valid := false
            result.missing.Push(varName)
        } else {
            result.present.Push(varName)
        }
    }

    return result
}

; -------------------------------------------------------------------
; Function: GetConfigurationSummary()
; Purpose : Returns a summary of loaded configuration
; Returns : Object with configuration information
; -------------------------------------------------------------------
GetConfigurationSummary() {
    global _EnvLoaded, _ConfigPath, _EnvCache

    return {
        loaded: _EnvLoaded,
        configFile: _ConfigPath,
        configExists: FileExist(_ConfigPath),
        variableCount: _EnvCache.Count(),
        lastModified: _EnvLoaded ? FileGetTime(_ConfigPath) : ""
    }
}

; ====================================================================
; MAINTENANCE FUNCTIONS
; ====================================================================

; -------------------------------------------------------------------
; Function: RefreshEnvironment()
; Purpose : Forces reload of environment variables
; Returns : true if successful
; -------------------------------------------------------------------
RefreshEnvironment() {
    global _EnvCache, _EnvLoaded

    _EnvCache := {}
    _EnvLoaded := false

    return LoadDotEnv()
}

; -------------------------------------------------------------------
; Function: BackupConfiguration()
; Purpose : Creates a backup of current .env file
; Returns : Path to backup file or empty string on failure
; -------------------------------------------------------------------
BackupConfiguration() {
    global _ConfigPath

    if (!FileExist(_ConfigPath)) {
        ShowErrorTip("No .env file to backup")
        return ""
    }

    timestamp := A_Now
    timestamp := RegExReplace(timestamp, "(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})", "$1$2$3_$4$5$6")
    backupPath := A_ScriptDir . "\.env.backup." . timestamp

    try {
        FileCopy, %_ConfigPath%, %backupPath%
        ShowTip("Configuration backed up to: " . backupPath, 2000)
        return backupPath
    } catch e {
        ShowErrorTip("Failed to backup configuration: " . e.message)
        return ""
    }
}

; ====================================================================
; LEGACY COMPATIBILITY
; ====================================================================

; -------------------------------------------------------------------
; Function: SendHotstringText(text)
; Purpose : Maintains compatibility with existing hotstring functions
;           Enhanced with clipboard security
; -------------------------------------------------------------------
SendHotstringText(text) {
    ; Use the secure clipboard operation from security-improvements.ahk
    if (IsFunc("SecureClipboardOperation")) {
        SecureClipboardOperation("save")
        success := SecureClipboardOperation("set", text)
        if (success) {
            Send, ^v
        }
        SecureClipboardOperation("restore")
        return success
    }

    ; Fallback to original implementation
    ClipSaved := SaveClipboard()
    Clipboard := text
    ClipWait, 2
    if (!ErrorLevel) {
        Send, ^v
    }
    Sleep, 100
    RestoreClipboard(ClipSaved)
    return !ErrorLevel
}

; -------------------------------------------------------------------
; Function: SendSecretFromEnv(varName, promptText)
; Purpose : Maintains compatibility with existing API key hotstrings
;           Enhanced with validation and logging
; -------------------------------------------------------------------
SendSecretFromEnv(varName, promptText) {
    if (IsFunc("SecureSendFromEnv")) {
        return SecureSendFromEnv(varName, promptText)
    }

    ; Fallback to original implementation
    EnvGet, val, %varName%
    if (val = "") {
        ToolTip, Env var not set: %varName%, % A_ScreenWidth-420, % A_ScreenHeight-80
        SetTimer, __HideTipSec, -1200
        return false
    }
    SendRaw, %val%
    return true
}

; -------------------------------------------------------------------
; Function: SaveClipboard()
; Function: RestoreClipboard(ByRef savedClip)
; Purpose : Legacy clipboard functions for compatibility
; -------------------------------------------------------------------
SaveClipboard() {
    return ClipboardAll
}

RestoreClipboard(ByRef savedClip) {
    Clipboard := savedClip
    savedClip := ""
}

; -------------------------------------------------------------------
; Label: __HideTipSec
; Purpose: Timer callback for legacy compatibility
; -------------------------------------------------------------------
__HideTipSec:
    ToolTip
return