; test_enhanced_result_window.ahk - Test the enhanced PromptOpt result window
#Requires AutoHotkey v2.0
#SingleInstance Force

; Test data
testPrompt := "
This is a test prompt to demonstrate the enhanced PromptOpt result window.

Features:
- Text statistics display
- Better visual styling
- Enhanced buttons with icons
- Auto-select text for easy copying
- Helpful tooltips
- Sound feedback

The window should show character count, line count, and word count in the title bar.
"

; Include the functions from the main script (simplified versions)
ShowResultWindow(text) {
    ; Calculate text statistics
    charCount := StrLen(text)
    lineCount := StrSplit(text, "`n").Length
    wordCount := StrSplit(StrReplace(text, "`n", " "), " ").Length

    resultGui := Gui("+Resize +MinSize +AlwaysOnTop", "Enhanced PromptOpt Result - " charCount " chars, " lineCount " lines")
    resultGui.SetFont("s10", "Segoe UI")

    ; Add info panel
    resultGui.Add("Text", "w900 h25 +Background0xF0F0F0", "📝 Test Prompt: " charCount " characters | " lineCount " lines | " wordCount " words")

    ; Add text area with better styling
    resultEdit := resultGui.Add("Edit", "w900 h520 ReadOnly -Wrap -WantReturn +Background0xFFFFFF")
    resultEdit.Value := text
    resultEdit.SetFont("s9 Consolas")

    ; Add button panel
    resultGui.Add("Text", "w900", "")

    ; Create button row with better spacing
    btnCopyAll := resultGui.Add("Button", "w100 h30", "📋 Copy All")
    btnCopyAll.OnEvent("Click", (*) => CopyToClipboard(text))

    btnSave := resultGui.Add("Button", "x+12 w100 h30", "💾 Save…")
    btnSave.OnEvent("Click", (*) => {
        try {
            path := FileSelect("S16", A_Desktop, "Save Test Prompt", "Text Documents (*.txt)")
            if (path = "")
                return
            if !RegExMatch(path, "\.[^.\\/]+$")
                path := path ".txt"
            try FileDelete(path)
            FileAppend(text, path, "UTF-8")
            ShowInfo("Saved: " PathShort(path))
        } catch {
            ShowError("Failed to save file.")
        }
    })

    btnOpen := resultGui.Add("Button", "x+12 w120 h30", "📝 Open in Notepad")
    btnOpen.OnEvent("Click", (*) => {
        try {
            tmpFile := A_Temp "\\test_promptopt_view_" A_TickCount ".txt"
            try FileDelete(tmpFile)
            FileAppend(text, tmpFile, "UTF-8")
            Run('notepad.exe "' tmpFile '"')
        } catch {
            ShowError("Failed to open Notepad.")
        }
    })

    ; Add separator
    resultGui.Add("Text", "x+12 w2 h30 +Background0xCCCCCC", "")

    btnClose := resultGui.Add("Button", "x+12 w80 h30 Default", "✓ Done")
    btnClose.OnEvent("Click", (*) => resultGui.Close())

    resultGui.OnEvent("Close", (*) => resultGui.Destroy())

    ; Auto-select all text for easy copying
    resultEdit.Focus()
    resultEdit.Modify("SelectAll")

    resultGui.Show()

    ; Show helpful tip
    SetTimer(() => {
        try {
            ToolTip("💡 Tip: Press Ctrl+A to select all, then Ctrl+C to copy", A_ScreenWidth - 400, A_ScreenHeight - 120, 2)
            SetTimer(() => ToolTip("", , , 2), -5000)
        }
    }, -1000)
}

CopyToClipboard(text) {
    try {
        A_Clipboard := text
        if ClipWait(1) {
            SoundBeep(1000, 120)
            ShowSuccess("✅ Copied to clipboard!")
        } else {
            ShowError("❌ Failed to copy to clipboard")
        }
    } catch as e {
        ShowError("❌ Copy failed: " e.Message)
    }
}

ShowInfo(msg) {
    ToolTip("ℹ️ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SetTimer(() => ToolTip("", , , 2), -3000)
}

ShowSuccess(msg) {
    ToolTip("✅ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SoundBeep(1000, 100)
    SetTimer(() => ToolTip("", , , 2), -2000)
}

ShowError(msg) {
    ToolTip("❌ " msg, A_ScreenWidth - 350, A_ScreenHeight - 120, 2)
    SoundBeep(500, 300)
    SetTimer(() => ToolTip("", , , 2), -3000)
}

PathShort(p) {
    return (StrLen(p) > 60) ? (SubStr(p, 1, 25) "…" SubStr(p, -25)) : p
}

; Show the test window
MsgBox("This will test the enhanced PromptOpt result window.`n`nFeatures to test:`n• Text statistics in title`n• Auto-select text`n• Enhanced buttons with icons`n• Sound feedback`n• Helpful tooltips`n`nPress OK to open the test window.", "Enhanced PromptOpt Test", "Iconi OK")

ShowResultWindow(testPrompt)