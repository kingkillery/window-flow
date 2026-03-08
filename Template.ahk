#Requires AutoHotkey v2.0
SendMode("Input")
SetWorkingDir(A_ScriptDir)

; Load core environment and secrets
#Include "core/environment.ahk"
LoadDotEnv()

; Tool paths - Configurable via environment variable with fallback
envRawToPromptDir := EnvGet("RAW_TO_PROMPT_DIR")
if (envRawToPromptDir = "") {
    ; Fallback to hard-coded path if environment variable not set
    global RAW_TO_PROMPT_DIR := "C:\Users\prest\Desktop\Desktop_Projects\May-Dec-2025\raw-to-prompt"
} else {
    global RAW_TO_PROMPT_DIR := envRawToPromptDir
}
global RAW_TO_PROMPT_MAIN := RAW_TO_PROMPT_DIR . "\main.py"

; Default timeouts and delays (in milliseconds)
global CLIPBOARD_TIMEOUT := 1000
global TOOLTIP_DURATION := 1200
global PROMPTOPT_LAUNCH_DELAY := 500

; Default AHK v2 executable paths (used by TryRunWithAHKv2)
global AHK_V2_PATH_A := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
global AHK_V2_PATH_B := "C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey64.exe"

; PK marker automation for quick prompt optimization via clipboard
global PK_TRIGGER_PREFIX := "PK_PROMPT"
global PK_CLIPBOARD_GUARD := false
global PK_PROMPTOPT_BUSY := false
global PK_PROMPT_MENU_BUILT := false
global PK_CLIPBOARD_MONITORING_ENABLED := false
global PK_INSANO_MODE := false ; Insano Mode Toggle
global Clipextra := ""  ; Initialize for clipboard extras

; Only enable clipboard monitoring if explicitly enabled
if (PK_CLIPBOARD_MONITORING_ENABLED) {
    OnClipboardChange(PK_HandleClipboard)
}

; Load hotkey modules
#Include "hotkeys/windows.ahk"
#Include "hotkeys/mouse.ahk"
#Include "hotkeys/media.ahk"

; Load hotstring modules
#Include "hotstrings/api-keys.ahk"
#Include "hotstrings/general.ahk"
#Include "hotstrings/role-task-constraint.ahk"
#Include "hotstrings/templates.ahk"

; ====================================================================
; INSANO MODE TOGGLE (Ctrl+Alt+I)
; ====================================================================

^!i:: {
    global PK_INSANO_MODE
    PK_INSANO_MODE := !PK_INSANO_MODE
    if (PK_INSANO_MODE) {
        ShowTip("🔥 INSANO MODE ON 🔥`nAuto-apply enabled", 1500)
        SoundBeep(1000, 100)
    } else {
        ShowTip("Insano Mode OFF", 1000)
        SoundBeep(500, 100)
    }
}

; ====================================================================
; RAW-TO-PROMPT TOOL INTEGRATION
; ...

; ====================================================================
; HELPER FUNCTIONS (Template-specific)
; ====================================================================

; Ctrl+Alt+F → Formatter Ability Menu
^!f::PK_ShowFormatterMenu()

; Ctrl+Alt+P → PromptOpt
^!p::PromptOpt_Run()

; ====================================================================
; HELPER FUNCTIONS (Template-specific)
; ====================================================================

PK_ShowFormatterMenu() {
    templates := PK_GetFormatterTemplates()
    if (templates.Length = 0) {
        ShowErrorTip("No formatter templates found.")
        return
    }

    fmtGui := Gui(, "Formatter Templates")
    fmtGui.SetFont("s10", "Segoe UI")
    fmtGui.Add("Text",, "Pick a formatter and press Run (dropdown is scrollable):")
    
    names := []
    for t in templates
        names.Push(t.Name)

    dd := fmtGui.Add("DropDownList", "w320 Choose1 vFmtDD", names)
    
    RunSelected(*) {
        idx := dd.Value
        if (idx < 1 || idx > templates.Length)
            return
        fmtGui.Destroy()
        PK_RunFormatterTemplate(templates[idx])
    }
    
    btnRun := fmtGui.Add("Button", "x+10 w80 Default", "Run")
    btnRun.OnEvent("Click", RunSelected)
    btnCancel := fmtGui.Add("Button", "x+5 w80", "Cancel")
    btnCancel.OnEvent("Click", (*) => fmtGui.Destroy())

    fmtGui.Show()
}

PK_GetFormatterTemplates() {
    list := []
    abilityFile := A_ScriptDir . "\promptopt\Ability_Formatter.md"
    if (!FileExist(abilityFile)) {
        return list
    }

    try {
        content := FileRead(abilityFile, "UTF-8")
        sections := StrSplit(content, "## ")
        for section in sections {
            if (A_Index = 1)
                continue
            lines := StrSplit(section, "`n", "`r", 2)
            if (lines.Length >= 2) {
                title := Trim(lines[1])
                body := Trim(lines[2])
                if (title != "" && body != "") {
                    list.Push({Name: title, Text: body})
                }
            }
        }
    }
    return list
}

PK_RunFormatterTemplate(tmpl) {
    customFile := A_Temp . "\promptopt_custom_" . A_TickCount . ".txt"
    try FileDelete(customFile)
    try FileAppend(tmpl.Text, customFile, "UTF-8")
    
    args := " --profile custom --model relace/relace-apply-3 --custom-prompt-file " . customFile
    
    global PK_INSANO_MODE
    if (PK_INSANO_MODE) {
        args .= " --insano"
    }
    
    ShowTip("Formatting with " . tmpl.Name . "...", 1000)
    
    script := A_ScriptDir . "\promptopt\promptopt.ahk"
    if (!TryRunWithAHKv2(script, args)) {
        ShowErrorTip("Failed to launch PromptOpt")
    }
}

PromptOpt_Run() {
    global PK_INSANO_MODE
    
    ; Visual ping to confirm hotkey fired
    if (PK_INSANO_MODE) {
        ShowTip("🔥 PromptOpt (INSANO)...", 800)
    } else {
        ShowTip("PromptOpt: launching...", 800)
    }

    ; Try to run with AHK v2 first
    script := A_ScriptDir . "\promptopt\promptopt.ahk"
    
    ; Add --insano flag if mode is active
    args := ""
    if (PK_INSANO_MODE) {
        args := " --insano"
    }
    
    if (TryRunWithAHKv2(script, args)) {
        return
    }

    ; Fall back to AHK v1 inline processing
    RunPromptOptFallback(A_ScriptDir)
}

; -------------------------------------------------------------------
; Function: PK_CopyEntireFieldText(timeoutMs := "")
; Purpose : Copies entire active control content (Ctrl+A/C) safely
; -------------------------------------------------------------------
PK_CopyEntireFieldText(timeoutMs := "") {
    global PK_CLIPBOARD_GUARD, CLIPBOARD_TIMEOUT
    prevGuard := PK_CLIPBOARD_GUARD
    PK_CLIPBOARD_GUARD := true

    if (timeoutMs = "") {
        timeoutMs := CLIPBOARD_TIMEOUT
    }

    ClipSaved := SaveClipboard()
    A_Clipboard := ""
    Send("^a")
    Sleep(50)
    Send("^c")
    if (!ClipWait(timeoutMs/1000)) {
        RestoreClipboard(ClipSaved)
        PK_CLIPBOARD_GUARD := prevGuard
        return ""
    }
    txt := A_Clipboard
    RestoreClipboard(ClipSaved)
    PK_CLIPBOARD_GUARD := prevGuard
    return txt
}

; -------------------------------------------------------------------
; Menu Handlers
; -------------------------------------------------------------------
PK_MenuOptimizeSelection(*) {
    selection := GetSelectionText(CLIPBOARD_TIMEOUT)
    if (selection = "") {
        ShowErrorTip("PromptOpt: no selection.")
        return
    }
    PK_RunPromptOpt(selection)
}

PK_MenuOptimizeField(*) {
    fieldText := PK_CopyEntireFieldText()
    if (fieldText = "") {
        ShowErrorTip("PromptOpt: field empty.")
        return
    }
    PK_RunPromptOpt(fieldText)
}

PK_MenuOptimizeClipboard(*) {
    if (A_Clipboard = "") {
        ShowErrorTip("PromptOpt: clipboard empty.")
        return
    }
    PK_RunPromptOpt(A_Clipboard)
}

PK_MenuCancel(*) {
    return
}

PK_MenuShowHelp(*) {
    PK_ShowPromptOptHelp()
}

; -------------------------------------------------------------------
; Function: FlattenClipboard()
; Purpose : Copies selected text, flattens it to a single line,
;           and replaces the clipboard content with the result.
; -------------------------------------------------------------------
FlattenClipboard() {
    ClipSaved := SaveClipboard()
    Send("^c")
    if (!ClipWait(0.5)) {
        RestoreClipboard(ClipSaved)
        return
    }
    ; Replace newlines with spaces and collapse multiple spaces
    txt := A_Clipboard
    txt := RegExReplace(txt, "\r\n|\r|\n", " ")
    txt := RegExReplace(txt, "\s{2,}", " ")
    A_Clipboard := Trim(txt)
    RestoreClipboard(ClipSaved)
}

; -------------------------------------------------------------------
; Function: ShowTip(msg, durationMs := 0, x := "", y := "")
; Purpose : Shows a tooltip with optional auto-hide timer
; -------------------------------------------------------------------
ShowTip(msg, durationMs := 0, x := "", y := "")
{
    if (x = "" || y = "")
    {
        MouseGetPos(&mx, &my)
        if (x = "")
        {
            x := mx + 12
        }
        if (y = "")
        {
            y := my + 12
        }
    }
    ToolTip(msg, x, y)
    if (durationMs > 0)
    {
        SetTimer(RemoveToolTip, -durationMs)
    }
}

RemoveToolTip(*)
{
    ToolTip()
}

; -------------------------------------------------------------------
; Function: GetSelectionText(timeoutMs := 0)
; Purpose : Copies selection with a guard and returns the text
; -------------------------------------------------------------------
GetSelectionText(timeoutMs := 0)
{
    global PK_CLIPBOARD_GUARD, CLIPBOARD_TIMEOUT
    prevGuard := PK_CLIPBOARD_GUARD
    PK_CLIPBOARD_GUARD := true
    if (timeoutMs <= 0)
    {
        timeoutMs := CLIPBOARD_TIMEOUT
    }
    ClipSaved := SaveClipboard()
    A_Clipboard := ""
    Send("^c")
    if (!ClipWait(timeoutMs/1000))
    {
        RestoreClipboard(ClipSaved)
        PK_CLIPBOARD_GUARD := prevGuard
        return ""
    }
    txt := A_Clipboard
    RestoreClipboard(ClipSaved)
    PK_CLIPBOARD_GUARD := prevGuard
    return txt
}

; -------------------------------------------------------------------
; Function: WriteUtf8(path, text, overwrite := true)
; Purpose : Writes text to file with UTF-8 encoding (with BOM)
; -------------------------------------------------------------------
WriteUtf8(path, text, overwrite := true) {
    try {
        file := FileOpen(path, overwrite ? "w" : "a", "UTF-8")
        file.Write(text)
        file.Close()
        return true
    } catch {
        ShowErrorTip("Failed to open file for writing: " . path)
        return false
    }
}

; -------------------------------------------------------------------
; Function: EnsureTxtExtension(path)
; Purpose : Ensures file path ends with .txt extension
; -------------------------------------------------------------------
EnsureTxtExtension(path) {
    if (!RegExMatch(path, "\.[^.\\/]+$")) {
        path := path . ".txt"
    }
    return path
}

; -------------------------------------------------------------------
; Function: OpenTempView(text, prefix := "promptopt_view_")
; Purpose : Creates temp file with content and opens in notepad
; -------------------------------------------------------------------
OpenTempView(text, prefix := "promptopt_view_") {
    tmpFile := CreateTempFile(prefix, ".txt")
    WriteUtf8(tmpFile, text)
    Run('notepad.exe "' . tmpFile . '"')
    return tmpFile
}

; -------------------------------------------------------------------
; Function: SendKeySequence(keys)
; Purpose : Sends a key sequence
; -------------------------------------------------------------------
SendKeySequence(keys) {
    Send(keys)
}

; -------------------------------------------------------------------
; Function: RunHidden(exe, params)
; Purpose : Runs a command hidden (no window)
; -------------------------------------------------------------------
RunHidden(exe, params) {
    Run(exe . " " . params,, "Hide")
}

; -------------------------------------------------------------------
; Function: CreateTempFile(prefix := "temp_", extension := ".txt")
; Purpose : Creates a temporary file path
; -------------------------------------------------------------------
CreateTempFile(prefix := "temp_", extension := ".txt") {
    return A_Temp . "\" . prefix . A_TickCount . extension
}

; -------------------------------------------------------------------
; Function: ShowPromptOptWindow(text)
; Purpose : Shows PromptOpt result window with the provided text
; -------------------------------------------------------------------
ShowPromptOptWindow(text) {
    global PromptOptGui

    ; Get current mouse position for window placement
    MouseGetPos(&mouseX, &mouseY)

    ; Calculate window position (ensure it fits on screen)
    windowWidth := 900
    windowHeight := 640  ; Approximate height including buttons
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    ; Position window near mouse, ensuring it stays on screen
    x := mouseX - (windowWidth // 2)  ; Center horizontally on mouse
    y := mouseY + 20  ; Place slightly below mouse cursor

    ; Adjust if window would go off-screen
    if (x < 0)
        x := 0
    if (x + windowWidth > screenWidth)
        x := screenWidth - windowWidth
    if (y < 0)
        y := 0
    if (y + windowHeight > screenHeight)
        y := mouseY - windowHeight - 20  ; Place above mouse instead

    PromptOptGui := Gui("+AlwaysOnTop +Resize", "PromptOpt Result")
    PromptOptGui.PO_Edit := PromptOptGui.Add("Edit", "w900 h560 ReadOnly", text)
    PromptOptGui.Add("Button", "w110", "Save...").OnEvent("Click", PO_SaveSection)
    PromptOptGui.Add("Button", "x+8 w130", "Open in Notepad").OnEvent("Click", PO_OpenSection)
    PromptOptGui.Add("Button", "x+8 w90", "Copy").OnEvent("Click", PO_CopySection)
    PromptOptGui.Add("Button", "x+8 w90", "Close").OnEvent("Click", PO_CloseSection)
    PromptOptGui.Show("x" . x . " y" . y)
}

PO_CopySection(*) {
    global PromptOptGui
    A_Clipboard := PromptOptGui.PO_Edit.Text
    ToolTip("Copied to clipboard.")
    SetTimer(RemoveToolTip, -1200)
}

PO_CloseSection(*) {
    global PromptOptGui
    PromptOptGui.Destroy()
}

PO_SaveSection(*) {
    global PromptOptGui
    savePath := FileSelect("S", A_Desktop, "Save Prompt", "Text Documents (*.txt)")
    if (savePath = "") {
        return
    }
    ; Ensure .txt extension if none provided
    if (!RegExMatch(savePath, "\.[^.\\/]+$")) {
        savePath := EnsureTxtExtension(savePath)
    }
    WriteUtf8(savePath, PromptOptGui.PO_Edit.Text)
    ShowTip("Saved: " . savePath, 1200)
}

PO_OpenSection(*) {
    global PromptOptGui
    tmpView := OpenTempView(PromptOptGui.PO_Edit.Text)
}

; -------------------------------------------------------------------
; Function: BuildPromptOptCommand(scriptDir, tempSel, tempOut, tempLog, mode, model, profile)
; Purpose : Builds PowerShell command string for PromptOpt execution
;           Returns complete command string ready for RunWait
; -------------------------------------------------------------------
BuildPromptOptCommand(scriptDir, tempSel, tempOut, tempLog, mode, model, profile) {
    ps1Path := scriptDir . "\promptopt\promptopt.ps1"
    metaDir := scriptDir . "\meta-prompts"
    
    cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass'
    cmd .= ' -File "' . ps1Path . '"'
    cmd .= ' -Mode "' . mode . '"'
    cmd .= ' -SelectionFile "' . tempSel . '"'
    cmd .= ' -OutputFile "' . tempOut . '"'
    cmd .= ' -MetaPromptDir "' . metaDir . '"'
    cmd .= ' -Model "' . model . '"'
    cmd .= ' -Profile "' . profile . '"'
    cmd .= ' -LogFile "' . tempLog . '"'
    
    return cmd
}

; -------------------------------------------------------------------
; Function: PK_HotstringLaunch()
; Purpose : Handles PK_PROMPT hotstring to run PromptOpt on inline text
; -------------------------------------------------------------------
PK_HotstringLaunch() {
    global PK_TRIGGER_PREFIX, PK_PROMPTOPT_BUSY
    if (PK_PROMPTOPT_BUSY) {
        ShowTip("PromptOpt already running…", 800)
        return
    }

    text := PK_CopyEntireFieldText()
    if (text = "") {
        ShowErrorTip("PK_PROMPT: nothing to optimize.")
        return
    }

    trimmed := Trim(text)
    prefixLen := StrLen(PK_TRIGGER_PREFIX)
    if (SubStr(trimmed, 1, prefixLen) != PK_TRIGGER_PREFIX) {
        ShowErrorTip("PK_PROMPT: prefix not found.")
        return
    }

    prompt := Trim(SubStr(trimmed, prefixLen + 1))
    if (prompt = "") {
        ShowErrorTip("PK_PROMPT: missing prompt content.")
        return
    }

    PK_RunPromptOpt(prompt)
}

; -------------------------------------------------------------------
; Function: PK_HandleQuadQuestionHotstring(endChar)
; Purpose : Handles ???? trigger to optimize entire field
; -------------------------------------------------------------------
PK_HandleQuadQuestionHotstring(endChar) {
    global PK_PROMPTOPT_BUSY
    if (PK_PROMPTOPT_BUSY) {
        ShowTip("PromptOpt already running…", 800)
        return
    }

    prompt := PK_CopyEntireFieldText()
    if (prompt = "") {
        ShowErrorTip("PromptOpt: nothing to optimize.")
        return
    }
    PK_RunPromptOpt(prompt)
}

; -------------------------------------------------------------------
; Function: PK_ShowPromptOptMenu()
; Purpose : Shows PromptOpt context menu for current selection
; -------------------------------------------------------------------
PK_ShowPromptOptMenu() {
    global PK_PROMPT_MENU_BUILT, PKPromptMenu
    if (!PK_PROMPT_MENU_BUILT) {
        PKPromptMenu := Menu()
        PKPromptMenu.Add("Optimize Selection", PK_MenuOptimizeSelection)
        PKPromptMenu.Add("Optimize Entire Field", PK_MenuOptimizeField)
        PKPromptMenu.Add("Optimize Clipboard", PK_MenuOptimizeClipboard)
        PKPromptMenu.Add()
        PKPromptMenu.Add("Help && Documentation", PK_MenuShowHelp)
        PKPromptMenu.Add()
        PKPromptMenu.Add("Cancel", PK_MenuCancel)
        PK_PROMPT_MENU_BUILT := true
    }

    CoordMode("Menu", "Screen")
    MouseGetPos(&mx, &my)
    PKPromptMenu.Show(mx, my)
}

; -------------------------------------------------------------------
; Function: PK_ShowPromptOptHelp()
; Purpose : Shows comprehensive help for PromptOpt features
; -------------------------------------------------------------------
PK_ShowPromptOptHelp() {
    helpText := ""
    helpText .= "PROMPTOPT HELP`n"
    helpText .= "===============`n`n"
    helpText .= "WHAT IS PROMPTOPT?`n"
    helpText .= "AI tool that optimizes your text for better AI responses.`n`n"
    helpText .= "HOW TO USE:`n`n"
    helpText .= "1. DIRECT OPTIMIZATION (Ctrl+Alt+P)`n"
    helpText .= "   - Select any text in any application`n"
    helpText .= "   - Press Ctrl+Alt+P`n"
    helpText .= "   - Choose profile and model`n"
    helpText .= "   - Get optimized prompt in clipboard + result window`n`n"
    helpText .= "2. CONTEXT MENU (Ctrl+Alt+Shift+P or Ctrl+Alt+AppsKey)`n"
    helpText .= "   - Optimize Selection: Optimize currently selected text`n"
    helpText .= "   - Optimize Entire Field: Optimize all text in current field/text area`n"
    helpText .= "   - Optimize Clipboard: Optimize text already copied to clipboard`n`n"
    helpText .= "3. AUTOMATIC MODE (PK_PROMPT prefix)`n"
    helpText .= "   - Type " . Chr(34) . "PK_PROMPT " . Chr(34) . " before your text`n"
    helpText .= "   - Press Ctrl+Alt+Shift+C to toggle monitoring`n"
    helpText .= "   - Copy text with PK_PROMPT prefix -> automatic optimization`n`n"
    helpText .= "4. RIGHT-CLICK CONTEXT MENU`n"
    helpText .= "   - Right-click any file -> PromptOpt menu`n"
    helpText .= "   - Specialized options for .md, .py, .js, .ts, .css, .html files`n`n"
    helpText .= "PROFILES AVAILABLE:`n"
    helpText .= "- Browser/Computer: Web browsing and computer tasks`n"
    helpText .= "- Coding: Programming and development`n"
    helpText .= "- Writing: Text composition and editing`n"
    helpText .= "- RAG: Retrieval-augmented generation`n"
    helpText .= "- General: All-purpose optimization`n`n"
    helpText .= "CUSTOMIZATION:`n"
    helpText .= "- Set API keys: Configure OpenRouter or OpenAI keys`n"
    helpText .= "- Auto-select profiles: Skip profile picker`n"
    helpText .= "- Default models: Per-profile model preferences`n"
    helpText .= "- Streaming: Live preview during optimization`n`n"
    helpText .= "TROUBLESHOOTING:`n"
    helpText .= "- Normal Ctrl+C/V not working? Toggle PK_PROMPT monitoring (Ctrl+Alt+Shift+C)`n"
    helpText .= "- Need to configure API keys? Check environment variables or .env file`n"
    helpText .= "- Issues with context menu? Run installer as Administrator`n`n"
    helpText .= "FILES & LOCATIONS:`n"
    helpText .= "- Main script: promptopt/promptopt.ahk`n"
    helpText .= "- PowerShell bridge: promptopt/promptopt.ps1`n"
    helpText .= "- Python client: promptopt/promptopt.py`n"
    helpText .= "- Meta-prompts: meta-prompts/*.md`n"
    helpText .= "- Config: %AppData%\PromptOpt\config.ini"

    global PromptOptHelpGui
    PromptOptHelpGui := Gui()
    PromptOptHelpGui.SetFont("s10", "Segoe UI")
    PromptOptHelpGui.Add("Edit", "w800 h600 ReadOnly -Wrap vHelpText", helpText)
    PromptOptHelpGui.Add("Button", "Default w80 h30 x720 y620", "OK").OnEvent("Click", PromptOptHelpClose)
    PromptOptHelpGui.Show(, "PromptOpt Help")
}

PromptOptHelpClose(*) {
    global PromptOptHelpGui
    PromptOptHelpGui.Destroy()
}

; -------------------------------------------------------------------
; Function: ShowErrorTip(msg, durationMs := TOOLTIP_DURATION)
; Purpose : Shows an error tooltip
; -------------------------------------------------------------------
ShowErrorTip(msg, durationMs := 0) {
    global TOOLTIP_DURATION
    if (durationMs = 0) {
        durationMs := TOOLTIP_DURATION
    }
    x := A_ScreenWidth - 420
    y := A_ScreenHeight - 100
    ShowTip("ERROR: " . msg, durationMs, x, y)
}

; -------------------------------------------------------------------
; Function: TryRunWithAHKv2(script)
; Purpose : Attempts to run a script with AutoHotkey v2
;           Returns true if launched successfully, false otherwise
; -------------------------------------------------------------------
TryRunWithAHKv2(script, args := "") {
    global AHK_V2_PATH_A, AHK_V2_PATH_B
    ; Check common AHK v2 installation paths
    if FileExist(AHK_V2_PATH_A) {
        Run('"' . AHK_V2_PATH_A . '" "' . script . '"' . args)
        return true
    }
    if FileExist(AHK_V2_PATH_B) {
        Run('"' . AHK_V2_PATH_B . '" "' . script . '"' . args)
        return true
    }
    ; If neither path exists, return false to trigger fallback
    return false
}

; -------------------------------------------------------------------
; Function: RunPromptOptFallback(scriptDir)
; Purpose : Fallback for running PromptOpt when AHK v2 unavailable
; -------------------------------------------------------------------
RunPromptOptFallback(scriptDir) {
    ShowTip("PromptOpt: AHK v2 not found. Attempting fallback...", 2000)

    ; Get selection
    selectedText := GetSelectionText(CLIPBOARD_TIMEOUT)
    if (selectedText = "") {
        ShowErrorTip("No text selected.")
        return
    }

    ClipSaved := SaveClipboard()

    ; Create temp files
    tempSel := CreateTempFile("promptopt_sel_", ".txt")
    tempOut := CreateTempFile("promptopt_out_", ".txt")
    tempLog := CreateTempFile("promptopt_", ".log")
    
    ; Write selection to file
    WriteUtf8(tempSel, selectedText)
    
    ; Get environment variables with defaults
    envMode := EnvGet("PROMPTOPT_MODE")
    if (envMode = "") {
        envMode := "meta"
    }

    envModel := EnvGet("OPENAI_MODEL")
    if (envModel = "") {
        envModel := "openai/gpt-oss-120b"
    }

    envProfile := EnvGet("PROMPTOPT_PROFILE")
    if (envProfile = "") {
        envProfile := "general"
    }

    ; Build PowerShell command using shared function
    cmd := BuildPromptOptCommand(scriptDir, tempSel, tempOut, tempLog, envMode, envModel, envProfile)

    ; Run PowerShell bridge
    RunWait(cmd,, "Hide")

    ; Handle output
    HandlePromptOptOutput(tempOut, ClipSaved)
}

; -------------------------------------------------------------------
; Function: HandlePromptOptOutput(tempOut, ClipSaved)
; Purpose : Reads PromptOpt output and shows result
; -------------------------------------------------------------------
HandlePromptOptOutput(tempOut, ClipSaved) {
    if !FileExist(tempOut) {
        ShowErrorTip("PromptOpt did not produce output file.")
        RestoreClipboard(ClipSaved)
        return
    }
    outText := ""
    try {
        outText := FileRead(tempOut, "UTF-8")
    } catch {
        ShowErrorTip("Failed to read output file.")
        RestoreClipboard(ClipSaved)
        return
    }
    ; Copy to clipboard by default (per spec) and show the window
    A_Clipboard := outText
    ShowTip("Prompt copied to clipboard.", TOOLTIP_DURATION)
    ShowPromptOptWindow(outText)
}

; ====================================================================
; PK PROMPT AUTOMATION (Clipboard-triggered PromptOpt)
; ====================================================================

; -------------------------------------------------------------------
; Function: PK_HandleClipboard(Type)
; Purpose : Monitors clipboard for PK_PROMPT prefix and triggers optimization
; -------------------------------------------------------------------
PK_HandleClipboard(Type) {
    global PK_PROMPTOPT_BUSY, PK_CLIPBOARD_GUARD, PK_TRIGGER_PREFIX
    ; Skip if we're already processing or guarding against recursion
    if (PK_PROMPTOPT_BUSY || PK_CLIPBOARD_GUARD) {
        return
    }
    
    ; Guard against our own clipboard changes during processing
    PK_CLIPBOARD_GUARD := true
    
    ; Get current clipboard content
    text := A_Clipboard
    
    ; Trim whitespace for reliable matching
    trimmed := Trim(text)
    
    ; Check for PK_PROMPT prefix
    prefixLen := StrLen(PK_TRIGGER_PREFIX)
    if (SubStr(trimmed, 1, prefixLen) != PK_TRIGGER_PREFIX) {
        PK_CLIPBOARD_GUARD := false
        return
    }
    
    ; Extract the actual prompt after PK_PROMPT
    cleanPrompt := Trim(SubStr(trimmed, prefixLen + 1))
    
    ; Skip if there's no actual prompt content
    if (cleanPrompt = "") {
        PK_CLIPBOARD_GUARD := false
        return
    }
    
    ; Run PromptOpt on the extracted prompt
    PK_RunPromptOpt(cleanPrompt)
    
    ; Clear guard after processing
    PK_CLIPBOARD_GUARD := false
}

; -------------------------------------------------------------------
; Function: PK_RunPromptOpt(promptText)
; Purpose : Executes PromptOpt workflow on the provided text and pastes result
; -------------------------------------------------------------------
PK_RunPromptOpt(promptText) {
    global PK_PROMPTOPT_BUSY
    ; Mark as busy to prevent multiple simultaneous runs
    PK_PROMPTOPT_BUSY := true
    
    ; Show processing indicator
    ShowTip("PK_PROMPT: optimizing...", 1000)
    
    ; Save current clipboard to restore later if needed
    ClipSaved := SaveClipboard()
    
    ; Create temporary files for PromptOpt processing
    tempSel := CreateTempFile("pk_promptopt_sel_", ".txt")
    tempOut := CreateTempFile("pk_promptopt_out_", ".txt")
    tempLog := CreateTempFile("pk_promptopt_", ".log")
    
    ; Write the prompt to temp selection file
    if (!WriteUtf8(tempSel, promptText)) {
        ShowErrorTip("PK_PROMPT: failed to write temp file.")
        RestoreClipboard(ClipSaved)
        PK_PROMPTOPT_BUSY := false
        return
    }
    
    ; Try AHK v2 orchestrator first (same as hotkey workflow)
    script := A_ScriptDir . "\promptopt\promptopt.ahk"
    if (TryRunWithAHKv2(script)) {
        ; Wait for processing and handle result
        PK_WaitAndProcessResult(tempOut, tempLog, ClipSaved, tempSel)
    } else {
        ; Fallback to direct PowerShell processing
        PK_RunFallback(tempSel, tempOut, tempLog, ClipSaved)
    }
    
    ; Cleanup and reset busy state
    PK_PROMPTOPT_BUSY := false
}

; -------------------------------------------------------------------
; Function: PK_WaitAndProcessResult(tempOut, tempLog, ClipSaved, tempSel := "")
; Purpose : Monitors for PromptOpt completion and pastes optimized result
; -------------------------------------------------------------------
PK_WaitAndProcessResult(tempOut, tempLog, ClipSaved, tempSel := "") {
    ; Wait up to 30 seconds for output file to appear
    maxWait := 30000
    waitInterval := 500
    elapsed := 0
    
    while (elapsed < maxWait) {
        if (FileExist(tempOut)) {
            break
        }
        Sleep(waitInterval)
        elapsed += waitInterval
    }
    
    ; Process the result
    PK_ProcessResult(tempOut, tempLog, ClipSaved, tempSel)
}

; -------------------------------------------------------------------
; Function: PK_RunFallback(tempSel, tempOut, tempLog, ClipSaved)
; Purpose : Direct PowerShell fallback when AHK v2 unavailable
; -------------------------------------------------------------------
PK_RunFallback(tempSel, tempOut, tempLog, ClipSaved) {
    ; Get environment variables with same defaults as RunPromptOptFallback
    envMode := EnvGet("PROMPTOPT_MODE")
    if (envMode = "") {
        envMode := "meta"
    }

    envModel := EnvGet("OPENAI_MODEL")
    if (envModel = "") {
        envModel := "openai/gpt-oss-120b"
    }

    envProfile := EnvGet("PROMPTOPT_PROFILE")
    if (envProfile = "") {
        envProfile := "general"
    }

    ; Build PowerShell command using shared function
    cmd := BuildPromptOptCommand(A_ScriptDir, tempSel, tempOut, tempLog, envMode, envModel, envProfile)
    
    ; Run and wait for completion
    RunWait(cmd,, "Hide")
    
    ; Process result
    PK_ProcessResult(tempOut, tempLog, ClipSaved, tempSel)
}

; -------------------------------------------------------------------
; Function: PK_ProcessResult(tempOut, tempLog, ClipSaved, tempSel := "")
; Purpose : Handles PromptOpt output and pastes optimized prompt
; -------------------------------------------------------------------
PK_ProcessResult(tempOut, tempLog, ClipSaved, tempSel := "") {
    if (!FileExist(tempOut)) {
        ShowErrorTip("PK_PROMPT: no output generated.")
        RestoreClipboard(ClipSaved)
        return
    }
    
    ; Read the optimized prompt
    optimizedPrompt := ""
    try {
        optimizedPrompt := FileRead(tempOut, "UTF-8")
    } catch {
        ShowErrorTip("PK_PROMPT: failed to read output.")
        RestoreClipboard(ClipSaved)
        return
    }
    
    if (optimizedPrompt = "") {
        ShowErrorTip("PK_PROMPT: empty result.")
        RestoreClipboard(ClipSaved)
        return
    }
    
    ; Paste the optimized prompt at current cursor position
    SendHotstringText(optimizedPrompt)
    
    ; Show success indicator
    ShowTip("PK_PROMPT: optimized and pasted.", 1200)
    
    ; Restore original clipboard
    RestoreClipboard(ClipSaved)
    
    ; Cleanup temp files
    try FileDelete(tempOut)
    try FileDelete(tempLog)
    if (tempSel != "") {
        try FileDelete(tempSel)
    }
}

; ====================================================================
; MOUSE HOTKEYS
; ====================================================================

; Alt+RButton → Copy (Ctrl+C)
!RButton::Send("^c")

; Alt+LButton → Paste (Ctrl+V)
!LButton::Send("^v")

; ====================================================================
; KEYBOARD SAFEGUARDS
; ====================================================================

; Ensure Enter key works normally (override any potential conflicts)
Enter::Send("{Enter}")

; ====================================================================
; END OF TEMPLATE.AHK
; ====================================================================
