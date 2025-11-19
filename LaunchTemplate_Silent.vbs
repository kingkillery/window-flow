' VBScript launcher for Template.ahk with AutoHotkey v2
' This runs silently without showing a console window

Dim objShell, ahkPath, scriptPath

Set objShell = CreateObject("WScript.Shell")

ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
scriptPath = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "Template.ahk"

' Check if AutoHotkey v2 exists
Set objFSO = CreateObject("Scripting.FileSystemObject")
If Not objFSO.FileExists(ahkPath) Then
    MsgBox "AutoHotkey v2 not found!" & vbCrLf & vbCrLf & _
           "Expected at: " & ahkPath & vbCrLf & vbCrLf & _
           "Please install from: https://www.autohotkey.com/download/ahk-v2.exe", _
           vbExclamation, "AutoHotkey v2 Required"
    WScript.Quit
End If

' Check if script exists
If Not objFSO.FileExists(scriptPath) Then
    MsgBox "Script not found!" & vbCrLf & vbCrLf & _
           "Expected at: " & scriptPath, _
           vbExclamation, "Script Not Found"
    WScript.Quit
End If

' Launch the script with AutoHotkey v2
objShell.Run """" & ahkPath & """ """ & scriptPath & """", 0, False
