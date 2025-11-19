; test_clipboard.ahk - Simple test to verify clipboard functionality
#Requires AutoHotkey v1.1
#SingleInstance Force

MsgBox, 64, Clipboard Test, This script will test basic clipboard functionality.`n`n1. Copy some text with Ctrl+C`n2. Press F1 to check clipboard content`n3. Press F2 to paste test text`n4. Press ESC to exit`n`nThe script should not interfere with normal copy-paste.

F1::
    Clipboard := ""
    Send, ^c
    ClipWait, 1
    if (Clipboard = "")
        MsgBox, 48, Test Result, No text found in clipboard
    else
        MsgBox, 64, Test Result, Clipboard contains:`n`n%Clipboard%
    return

F2::
    Clipboard := "Test paste from clipboard test script"
    ClipWait, 1
    Send, ^v
    MsgBox, 64, Test Complete, Test text should now be pasted.
    return

ESC::
    ExitApp