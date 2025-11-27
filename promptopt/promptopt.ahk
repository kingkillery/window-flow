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
global g_DDLFormatter := ""
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

; Override Custom Prompt File if provided
if (args.Has("custom-prompt-file")) {
    CUSTOM_PROMPT_FILE := args["custom-prompt-file"]
}

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
    
    ; Update Insano flag based on picker selection
    if (selected.HasOwnProp("IsInsano")) {
        args["insano"] := selected.IsInsano
    }
}

; Custom Profile Handling
if (profile = "custom") {
    ; Check if we already have content in CUSTOM_PROMPT_FILE (e.g. passed via arg)
    hasPredefinedCustom := false
    try {
        if (FileGetSize(CUSTOM_PROMPT_FILE) > 0) {
            hasPredefinedCustom := true
        }
    }

    if (!IsSet(pickerUsed) && !hasPredefinedCustom) {
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
isInsano := args.Has("insano") || (EnvGet("PROMPTOPT_INSANO") == "1")
isPrecise := args.Has("precise") || (EnvGet("PROMPTOPT_PRECISE") == "1")
if (selected && selected.HasOwnProp("IsPrecise")) {
    isPrecise := selected.IsPrecise
}
; Get Agent Mode flag from selection
isAgentMode := selected && selected.HasOwnProp("IsAgentMode") ? selected.IsAgentMode : false
RunPromptOpt(mode, model, profile, isInsano, isPrecise, isAgentMode)


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
        currentText := GetSelectedControlText(g_DDLProfile)
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

GetSelectedControlText(ctrl) {
    try {
        txt := ctrl.Text
        if (txt != "")
            return txt
    }
    try {
        idx := ctrl.Value
        if (HasProp(ctrl, "ItemsArray") && idx >= 1 && idx <= ctrl.ItemsArray.Length) {
            return ctrl.ItemsArray[idx]
        }
    }
    return ""
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
    profiles := ["(None)"]  ; Allow blank/no meta-prompt

    metaFound := false
    if (DirExist(META_PROMPT_DIR)) {
        Loop Files, META_PROMPT_DIR . "\Meta_Prompt.*.md" {
            if (RegExMatch(A_LoopFileName, "i)Meta_Prompt\.([^.]+)\.md", &match)) {
                profileName := match[1]
                if (profileName != "md") {
                    profiles.Push(StrTitle(profileName))
                    metaFound := true
                }
            }
        }
    }
    if (!metaFound) {
        profiles := ["(None)", "Browser", "Coding", "Writing", "RAG", "General"]
    }
    profiles.Push("Custom")
    return profiles
}

GetAvailableFormatters() {
    formatters := ["(None)"]  ; Allow blank/no formatter
    formatterTemplates := LoadFormatterTemplates()
    for fmt in formatterTemplates {
        ; Strip "Formatter: " prefix if present for cleaner display
        name := RegExReplace(fmt.Name, "^Formatter:\s*", "")
        formatters.Push(name)
    }
    formatters.Push("Custom")
    return formatters
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

                    prompts.Push({Name: StrLower(name), Text: Trim(match[1])})
                } else {
                    ; No META_PROMPT anchor, use file content directly
                    name := A_LoopFileName
                    name := StrReplace(name, "Meta_Prompt.", "")
                    name := StrReplace(name, ".md", "")
                    name := StrReplace(name, "_", " ")
                    name := StrTitle(name)

                    prompts.Push({Name: StrLower(name), Text: Trim(content)})
                }
            }
        }
    }

    return prompts
}

LoadFormatterContents() {
    formatters := []
    formatterTemplates := LoadFormatterTemplates()
    for fmt in formatterTemplates {
        ; Strip "Formatter: " prefix for map key
        name := RegExReplace(fmt.Name, "^Formatter:\s*", "")
        formatters.Push({Name: StrLower(name), Text: fmt.Text})
    }
    return formatters
}

LoadFormatterTemplates() {
    formatterPrompts := []
    formatterFile := SCRIPT_DIR . "\Ability_Formatter.md"
    if (!FileExist(formatterFile)) {
        return formatterPrompts
    }

    try {
        content := FileRead(formatterFile, "UTF-8")
        sections := StrSplit(content, "## ")
        
        for section in sections {
            if (A_Index == 1)
                continue
            
            lines := StrSplit(section, "`n", "`r", 2)
            if (lines.Length >= 2) {
                title := Trim(lines[1])
                body := Trim(lines[2])
                
                if (title != "" && body != "") {
                    formatterPrompts.Push({Name: "Formatter: " . title, Text: body})
                }
            }
        }
    } catch {
        ; ignore formatter loading errors to avoid breaking picker
    }
    return formatterPrompts
}

ShowProfilePicker(defaultProfile, defaultModel, inputText := "") {
    global g_DDLProfile, g_DDLFormatter
    selection := {Profile: defaultProfile, Model: defaultModel, CustomText: "", UserText: ""}

    ; ====================================================================
    ; ENHANCED UI - PromptOpt Dashboard
    ; ====================================================================

    guiPicker := Gui("+Resize", "PromptOpt")
    guiPicker.BackColor := "1a1a2e"
    guiPicker.SetFont("s10 cFFFFFF", "Segoe UI")

    ; -- Header with title and status --
    guiPicker.SetFont("s14 c00FFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x20 y10 w700 Center", "PromptOpt Dashboard")
    guiPicker.SetFont("s8 c808080", "Segoe UI")
    guiPicker.Add("Text", "x20 y35 w700 Center vStatusText", "Select a meta-prompt and/or formatter, then customize below")

    ; ====================================================================
    ; LEFT PANEL - Meta-Prompt Selection
    ; ====================================================================
    guiPicker.SetFont("s10 cFFFFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x20 y65 Section", "Meta-Prompt")
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    guiPicker.Add("Text", "x20 y82", "Optimization strategy for your prompt")

    guiPicker.SetFont("s10 cFFFFFF", "Segoe UI")
    profileList := GetAvailableProfiles()
    g_DDLProfile := guiPicker.Add("ListBox", "x20 y100 w220 r12 vDDLProfile Background2d2d44", profileList)
    g_DDLProfile.ItemsArray := profileList

    ; Quick filter for meta-prompts
    guiPicker.SetFont("s8 c808080", "Segoe UI")
    guiPicker.Add("Text", "x20 y+5", "Type to filter...")
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    editMetaFilter := guiPicker.Add("Edit", "x20 y+2 w220 h24 Background2d2d44 vMetaFilter")

    ; ====================================================================
    ; MIDDLE PANEL - Formatter Selection (Categorized)
    ; ====================================================================
    guiPicker.SetFont("s10 cFFFFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x260 y65", "Formatter")
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    guiPicker.Add("Text", "x260 y82", "Output structure and format")

    guiPicker.SetFont("s10 cFFFFFF", "Segoe UI")
    formatterList := GetAvailableFormatters()
    g_DDLFormatter := guiPicker.Add("ListBox", "x260 y100 w220 r12 vDDLFormatter Background2d2d44", formatterList)
    g_DDLFormatter.ItemsArray := formatterList

    ; Quick filter for formatters
    guiPicker.SetFont("s8 c808080", "Segoe UI")
    guiPicker.Add("Text", "x260 y+5", "Type to filter...")
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    editFmtFilter := guiPicker.Add("Edit", "x260 y+2 w220 h24 Background2d2d44 vFmtFilter")

    ; ====================================================================
    ; RIGHT PANEL - Quick Actions & Options
    ; ====================================================================
    guiPicker.SetFont("s10 cFFFFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x500 y65", "Options")

    ; Model Selection
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    guiPicker.Add("Text", "x500 y90", "Model:")
    ddlModel := guiPicker.Add("ComboBox", "x500 y108 w220 Background2d2d44", [
        "openai/gpt-4o",
        "openai/gpt-4o-mini",
        "anthropic/claude-sonnet-4-20250514",
        "anthropic/claude-3.5-sonnet",
        "google/gemini-2.0-flash-001",
        "openai/gpt-oss-120b"
    ])
    try ddlModel.Text := defaultModel

    ; ====================================================================
    ; OUTPUT STEERING CONTROLS
    ; ====================================================================

    ; Audience Level
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    guiPicker.Add("Text", "x500 y135", "Audience:")
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    ddlAudience := guiPicker.Add("DropDownList", "x560 y132 w160 Background2d2d44 vAudience Choose1", [
        "(Auto)",
        "Technical",
        "Non-Technical",
        "Executive",
        "Developer",
        "End User"
    ])

    ; Length Control
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    guiPicker.Add("Text", "x500 y162", "Length:")
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    ddlLength := guiPicker.Add("DropDownList", "x560 y159 w160 Background2d2d44 vLength Choose1", [
        "(Auto)",
        "Ultra Concise",
        "Concise",
        "Normal",
        "Detailed",
        "Comprehensive"
    ])

    ; Tone
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    guiPicker.Add("Text", "x500 y189", "Tone:")
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    ddlTone := guiPicker.Add("DropDownList", "x560 y186 w160 Background2d2d44 vTone Choose1", [
        "(Auto)",
        "Formal",
        "Professional",
        "Neutral",
        "Friendly",
        "Casual",
        "Direct"
    ])

    ; Mode Toggles
    guiPicker.SetFont("s9 cFFFFFF", "Segoe UI")
    global PK_INSANO_MODE
    isInsanoDefault := (EnvGet("PROMPTOPT_INSANO") == "1") || (IsSet(PK_INSANO_MODE) && PK_INSANO_MODE)
    chkInsano := guiPicker.Add("Checkbox", "x500 y218 Checked" . isInsanoDefault, "Insano Mode")

    isPreciseDefault := (EnvGet("PROMPTOPT_PRECISE") == "1")
    chkPrecise := guiPicker.Add("Checkbox", "x620 y218 Checked" . isPreciseDefault, "Precise Edit")

    isAgentDefault := (EnvGet("PROMPTOPT_AGENT_MODE") == "1")
    chkAgentMode := guiPicker.Add("Checkbox", "x500 y241 Checked" . isAgentDefault, "Agent Mode (4-stage GPT-5.1)")

    ; Character/token count display
    guiPicker.SetFont("s8 c888888", "Segoe UI")
    txtCharCount := guiPicker.Add("Text", "x500 y265 w220 vCharCount", "System: 0 chars | User: 0 chars")

    ; Keyboard shortcuts hint
    guiPicker.SetFont("s8 c666666", "Segoe UI")
    guiPicker.Add("Text", "x500 y283", "Enter=Run | Ctrl+Shift+Wheel=Cycle")

    ; ====================================================================
    ; BOTTOM SECTION - Editable Prompts
    ; ====================================================================
    guiPicker.SetFont("s10 cFFFFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x20 y295", "System Prompt")
    guiPicker.SetFont("s8 c00FF88", "Segoe UI")
    guiPicker.Add("Text", "x140 y297", "(editable)")

    guiPicker.SetFont("s9 cFFFFFF", "Consolas")
    editSystem := guiPicker.Add("Edit", "x20 y315 w700 h140 vSystemPrompt Background1e1e2e -Wrap")

    guiPicker.SetFont("s10 cFFFFFF w700", "Segoe UI")
    guiPicker.Add("Text", "x20 y465", "User Input")
    guiPicker.SetFont("s8 cFFAA00", "Segoe UI")
    guiPicker.Add("Text", "x100 y467", "(your selected text)")

    guiPicker.SetFont("s9 cWhite", "Consolas")
    editUser := guiPicker.Add("Edit", "x20 y485 w700 h100 vUserInput Background1e1e2e cWhite -Wrap")
    editUser.Value := inputText

    ; ====================================================================
    ; ACTION BUTTONS
    ; ====================================================================
    guiPicker.SetFont("s11 cWhite Bold", "Segoe UI")
    btnRun := guiPicker.Add("Button", "x20 y600 w120 h35 Default", "Run")
    btnRun.Opt("+Background00aa55")

    guiPicker.SetFont("s10 cWhite", "Segoe UI")
    btnCopy := guiPicker.Add("Button", "x150 y600 w100 h35", "Copy All")
    btnClear := guiPicker.Add("Button", "x260 y600 w100 h35", "Clear")
    btnSwap := guiPicker.Add("Button", "x370 y600 w100 h35", "Swap")

    ; ====================================================================
    ; DATA & EVENT HANDLERS
    ; ====================================================================

    ; Load prompts and formatters for preview
    metaPrompts := LoadMetaPromptContents()
    metaMap := Map()
    for p in metaPrompts {
        metaMap[p.Name] := p.Text
    }

    formatters := LoadFormatterContents()
    formatterMap := Map()
    for f in formatters {
        formatterMap[f.Name] := f.Text
    }

    ; Store original lists for filtering
    originalMetaList := profileList.Clone()
    originalFmtList := formatterList.Clone()

    UpdatePreview(*) {
        selectedMeta := StrLower(GetSelectedControlText(g_DDLProfile))
        selectedFormatter := StrLower(GetSelectedControlText(g_DDLFormatter))

        metaText := ""
        formatterText := ""

        ; Get meta-prompt text (if not "(none)" or "custom")
        if (selectedMeta != "(none)" && selectedMeta != "custom") {
            if (metaMap.Has(selectedMeta)) {
                metaText := metaMap[selectedMeta]
            }
        }

        ; Get formatter text (if not "(none)" or "custom")
        if (selectedFormatter != "(none)" && selectedFormatter != "custom") {
            if (formatterMap.Has(selectedFormatter)) {
                formatterText := formatterMap[selectedFormatter]
            }
        }

        ; Build steering instructions from dropdowns
        steeringParts := []

        audience := ddlAudience.Text
        if (audience != "(Auto)") {
            steeringParts.Push("**Audience:** " . audience . " - tailor language, depth, and examples appropriately.")
        }

        length := ddlLength.Text
        if (length != "(Auto)") {
            lengthGuide := ""
            switch length {
                case "Ultra Concise": lengthGuide := "Absolute minimum words. Strip everything non-essential. Target <100 words."
                case "Concise": lengthGuide := "Brief and focused. No fluff. Target 100-300 words."
                case "Normal": lengthGuide := "Balanced coverage. Include key details. Target 300-600 words."
                case "Detailed": lengthGuide := "Thorough explanation with examples. Target 600-1200 words."
                case "Comprehensive": lengthGuide := "Complete coverage. Include context, examples, edge cases. No word limit."
            }
            steeringParts.Push("**Length:** " . length . " - " . lengthGuide)
        }

        tone := ddlTone.Text
        if (tone != "(Auto)") {
            toneGuide := ""
            switch tone {
                case "Formal": toneGuide := "Professional, structured, third-person where appropriate."
                case "Professional": toneGuide := "Clear and businesslike, but approachable."
                case "Neutral": toneGuide := "Balanced, objective, no strong voice."
                case "Friendly": toneGuide := "Warm and helpful, use 'you' and conversational language."
                case "Casual": toneGuide := "Relaxed, conversational, contractions OK."
                case "Direct": toneGuide := "Straight to the point. No hedging or qualifiers."
            }
            steeringParts.Push("**Tone:** " . tone . " - " . toneGuide)
        }

        steeringText := ""
        if (steeringParts.Length > 0) {
            steeringText := "`n`n---`n`n**Output Guidelines:**`n" . ArrayJoin(steeringParts, "`n")
        }

        ; Combine: meta-prompt first, then formatter, then steering
        combined := ""
        if (metaText != "") {
            combined := metaText
        }
        if (formatterText != "") {
            if (combined != "") {
                combined .= "`n`n---`n`n**Output Format:**`n" . formatterText
            } else {
                combined := formatterText
            }
        }
        if (steeringText != "") {
            combined .= steeringText
        }

        ; Update the System Prompt box
        editSystem.Value := combined

        ; Update character count
        UpdateCharCount()
    }

    ArrayJoin(arr, sep) {
        result := ""
        for i, item in arr {
            if (i > 1)
                result .= sep
            result .= item
        }
        return result
    }

    UpdateCharCount(*) {
        sysLen := StrLen(editSystem.Value)
        userLen := StrLen(editUser.Value)
        ; Rough token estimate (4 chars per token average)
        sysTok := Round(sysLen / 4)
        userTok := Round(userLen / 4)
        txtCharCount.Value := "System: " . sysLen . " chars (~" . sysTok . " tok) | User: " . userLen . " chars (~" . userTok . " tok)"
    }

    FilterList(edit, listbox, originalList, *) {
        filterText := StrLower(edit.Value)
        if (filterText = "") {
            ; Restore original list
            listbox.Delete()
            listbox.Add(originalList)
            listbox.Choose(1)
        } else {
            ; Filter and update
            filtered := []
            for item in originalList {
                if (InStr(StrLower(item), filterText)) {
                    filtered.Push(item)
                }
            }
            listbox.Delete()
            if (filtered.Length > 0) {
                listbox.Add(filtered)
                listbox.Choose(1)
            }
        }
        UpdatePreview()
    }

    ; Event bindings
    g_DDLProfile.OnEvent("Change", UpdatePreview)
    g_DDLFormatter.OnEvent("Change", UpdatePreview)
    g_DDLProfile.UpdatePreviewFn := UpdatePreview

    ; Steering dropdown events
    ddlAudience.OnEvent("Change", UpdatePreview)
    ddlLength.OnEvent("Change", UpdatePreview)
    ddlTone.OnEvent("Change", UpdatePreview)

    editMetaFilter.OnEvent("Change", FilterList.Bind(editMetaFilter, g_DDLProfile, originalMetaList))
    editFmtFilter.OnEvent("Change", FilterList.Bind(editFmtFilter, g_DDLFormatter, originalFmtList))

    editSystem.OnEvent("Change", UpdateCharCount)
    editUser.OnEvent("Change", UpdateCharCount)

    btnRun.OnEvent("Click", (*) => SubmitPicker())
    btnCopy.OnEvent("Click", (*) => CopyPreview())
    btnClear.OnEvent("Click", (*) => ClearAll())
    btnSwap.OnEvent("Click", (*) => SwapPrompts())

    ; Set default selections
    try {
        defaultChosen := false
        for idx, name in profileList {
            if (StrLower(name) = StrLower(StrTitle(defaultProfile))) {
                g_DDLProfile.Choose(idx)
                defaultChosen := true
                break
            }
        }
        if (!defaultChosen)
            g_DDLProfile.Choose(1)
    }

    ; Default formatter to "(None)"
    g_DDLFormatter.Choose(1)

    ; Initial update
    UpdatePreview()

    isSubmitted := false

    SubmitPicker() {
        selection.Profile := StrLower(GetSelectedControlText(g_DDLProfile))
        selection.Formatter := StrLower(GetSelectedControlText(g_DDLFormatter))
        selection.Model := ddlModel.Text
        selection.CustomText := editSystem.Value
        selection.UserText := editUser.Value
        selection.IsInsano := chkInsano.Value
        selection.IsPrecise := chkPrecise.Value
        selection.IsAgentMode := chkAgentMode.Value
        isSubmitted := true
        guiPicker.Destroy()
    }

    CopyPreview() {
        A_Clipboard := "--- SYSTEM ---`n" . editSystem.Value . "`n`n--- USER ---`n" . editUser.Value
        ToolTip("Copied to clipboard!")
        SetTimer(() => ToolTip(), -1500)
    }

    ClearAll() {
        editSystem.Value := ""
        editUser.Value := ""
        g_DDLProfile.Choose(1)
        g_DDLFormatter.Choose(1)
        ddlAudience.Choose(1)
        ddlLength.Choose(1)
        ddlTone.Choose(1)
        editMetaFilter.Value := ""
        editFmtFilter.Value := ""
        ; Restore lists
        g_DDLProfile.Delete()
        g_DDLProfile.Add(originalMetaList)
        g_DDLProfile.Choose(1)
        g_DDLFormatter.Delete()
        g_DDLFormatter.Add(originalFmtList)
        g_DDLFormatter.Choose(1)
        UpdateCharCount()
    }

    SwapPrompts() {
        temp := editSystem.Value
        editSystem.Value := editUser.Value
        editUser.Value := temp
        UpdateCharCount()
    }

    guiPicker.OnEvent("Close", (*) => guiPicker.Destroy())
    guiPicker.OnEvent("Escape", (*) => guiPicker.Destroy())

    guiPicker.Show("w740 h650")
    WinWaitClose(guiPicker)
    g_DDLProfile := ""
    g_DDLFormatter := ""
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

RunPromptOpt(mode, model, profile, isInsano := false, isPrecise := false, isAgentMode := false) {
    ; Check for Insano Mode
    ; isInsano passed from args/env
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

    if (isPrecise) {
        cmd .= ' -PreciseEdit'
    }

    if (isAgentMode) {
        cmd .= ' -AgentMode'
    }
    
    ; Setup Result GUI
    guiTitle := isAgentMode ? "PromptOpt - Agent Mode (4-Stage Pipeline)" : "PromptOpt Result"
    guiResult := Gui("+Resize", guiTitle)
    guiResult.SetFont("s10", "Consolas")

    ; -WantReturn ensures Enter triggers the Default button (OK)
    ; User can use Ctrl+Enter for new lines if needed
    editResult := guiResult.Add("Edit", "w800 h600 Multi -WantReturn vOutput")
    editResult.Value := isAgentMode ? "Agent Mode: Starting 4-stage optimization..." : "Initializing..."
    
    ; Buttons
    btnOK := guiResult.Add("Button", "Default w100", "OK")
    btnCopy := guiResult.Add("Button", "x+10 w100", "Copy All")

    ; Agent Mode: Add "Copy Final Only" button
    if (isAgentMode) {
        btnCopyFinal := guiResult.Add("Button", "x+10 w120", "Copy Final Only")
        btnCopyFinal.OnEvent("Click", (*) => CopyFinalOnly(editResult.Value))
    }

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
        ; For Agent Mode, save only the final prompt to clipboard
        if (isAgentMode) {
            finalText := ExtractFinalPrompt(editResult.Value)
            if (finalText != "") {
                A_Clipboard := finalText
                ToolTip("Final prompt saved to Clipboard")
            } else {
                A_Clipboard := editResult.Value
                ToolTip("Saved to Clipboard (full output)")
            }
        } else {
            A_Clipboard := editResult.Value
            ToolTip("Saved to Clipboard")
        }
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

    CopyFinalOnly(text) {
        finalText := ExtractFinalPrompt(text)
        if (finalText != "") {
            A_Clipboard := finalText
            ToolTip("Final prompt copied!")
        } else {
            A_Clipboard := text
            ToolTip("No final marker found - copied all")
        }
        SetTimer(() => ToolTip(), -1000)
    }

    ExtractFinalPrompt(text) {
        ; Extract content after ---FINAL--- marker
        if (InStr(text, "---FINAL---")) {
            parts := StrSplit(text, "---FINAL---", "", 2)
            if (parts.Length >= 2) {
                return Trim(parts[2])
            }
        }
        return ""
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
