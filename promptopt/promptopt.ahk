#Requires AutoHotkey v2.0
#SingleInstance Off
SendMode("Input")
SetWorkingDir(A_ScriptDir)

; ====================================================================
; CONFIGURATION & SETUP
; ====================================================================
global SCRIPT_DIR := A_ScriptDir
global PARENT_DIR := RegExReplace(SCRIPT_DIR, "\\[^\\]+$", "")
global META_PROMPT_DIR := PARENT_DIR . "\meta-prompts"
global OUTPUT_FILE := A_Temp . "\promptopt_out_" . A_TickCount . ".txt"
global SELECTION_FILE := A_Temp . "\promptopt_sel_" . A_TickCount . ".txt"
global LOG_FILE := A_Temp . "\promptopt_log_" . A_TickCount . ".log"
global CUSTOM_PROMPT_FILE := A_Temp . "\promptopt_custom_" . A_TickCount . ".txt"

; Global references for GUI controls to allow hotkey manipulation
global g_DDLProfile := ""
global g_EditCustom := ""
global g_CustomPrompts := []
global g_CustomPromptIndex := 0

; Load environment variables
LoadDotEnv(PARENT_DIR . "\.env")

; ====================================================================
; MAIN EXECUTION
; ====================================================================

; Parse Arguments
args := ParseArgs()
mode := EnvGet("PROMPTOPT_MODE") ? EnvGet("PROMPTOPT_MODE") : "meta"
model := EnvGet("OPENAI_MODEL") ? EnvGet("OPENAI_MODEL") : "openai/gpt-oss-120b"
profile := args.Has("profile") ? args["profile"] : (EnvGet("PROMPTOPT_PROFILE") ? EnvGet("PROMPTOPT_PROFILE") : "browser")
skipPickers := args.Has("skip-pickers")

; Get Input Text
inputText := ""
if (args.Has("file")) {
    try {
        inputText := FileRead(args["file"], "UTF-8")
    } catch {
        MsgBox("Failed to read input file: " . args["file"])
        ExitApp()
    }
} else {
    ; Clipboard / Selection Mode
    inputText := GetSelectionText()
    
    ; FIX: If no text selected, ask user for input instead of exiting
    if (inputText = "") {
        if (skipPickers) {
            ; If running in background mode, we must exit
            ToolTip("PromptOpt: No text selected.")
            SetTimer(() => ToolTip(), -2000)
            ExitApp()
        }
        
        ; Show Manual Input Dialog
        ib := InputBox("No text was selected.\n\nPlease enter or paste the text you want to optimize below:", "PromptOpt - Manual Input", "w600 h150")
        if (ib.Result = "Cancel" || ib.Value = "") {
            ExitApp() ; User cancelled
        }
        inputText := ib.Value
    }
}

; Write selection to temp file
try {
    if FileExist(SELECTION_FILE)
        FileDelete(SELECTION_FILE)
    FileAppend(inputText, SELECTION_FILE, "UTF-8")
} catch as e {
    MsgBox("Failed to write selection file: " . e.Message)
    ExitApp()
}

; Profile Selection (if not skipped)
if (!skipPickers && !args.Has("profile")) {
    ; Default to environment variable if available, otherwise "browser"
    defaultProfile := EnvGet("PROMPTOPT_PROFILE") ? EnvGet("PROMPTOPT_PROFILE") : "browser"
    
    selected := ShowProfilePicker(defaultProfile, model, inputText)
    if (!selected) {
        ExitApp() ; User cancelled
    }
    
    ; ALWAYS use the text from the picker as the custom prompt
    ; This ensures any edits made by the user are respected.
    profile := "custom"
    model := selected.Model
    pickerSystem := selected.CustomText ; This is now just the System Prompt
    pickerUser := selected.UserText     ; This is the (potentially edited) Input
    
    try {
        FileDelete(CUSTOM_PROMPT_FILE)
        FileAppend(pickerSystem, CUSTOM_PROMPT_FILE, "UTF-8")
        
        ; Also update the selection file with the edited user text
        FileDelete(SELECTION_FILE)
        FileAppend(pickerUser, SELECTION_FILE, "UTF-8")
    }
    
    ; Flag to skip the CLI input box
    pickerUsed := true
}

; Custom Profile Handling
if (profile = "custom") {
    if (!IsSet(pickerUsed)) {
        ; Pre-load prompts for cycling (CLI mode)
        g_CustomPrompts := LoadMetaPromptContents()
        g_CustomPromptIndex := 0
        
        ; We pass the current input text to the dialog so it can be edited
        currentInput := ""
        try currentInput := FileRead(SELECTION_FILE, "UTF-8")
        
        customResult := ShowCustomPromptInput(currentInput)
        if (!customResult) {
            ExitApp() ; User cancelled
        }
        
        try {
            FileDelete(CUSTOM_PROMPT_FILE)
            FileAppend(customResult.System, CUSTOM_PROMPT_FILE, "UTF-8")
            
            FileDelete(SELECTION_FILE)
            FileAppend(customResult.User, SELECTION_FILE, "UTF-8")
        }
    }
}

; Run PromptOpt (PowerShell Bridge)
RunPromptOpt(mode, model, profile)


; ====================================================================
; HOTKEYS
; ====================================================================

; --- Profile Picker Hotkeys ---
#HotIf WinActive("PromptOpt Configuration")
^+WheelUp::CycleProfilePicker(-1)
^+WheelDown::CycleProfilePicker(1)
#HotIf

; --- Custom Input Hotkeys ---
#HotIf WinActive("Custom Instructions")
^+WheelUp::CycleCustomPrompt(-1)
^+WheelDown::CycleCustomPrompt(1)
#HotIf

CycleProfilePicker(direction) {
    global g_DDLProfile
    if (!g_DDLProfile)
        return
    try {
        if (!HasProp(g_DDLProfile, "ItemsArray"))
            return
        
        listItems := g_DDLProfile.ItemsArray
        currentText := g_DDLProfile.Text
        currentIndex := 0
        
        for i, item in listItems {
            if (item = currentText) {
                currentIndex := i
                break
            }
        }
        
        if (currentIndex = 0)
            currentIndex := 1
            
        newIndex := currentIndex + direction
        if (newIndex < 1)
            newIndex := listItems.Length
        else if (newIndex > listItems.Length)
            newIndex := 1
            
        g_DDLProfile.Choose(newIndex)
        
        ; Trigger preview update if function attached
        if (HasProp(g_DDLProfile, "UpdatePreviewFn")) {
            g_DDLProfile.UpdatePreviewFn()
        }
    }
}

CycleCustomPrompt(direction) {
    global g_EditCustom, g_CustomPrompts, g_CustomPromptIndex
    if (!g_EditCustom || g_CustomPrompts.Length = 0)
        return

    g_CustomPromptIndex += direction
    
    ; Handle wrapping
    ; Index 0 is "Blank"
    maxIndex := g_CustomPrompts.Length
    
    if (g_CustomPromptIndex < 0)
        g_CustomPromptIndex := maxIndex
    else if (g_CustomPromptIndex > maxIndex)
        g_CustomPromptIndex := 0
        
    if (g_CustomPromptIndex = 0) {
        g_EditCustom.Value := ""
        ToolTip("Custom: Blank")
    } else {
        item := g_CustomPrompts[g_CustomPromptIndex]
        g_EditCustom.Value := item.Text
        ToolTip("Template: " . item.Name)
    }
    
    SetTimer(() => ToolTip(), -1000)
}

; ====================================================================
; FUNCTIONS
; ====================================================================

ParseArgs() {
    parsed := Map()
    loop A_Args.Length {
        arg := A_Args[A_Index]
        if (SubStr(arg, 1, 2) = "--") {
            key := SubStr(arg, 3)
            val := true
            if (A_Index < A_Args.Length && SubStr(A_Args[A_Index + 1], 1, 1) != "-") {
                val := A_Args[A_Index + 1]
            }
            parsed[key] := val
        }
    }
    return parsed
}

GetSelectionText() {
    savedClip := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    ; FIX: Increased timeout to 0.8s to handle slower apps
    if !ClipWait(0.8) {
        A_Clipboard := savedClip
        return ""
    }
    text := A_Clipboard
    A_Clipboard := savedClip
    return text
}

GetAvailableProfiles() {
    profiles := []
    if (DirExist(META_PROMPT_DIR)) {
        Loop Files, META_PROMPT_DIR . "\Meta_Prompt.*.md"
        {
            if (RegExMatch(A_LoopFileName, "i)Meta_Prompt\.([^.]+)\.md", &match)) {
                profileName := match[1]
                if (profileName != "md") 
                    profiles.Push(StrTitle(profileName))
            }
        }
    }
    if (profiles.Length = 0) {
        profiles := ["Browser", "Coding", "Writing", "RAG", "General"]
    }
    hasCustom := false
    for p in profiles {
        if (p = "Custom")
            hasCustom := true
    }
    if (!hasCustom)
        profiles.Push("Custom")
    return profiles
}

LoadMetaPromptContents() {
    prompts := []
    if (DirExist(META_PROMPT_DIR)) {
        ; We look for specific meta prompt files to offer as templates
        Loop Files, META_PROMPT_DIR . "\Meta_Prompt*.md"
        {
            try {
                content := FileRead(A_LoopFileFullPath, "UTF-8")
                ; Extract python string content: META_PROMPT = """..."""
                if (RegExMatch(content, "s)META_PROMPT\s*=\s*`"`"`"(.*?)`"`"`"", &match)) {
                    name := A_LoopFileName
                    ; Clean up name for display
                    name := StrReplace(name, "Meta_Prompt.", "")
                    name := StrReplace(name, ".md", "")
                    name := StrReplace(name, "_", " ")
                    name := StrTitle(name)
                    
                    prompts.Push({Name: name, Text: Trim(match[1])})
                }
            }
        }
    }
    return prompts
}

ShowProfilePicker(defaultProfile, defaultModel, inputText := "") {
    global g_DDLProfile
    selection := {Profile: defaultProfile, Model: defaultModel, CustomText: "", UserText: ""}
    
    guiPicker := Gui(, "PromptOpt Configuration")
    guiPicker.SetFont("s10", "Segoe UI")
    
    guiPicker.Add("Text",, "Select Profile (Ctrl+Shift+Wheel to cycle):")
    
    profileList := GetAvailableProfiles()
    g_DDLProfile := guiPicker.Add("DropDownList", "w400 Choose1", profileList)
    g_DDLProfile.ItemsArray := profileList
    
    ; -- Split View: System Prompt (Instructions) vs User Input (Content) --
    
    ; 1. System Prompt
    guiPicker.Add("Text",, "System Prompt / Instructions:")
    editSystem := guiPicker.Add("Edit", "w600 h200 vSystemPrompt -Wrap")
    
    ; 2. User Input
    guiPicker.Add("Text",, "User Input / Selection:")
    editUser := guiPicker.Add("Edit", "w600 h150 vUserInput -Wrap")
    editUser.Value := inputText ; Initialize with captured text
    
    ; Load prompts for preview
    prompts := LoadMetaPromptContents()
    promptMap := Map()
    for p in prompts {
        promptMap[StrLower(p.Name)] := p.Text
    }
    
    UpdatePreview(*) {
        selected := StrLower(g_DDLProfile.Text)
        text := ""
        
        if (promptMap.Has(selected)) {
            text := promptMap[selected]
        } else if (selected != "custom") {
            ; If not custom (and not in map), clear it. 
            text := "" 
        }
        
        ; Update only the System Prompt box
        editSystem.Value := text
    }
    
    g_DDLProfile.OnEvent("Change", UpdatePreview)
    g_DDLProfile.UpdatePreviewFn := UpdatePreview 
    
    try g_DDLProfile.Text := StrTitle(defaultProfile)
    catch {
        try g_DDLProfile.Choose(1)
    }
    
    ; Initial update
    UpdatePreview()
    
    guiPicker.Add("Text",, "Select Model:")
    ddlModel := guiPicker.Add("ComboBox", "w400", ["openai/gpt-4o", "openai/gpt-4o-mini", "anthropic/claude-3.5-sonnet", "openai/gpt-oss-120b"])
    try ddlModel.Text := defaultModel
    
    btnRun := guiPicker.Add("Button", "Default w100", "Run")
    btnRun.OnEvent("Click", (*) => SubmitPicker())
    
    btnCopy := guiPicker.Add("Button", "x+10 w100", "Copy")
    btnCopy.OnEvent("Click", (*) => CopyPreview())
    
    isSubmitted := false
    
    SubmitPicker() {
        selection.Profile := StrLower(g_DDLProfile.Text)
        selection.Model := ddlModel.Text
        selection.CustomText := editSystem.Value
        selection.UserText := editUser.Value
        isSubmitted := true
        guiPicker.Destroy()
    }
    
    CopyPreview() {
        ; Copy composite for debugging/testing
        A_Clipboard := "--- SYSTEM ---`n" . editSystem.Value . "`n`n--- USER ---`n" . editUser.Value
        ToolTip("Copied System+User!")
        SetTimer(() => ToolTip(), -1000)
    }
    
    guiPicker.Show()
    WinWaitClose(guiPicker)
    g_DDLProfile := ""
    return isSubmitted ? selection : false
}

ShowCustomPromptInput(currentInput := "") {
    global g_EditCustom
    
    guiCustom := Gui(, "Custom Instructions")
    guiCustom.SetFont("s10", "Segoe UI")
    
    guiCustom.Add("Text",, "Enter custom instructions (Ctrl+Shift+Wheel to cycle templates):")
    
    ; System Prompt Edit
    g_EditCustom := guiCustom.Add("Edit", "w600 h200 vCustomSystem")
    
    guiCustom.Add("Text",, "Edit User Input:")
    editUser := guiCustom.Add("Edit", "w600 h150 vCustomUser")
    editUser.Value := currentInput
    
    ; Buttons
    btnOK := guiCustom.Add("Button", "Default w100", "OK")
    btnCancel := guiCustom.Add("Button", "x+10 w100", "Cancel")
    
    btnOK.OnEvent("Click", (*) => SubmitCustom())
    btnCancel.OnEvent("Click", (*) => guiCustom.Destroy())
    
    isSubmitted := false
    result := {System: "", User: ""}
    
    SubmitCustom() {
        result.System := g_EditCustom.Value
        result.User := editUser.Value
        isSubmitted := true
        guiCustom.Destroy()
    }
    
    guiCustom.Show()
    WinWaitClose(guiCustom)
    g_EditCustom := ""
    return isSubmitted ? result : false
}

RunPromptOpt(mode, model, profile) {
    ; Check for Insano Mode
    isInsano := EnvGet("PROMPTOPT_INSANO") == "1"
    contextFile := ""
    
    if (isInsano) {
        contextFile := GetActiveFilePath()
        if (contextFile) {
            ToolTip("⚡ Insano Mode: Targeting " . contextFile)
            SetTimer(() => ToolTip(), -2000)
        }
    }

    ; Build PowerShell command
    psScript := SCRIPT_DIR . "\promptopt.ps1"
    cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' . psScript . '"'
    cmd .= ' -Mode "' . mode . '"'
    cmd .= ' -SelectionFile "' . SELECTION_FILE . '"'
    cmd .= ' -OutputFile "' . OUTPUT_FILE . '"'
    cmd .= ' -MetaPromptDir "' . META_PROMPT_DIR . '"'
    cmd .= ' -Model "' . model . '"'
    cmd .= ' -Profile "' . profile . '"'
    cmd .= ' -LogFile "' . LOG_FILE . '"'
    
    if (contextFile) {
        cmd .= ' -ContextFilePath "' . contextFile . '"'
    }
    
    if (profile = "custom") {
        cmd .= ' -CustomPromptFile "' . CUSTOM_PROMPT_FILE . '"'
    }
    
    ; Setup Result GUI
    guiResult := Gui("+Resize", "PromptOpt Result")
    guiResult.SetFont("s10", "Consolas")
    
    ; -WantReturn ensures Enter triggers the Default button (OK)
    ; User can use Ctrl+Enter for new lines if needed
    editResult := guiResult.Add("Edit", "w800 h600 Multi -WantReturn vOutput")
    editResult.Value := "Initializing..." ; Loading indicator
    
    ; Buttons
    btnOK := guiResult.Add("Button", "Default w100", "OK")
    btnCopy := guiResult.Add("Button", "x+10 w100", "Copy")
    
    ; Relace Quick Apply Button
    if (InStr(profile, "relace")) {
        btnApply := guiResult.Add("Button", "x+10 w120", "⚡ Quick Apply")
        btnApply.OnEvent("Click", (*) => RunRelaceApply(editResult.Value))
    }
    
    ; Event Handlers
    btnOK.OnEvent("Click", (*) => SaveAndClose())
    btnCopy.OnEvent("Click", (*) => CopyResult(editResult.Value))
    guiResult.OnEvent("Escape", (*) => ExitScript())
    guiResult.OnEvent("Close", (*) => ExitScript())
    
    guiResult.Show()
    
    ; Start PowerShell
    Run(cmd,, "Hide")
    
    ; Monitor Output
    SetTimer(CheckOutput, 200) ; Increased interval to reduce CPU usage
    lastSize := 0
    completionChecked := false
    noChangeCount := 0
    
    CheckOutput() {
        ; Check if output file exists and has content
        if (FileExist(OUTPUT_FILE)) {
            try {
                currentSize := GetFileSize(OUTPUT_FILE)
                if (currentSize > lastSize) {
                    ; File has grown, read and display content
                    try {
                        content := FileRead(OUTPUT_FILE, "UTF-8")
                        if (content != "") {
                            editResult.Value := content
                            try SendMessage(0x0115, 7, 0, editResult.Hwnd) ; Scroll to bottom
                            lastSize := currentSize
                            noChangeCount := 0
                        }
                    }
                } else if (currentSize > 0 && currentSize = lastSize) {
                    ; File size hasn't changed, count consecutive checks
                    noChangeCount++
                    
                    ; If file hasn't changed for 3 seconds (15 checks * 200ms), assume completion
                    if (noChangeCount >= 15 && !completionChecked) {
                        completionChecked := true
                        try {
                            finalContent := FileRead(OUTPUT_FILE, "UTF-8")
                            if (finalContent != "" && finalContent != "Initializing...") {
                                
                                ; INSANO MODE: Auto-Apply if JSON
                                if (isInsano && IsJson(finalContent)) {
                                    editResult.Value := finalContent
                                    ToolTip("⚡ Insano Mode: Applying...")
                                    RunRelaceApply(finalContent, true) ; true = silent
                                    ExitScript()
                                    return
                                }

                                editResult.Value := finalContent
                                SetTimer(CheckOutput, 0) ; Stop monitoring
                                ToolTip("Complete")
                                SetTimer(() => ToolTip(), -2000)
                                return
                            }
                        }
                    }
                }
            } catch as e {
                ; Log error but continue trying
            }
        }
        
        ; Also check log file for completion signal (backup method)
        if (FileExist(LOG_FILE) && !completionChecked) {
            try {
                logContent := FileRead(LOG_FILE, "UTF-8")
                if (InStr(logContent, "--- PromptOpt done")) {
                    completionChecked := true
                    SetTimer(CheckOutput, 0)
                    try {
                        finalContent := FileRead(OUTPUT_FILE, "UTF-8")
                        if (finalContent != "") {
                            editResult.Value := finalContent
                        }
                    }
                    ToolTip("Complete")
                    SetTimer(() => ToolTip(), -2000)
                }
            } catch {
                ; Continue even if log reading fails
            }
        }
        
        ; Safety timeout: if we've been running for more than 2 minutes without completion,
        ; try to read whatever we have and stop monitoring
        static startTime := A_TickCount
        if (A_TickCount - startTime > 120000 && !completionChecked) {
            completionChecked := true
            SetTimer(CheckOutput, 0)
            try {
                if (FileExist(OUTPUT_FILE)) {
                    content := FileRead(OUTPUT_FILE, "UTF-8")
                    if (content != "" && content != "Initializing...") {
                        editResult.Value := content
                        ToolTip("Timeout - showing partial result")
                        SetTimer(() => ToolTip(), -3000)
                    } else {
                        editResult.Value := "Error: No output received within timeout period."
                        ToolTip("Error - No output")
                        SetTimer(() => ToolTip(), -3000)
                    }
                } else {
                    editResult.Value := "Error: No output file created."
                    ToolTip("Error - No file")
                    SetTimer(() => ToolTip(), -3000)
                }
            } catch {
                editResult.Value := "Error: Failed to read output file."
                ToolTip("Error - Read failed")
                SetTimer(() => ToolTip(), -3000)
            }
        }
    }
    
    SaveAndClose() {
        A_Clipboard := editResult.Value
        ToolTip("Saved to Clipboard")
        SetTimer(() => ToolTip(), -1000)
        Sleep(500)
        ExitScript()
    }
    
    ExitScript() {
        guiResult.Destroy()
        ExitApp()
    }
    
    CopyResult(text) {
        A_Clipboard := text
        ToolTip("Copied!")
        SetTimer(() => ToolTip(), -1000)
    }
    
    RunRelaceApply(jsonContent, silent := false) {
        ; Save to temp file for the python tool
        tempJson := A_Temp . "\relace_payload_" . A_TickCount . ".json"
        try FileDelete(tempJson)
        try FileAppend(jsonContent, tempJson, "UTF-8")
        
        toolScript := PARENT_DIR . "\tools\relace_apply.py"
        
        if (!FileExist(toolScript)) {
            MsgBox("Error: Tool script not found at:`n" . toolScript)
            return
        }
        
        if (silent) {
            ; Silent execution for Insano Mode
            RunWait(A_ComSpec . ' /c python "' . toolScript . '" "' . tempJson . '" > "' . tempJson . '.log" 2>&1',, "Hide")
            
            ; Check log for success/error
            try {
                logContent := FileRead(tempJson . ".log", "UTF-8")
                if (InStr(logContent, "Applied code changes") || InStr(logContent, "Created new file")) {
                    ToolTip("⚡ Insano Apply: Success!")
                    SoundBeep(1000, 150)
                } else {
                    ToolTip("❌ Insano Apply Failed: Check log")
                    SoundBeep(500, 300)
                    ; Show error if failed
                    MsgBox("Insano Apply Failed:`n" . logContent)
                }
                SetTimer(() => ToolTip(), -2000)
            }
        } else {
            ; Execute in a new window so user can see output/errors
            Run(A_ComSpec . ' /c python "' . toolScript . '" "' . tempJson . '" & pause')
        }
    }
}

LoadDotEnv(envFile) {
    if !FileExist(envFile)
        return
    try {
        loop read envFile {
            line := Trim(A_LoopReadLine)
            if (line = "" || SubStr(line, 1, 1) = "#")
                continue
            parts := StrSplit(line, "=", 2)
            if (parts.Length = 2) {
                key := Trim(parts[1])
                val := Trim(parts[2])
                val := RegExReplace(val, '^["\x27]|["\x27]$', "")
                EnvSet(key, val)
            }
        }
    }
}

StrLower(str) {
    return Format("{:L}", str)
}

StrTitle(str) {
    return Format("{:T}", str)
}

GetFileSize(filePath) {
    try {
        f := FileOpen(filePath, "r")
        if (f) {
            size := f.Length
            f.Close()
            return size
        }
    } catch {
        return 0
    }
    return 0
}

; ====================================================================
; INSANO MODE HELPERS
; ====================================================================

GetActiveFilePath() {
    try {
        ; Get active window title
        title := WinGetTitle("A")
        
        ; Check for Notepad
        if (InStr(title, "- Notepad")) {
            ; Extract filename (simplified)
            ; Notepad title format: "*filename.txt - Notepad" or "filename.txt - Notepad"
            filename := RegExReplace(title, " - Notepad.*$", "")
            filename := RegExReplace(filename, "^\*", "") ; Remove unsaved asterisk
            
            ; If it's a full path, return it
            if (InStr(filename, ":\")) {
                return filename
            }
            
            ; If it's just a filename, we might not be able to resolve it easily without more context
            ; But we can return it as a hint
            return filename
        }
        
        ; VS Code (often puts path in title or we can't get it easily without COM/ACC)
        ; For now, focus on Notepad as requested
    }
    return ""
}

IsJson(str) {
    try {
        ; Simple check: starts with { and ends with }
        trimmed := Trim(str)
        if (SubStr(trimmed, 1, 1) == "{" && SubStr(trimmed, -1) == "}") {
            return true
        }
    }
    return false
}
