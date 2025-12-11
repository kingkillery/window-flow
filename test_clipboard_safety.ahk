; test_clipboard_safety.ahk - Test that normal Ctrl+C/Ctrl+V works without interference
#Requires AutoHotkey v1.1
#SingleInstance Force

MsgBox, 64, Clipboard Safety Test, This test will verify that normal copy-paste operations work correctly without PromptOpt interference.`n`n1. Test normal copy-paste (Ctrl+C, Ctrl+V)`n2. Test PK_PROMPT feature when enabled`n3. Verify clipboard monitoring toggle works`n`nPress OK to start testing., 10

; Create a test GUI for easier testing
TestGui := Gui("+AlwaysOnTop", "Clipboard Safety Test")
TestGui.SetFont("s11", "Segoe UI")
TestGui.Add("Text", "w600 h30", "✅ Normal Ctrl+C/Ctrl+V should work always")
TestGui.Add("Text", "w600 h30", "🔒 PK_PROMPT monitoring is DISABLED by default")
TestGui.Add("Text", "w600 h30", "🔄 Press Ctrl+Alt+Shift+C to toggle PK_PROMPT")
TestGui.Add("Text", "w600 h30", "")

TestGui.Add("Text", "w600 h20", "Test this text:")
testEdit := TestGui.Add("Edit", "w600 h60 ReadOnly", "This is sample text for testing clipboard operations.`nYou can select and copy this text normally.")

TestGui.Add("Text", "w600 h30", "")
TestGui.Add("Text", "w600 h20", "Paste area:")
pasteEdit := TestGui.Add("Edit", "w600 h100", "")

TestGui.Add("Text", "w600 h30", "")
btnClear := TestGui.Add("Button", "w100", "Clear Paste Area")
btnStatus := TestGui.Add("Button", "x+12 w120", "Check PK Status")
btnHelp := TestGui.Add("Button", "x+12 w100", "Help")
btnClose := TestGui.Add("Button", "x+12 w80", "Close")

btnClear.OnEvent("Click", (*) => pasteEdit.Value := "")

btnStatus.OnEvent("Click", (*) => {
    global PK_CLIPBOARD_MONITORING_ENABLED
    if (IsSet(PK_CLIPBOARD_MONITORING_ENABLED) && PK_CLIPBOARD_MONITORING_ENABLED) {
        MsgBox("PK_PROMPT monitoring: ENABLED`n`n⚠️ Clipboard will be monitored for 'PK_PROMPT' prefix`nNormal copy-paste should still work, but may have slight delays")
    } else {
        MsgBox("PK_PROMPT monitoring: DISABLED`n`n✅ Normal copy-paste should work perfectly without any interference")
    }
})

btnHelp.OnEvent("Click", (*) => {
    MsgBox("Instructions:`n`n1. NORMAL USE (Default):`n   • Select text above`n   • Press Ctrl+C to copy`n   • Press Ctrl+V to paste`n   • Works normally without interference`n`n2. PK_PROMPT FEATURE (Optional):`n   • Press Ctrl+Alt+Shift+C to enable`n   • Copy text starting with 'PK_PROMPT '`n   • It will be automatically optimized`n   • Press Ctrl+Alt+Shift+C again to disable`n`n3. ALWAYS:`n   • Use Ctrl+Alt+P for PromptOpt with GUI`n   • Use right-click context menu for files", "Help", "Iconi")
})

btnClose.OnEvent("Click", (*) => TestGui.Close())
TestGui.OnEvent("Close", (*) => TestGui.Destroy())

TestGui.Show()

; Add a status indicator
SetTimer(() => {
    try {
        if (IsSet(PK_CLIPBOARD_MONITORING_ENABLED) && PK_CLIPBOARD_MONITORING_ENABLED) {
            ToolTip("PK_PROMPT: ENABLED", 10, 10, 1)
        } else {
            ToolTip("PK_PROMPT: DISABLED", 10, 10, 1)
        }
        SetTimer(() => ToolTip("", , , 1), -2000)
    }
}, -5000)