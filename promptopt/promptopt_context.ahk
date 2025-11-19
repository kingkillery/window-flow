; promptopt_context.ahk - Context Menu Launcher for PromptOpt
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; Working directory and encoding
SetWorkingDir(A_ScriptDir)
FileEncoding("UTF-8")

; Load .env into process environment
LoadDotEnv()

; Add small delay to avoid conflicts with main Template.ahk
Sleep(100)

; Parse command line arguments
args := A_Args
action := ""
profile := ""
filePath := ""

if (args.Length >= 1) {
    action := args[1]
    if (args.Length >= 2) {
        profile := args[2]
    }
}

; Handle different actions
if (action = "settings") {
    ShowSettingsGui()
    ExitApp()
} else if (action = "about") {
    ShowAboutDialog()
    ExitApp()
} else if (action = "clipboard") {
    ; Use clipboard content
    ProcessClipboardText(profile)
} else if (action = "copyraw") {
    ; Copy raw file content to clipboard
    if (FileExist(profile)) {
        CopyRawFileContent(profile)
    } else {
        ShowError("File not found: " profile)
    }
    ExitApp()
} else if (FileExist(action)) {
    ; Process file content
    ProcessFileContent(action, profile)
} else {
    ShowError("Invalid context menu action: " action)
}

ExitApp()

; Process clipboard text with PromptOpt
ProcessClipboardText(profile) {
    ; Get clipboard content without modifying it - use a non-invasive approach
    try {
        ; Create a temporary clipboard monitor to avoid interfering with normal operations
        userText := A_Clipboard
    } catch {
        ShowError("Unable to access clipboard")
        return
    }

    if (userText = "" || RegExReplace(userText, "\s+", "") = "") {
        ShowError("Clipboard is empty")
        return
    }

    ; Launch PromptOpt with the text - this should NOT modify the clipboard until the very end
    LaunchPromptOpt(userText, profile)
}

; Copy raw file content to clipboard
CopyRawFileContent(filePath) {
    if !FileExist(filePath) {
        ShowError("File not found: " filePath)
        return
    }

    try {
        fileContent := FileRead(filePath, "UTF-8")
        if (fileContent = "") {
            ShowError("File is empty: " filePath)
            return
        }

        ; Copy to clipboard
        A_Clipboard := fileContent
        if ClipWait(1) {
            SoundBeep(1000, 120)
            ShowSuccess("Raw content copied to clipboard!")

            ; Show brief info about what was copied
            fileName := StrSplit(filePath, "\").Pop()
            lineCount := StrSplit(fileContent, "`n").Length
            charCount := StrLen(fileContent)
            ShowInfo("Copied " fileName "`n" lineCount " lines, " charCount " characters")
        } else {
            ShowError("Failed to copy to clipboard")
        }
    } catch as e {
        ShowError("Failed to read file: " e.Message)
    }
}

; Process file or directory content
ProcessFileContent(path, profile) {
    if !FileExist(path) {
        ShowError("Path not found: " path)
        return
    }

    try {
        attr := FileGetAttrib(path)
        userText := ""
        
        if (InStr(attr, "D")) {
            ; It's a directory - concatenate all text files
            Loop Files, path "\*.*", "R"
            {
                if (A_LoopFileExt = "txt" || A_LoopFileExt = "md" || A_LoopFileExt = "ahk" || A_LoopFileExt = "py" || A_LoopFileExt = "js" || A_LoopFileExt = "ts" || A_LoopFileExt = "json" || A_LoopFileExt = "html" || A_LoopFileExt = "css" || A_LoopFileExt = "ps1" || A_LoopFileExt = "bat" || A_LoopFileExt = "sh") {
                    try {
                        content := FileRead(A_LoopFileFullPath, "UTF-8")
                        userText .= "--- FILE: " A_LoopFileName " ---`n"
                        userText .= content "`n`n"
                    }
                }
            }
            
            if (userText = "") {
                ShowError("No text files found in directory: " path)
                return
            }
            
            if (profile = "copyraw") {
                 A_Clipboard := userText
                 if ClipWait(1) {
                     SoundBeep(1000, 120)
                     ShowSuccess("Directory content copied to clipboard!")
                 }
                 return
            }
        } else {
            ; It's a file
            userText := FileRead(path, "UTF-8")
            if (userText = "") {
                ShowError("File is empty: " path)
                return
            }
            
             if (profile = "copyraw") {
                 A_Clipboard := userText
                 if ClipWait(1) {
                     SoundBeep(1000, 120)
                     ShowSuccess("File content copied to clipboard!")
                 }
                 return
            }
        }

        ; Launch PromptOpt with the content
        LaunchPromptOpt(userText, profile)
    } catch as e {
        ShowError("Failed to process content: " e.Message)
    }
}

; Launch PromptOpt with specified text and profile
LaunchPromptOpt(userText, profile) {
    ; Save text to temp file for PromptOpt to process
    tmpSel := A_Temp "\promptopt_context_" A_TickCount ".txt"
    try FileDelete(tmpSel)
    FileAppend(userText, tmpSel, "UTF-8")

    ; Launch PromptOpt main script with command-line arguments
    ; This gives us all features: streaming, model selection, error handling, etc.
    promptoptPath := A_ScriptDir "\promptopt.ahk"
    if !FileExist(promptoptPath) {
        ShowError("Missing PromptOpt script: " promptoptPath)
        return
    }

    ; Build command with arguments
    ; --file: read from file instead of clipboard
    ; --profile: pre-select profile
    ; --skip-pickers: use provided profile/model without showing pickers (faster workflow)
    cmd := QQ(promptoptPath) " --file " QQ(tmpSel) " --profile " QQ(profile) " --skip-pickers"

    ; Launch main script (it will handle everything: API calls, streaming, result window, etc.)
    ; Use Run instead of RunWait so context menu script can exit immediately
    ; The main script will handle its own lifecycle
    try {
        Run(cmd)
        ; Brief success message
        ShowSuccess("PromptOpt started with " profile " profile")
        Sleep(500)
    } catch as e {
        ShowError("Failed to launch PromptOpt: " e.Message)
        try FileDelete(tmpSel)
    }
}

; Show settings GUI
ShowSettingsGui() {
    settingsGui := Gui("+Resize +MinSize +AlwaysOnTop", "PromptOpt Settings")
    settingsGui.SetFont("s10", "Segoe UI")

    ; API Keys section
    settingsGui.Add("Text", "w600 h20 +Background0x0F0F0F", "API Keys")
    settingsGui.Add("Text", , "OpenRouter API Key:")
    openrouterEdit := settingsGui.Add("Edit", "w400 h25 vOpenRouterKey")
    openrouterEdit.Value := EnvGet("OPENROUTER_API_KEY")

    settingsGui.Add("Text", , "OpenAI API Key:")
    openaiEdit := settingsGui.Add("Edit", "w400 h25 vOpenAIKey")
    openaiEdit.Value := EnvGet("OPENAI_API_KEY")

    settingsGui.Add("Text", "w600", "")

    ; Default profile section
    settingsGui.Add("Text", "w600 h20 +Background0x0F0F0F", "Default Settings")
    settingsGui.Add("Text", , "Default Profile:")
    profileDropDown := settingsGui.Add("DropDownList", "w200 vDefaultProfile", ["Browser/Computer","Coding","Writing","RAG","General","Custom"])

    lastProfile := LoadLastProfile()
    if (lastProfile = "browser") {
        profileDropDown.Choose(1)
    } else if (lastProfile = "coding") {
        profileDropDown.Choose(2)
    } else if (lastProfile = "writing") {
        profileDropDown.Choose(3)
    } else if (lastProfile = "rag") {
        profileDropDown.Choose(4)
    } else if (lastProfile = "general") {
        profileDropDown.Choose(5)
    } else if (lastProfile = "custom") {
        profileDropDown.Choose(6)
    }

    autoSelectCheck := settingsGui.Add("CheckBox", "vAutoSelect", "Don't ask for profile selection (use default)")
    autoSelectCheck.Value := LoadAutoSelect() ? 1 : 0

    settingsGui.Add("Text", "w600", "")

    ; Buttons
    saveBtn := settingsGui.Add("Button", "w96", "Save")
    cancelBtn := settingsGui.Add("Button", "x+8 w96", "Cancel")
    resetBtn := settingsGui.Add("Button", "x+8 w96", "Reset")

    saveBtn.OnEvent("Click", SaveSettings.Bind(settingsGui, openrouterEdit, openaiEdit, profileDropDown, autoSelectCheck))
    cancelBtn.OnEvent("Click", (*) => settingsGui.Close())
    resetBtn.OnEvent("Click", ResetSettings.Bind(settingsGui, openrouterEdit, openaiEdit, profileDropDown, autoSelectCheck))

    settingsGui.Show()
}

SaveSettings(gui, openrouterEdit, openaiEdit, profileDropDown, autoSelectCheck, *) {
    ; Save API keys to environment
    EnvSet("OPENROUTER_API_KEY", openrouterEdit.Value)
    EnvSet("OPENAI_API_KEY", openaiEdit.Value)

    ; Save default profile
    profiles := ["browser","coding","writing","rag","general","custom"]
    profileIndex := profileDropDown.Value
    if (profileIndex >= 1 && profileIndex <= profiles.Length) {
        SaveLastProfile(profiles[profileIndex])
    }

    ; Save auto-select setting
    SaveAutoSelect(autoSelectCheck.Value ? true : false)

    ShowSuccess("Settings saved successfully!")
    Sleep(1000)
    gui.Close()
}

ResetSettings(gui, openrouterEdit, openaiEdit, profileDropDown, autoSelectCheck, *) {
    openrouterEdit.Value := ""
    openaiEdit.Value := ""
    profileDropDown.Choose(1)
    autoSelectCheck.Value := 0
}

ShowAboutDialog() {
    aboutGui := Gui("+AlwaysOnTop", "About PromptOpt")
    aboutGui.SetFont("s11", "Segoe UI")
    aboutGui.Add("Text", "w400 Center", "PromptOpt v2.0")
    aboutGui.Add("Text", "w400 Center", "AI-powered prompt optimization tool")
    aboutGui.Add("Text", "w400 Center", "")
    aboutGui.Add("Text", "w400 Center", "Features:")
    aboutGui.Add("Text", "w400 Center", "• Multiple optimization profiles")
    aboutGui.Add("Text", "w400 Center", "• Support for OpenAI & OpenRouter APIs")
    aboutGui.Add("Text", "w400 Center", "• Context menu integration")
    aboutGui.Add("Text", "w400 Center", "• Real-time streaming preview")
    aboutGui.Add("Text", "w400 Center", "")
    aboutGui.Add("Text", "w400 Center", "© 2025 - PromptOpt Project")
    aboutGui.Add("Button", "w96 Default Center", "OK").OnEvent("Click", (*) => aboutGui.Close())
    aboutGui.Show()
}

; ShowResultWindow removed - now handled by main promptopt.ahk script

; CopyToClipboard removed - now handled by main promptopt.ahk script

; Helper functions
QQ(s) {
    return '"' s '"'
}

LoadDotEnv() {
    path := A_ScriptDir "\\.env"
    if !FileExist(path)
        return
    try {
        content := FileRead(path, "UTF-8")
        for line in StrSplit(content, "`n") {
            line := Trim(StrReplace(line, "`r"))
            if (line = "" || SubStr(line, 1, 1) = "#")
                continue
            pos := InStr(line, "=")
            if !pos
                continue
            key := Trim(SubStr(line, 1, pos - 1))
            val := Trim(SubStr(line, pos + 1))
            if (SubStr(val, 1, 1) = '"' && SubStr(val, StrLen(val)) = '"')
                val := SubStr(val, 2, StrLen(val) - 2)
            else if (SubStr(val, 1, 1) = "'" && SubStr(val, StrLen(val)) = "'")
                val := SubStr(val, 2, StrLen(val) - 2)
            if (key != "")
                EnvSet(key, val)
        }
    }
}

; GetDefaultModelForProfile removed - now handled by main promptopt.ahk script

GetConfigIniPath() {
    dir := A_AppData "\\PromptOpt"
    try DirCreate(dir)
    return dir "\\config.ini"
}

LoadLastProfile() {
    ini := GetConfigIniPath()
    val := ""
    try val := IniRead(ini, "profile", "last", "")
    if (val = "browser" || val = "coding" || val = "writing" || val = "rag" || val = "general" || val = "custom")
        return val
    return ""
}

SaveLastProfile(token) {
    if !(token = "browser" || token = "coding" || token = "writing" || token = "rag" || token = "general" || token = "custom")
        return
    ini := GetConfigIniPath()
    try IniWrite(token, ini, "profile", "last")
}

LoadAutoSelect() {
    ini := GetConfigIniPath()
    val := 0
    try val := IniRead(ini, "profile", "autoselect", 0)
    return val ? true : false
}

SaveAutoSelect(on) {
    ini := GetConfigIniPath()
    try IniWrite(on ? 1 : 0, ini, "profile", "autoselect")
}

ShowProgress(msg) {
    ToolTip(msg, A_ScreenWidth - 340, A_ScreenHeight - 100, 1)
}

ShowSuccess(msg) {
    ToolTip("✅ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SoundBeep(1000, 100)
    SetTimer(() => ToolTip("", , , 2), -2000)
}

ShowInfo(msg) {
    ToolTip("ℹ️ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SetTimer(() => ToolTip("", , , 2), -3000)
}

ShowError(msg) {
    ToolTip("❌ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SoundBeep(500, 300)
    SetTimer(() => ToolTip("", , , 2), -3000)
}

PathShort(p) {
    return (StrLen(p) > 60) ? (SubStr(p, 1, 25) "…" SubStr(p, -25)) : p
}