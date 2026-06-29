#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Screenshot / Clipboard-Image Path Grabber
; Quick path-sharing of images with coding agents.
;
; Hotkeys:
;   Alt+S             -> copy newest screenshot path AND paste it
;   Ctrl+Alt+S        -> save clipboard image to ~\Pictures\
;                        clipboard-save and copy its path
;   Ctrl+Alt+Shift+S  -> copy newest screenshot path AND reveal it
;                        in Explorer
;
; Both actions also write the resulting path to a sidecar file so
; other tools/agents can read it without a hotkey:
;   %TEMP%\latest-screenshot-path.txt
; ===================================================================

; --- Candidate screenshot folders, in priority order ---
; The real screenshots currently live in "Screenshots 1", but we
; prefer a bare "Screenshots" folder if it exists and has images.
global SCREENSHOT_DIRS := [
    "C:\Users\prest\OneDrive\Pictures\Screenshots",
    "C:\Users\prest\OneDrive\Pictures\Screenshots 1",
    A_MyDocuments "\..\Pictures\Screenshots",
    A_MyDocuments "\..\Pictures\Screenshots 1"
]

global SIDECAR_FILE := A_Temp "\latest-screenshot-path.txt"
global SCREENSHOT_EXTS := ["png", "jpg", "jpeg", "bmp", "gif", "webp"]

; --- Hotkeys ---
!s::CopyLatestScreenshotPath(false, true)
^!+s::CopyLatestScreenshotPath(true)
^!s::SaveClipboardImageToPath()

; Saves the image currently on the clipboard to a PNG file under
; ~\Pictures\clipboard-save, then replaces the clipboard with that
; file's full path (for quick path-sharing with coding agents).
SaveClipboardImageToPath() {
    psScript := A_ScriptDir "\save-clipboard-image.ps1"
    if !FileExist(psScript) {
        ShowImgFeedback("Helper script not found:`n" psScript)
        return
    }

    outFile := A_Temp "\clipboard-image-path.txt"
    try FileDelete(outFile)

    ; Launch PowerShell directly (no cmd /c, no stdout redirection).
    ; The script writes the saved path to -OutFile, which we read back.
    cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "'
        . psScript '" -OutFile "' outFile '"'
    exitCode := RunWait(cmd, , "Hide")

    path := ""
    try path := Trim(FileRead(outFile, "UTF-8"), " `t`r`n" Chr(0xFEFF))

    if (exitCode != 0 || path = "" || !FileExist(path)) {
        ShowImgFeedback("No image on the clipboard (or save failed).")
        return
    }

    A_Clipboard := path
    if !ClipWait(1) {
        ShowImgFeedback("Saved, but clipboard set failed:`n" path)
        return
    }

    ; Persist for non-interactive consumers (tools/agents).
    try FileDelete(SIDECAR_FILE)
    try FileAppend(path, SIDECAR_FILE, "UTF-8")

    ShowImgFeedback("Path copied:`n" path)
}

; Visible feedback that does not depend on Windows toast notifications
; (which may be silenced by Focus Assist). Shows a brief ToolTip near
; the cursor and falls back to TrayTip.
ShowImgFeedback(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -1800)
    try TrayTip("Clipboard Image", msg, 1)
}

CopyLatestScreenshotPath(revealInExplorer, paste := false) {
    path := FindLatestScreenshot()
    if (path = "") {
        TrayTip("Screenshot Path", "No screenshots found in any known folder.", 1)
        return
    }

    A_Clipboard := path
    if !ClipWait(1) {
        TrayTip("Screenshot Path", "Failed to set clipboard.", 3)
        return
    }

    ; Persist for non-interactive consumers (tools/agents).
    try FileDelete(SIDECAR_FILE)
    try FileAppend(path, SIDECAR_FILE, "UTF-8")

    if (revealInExplorer)
        Run('explorer.exe /select,"' path '"')

    if (paste) {
        Sleep(60)               ; let the clipboard settle
        SendInput("^v")
    }

    TrayTip("Screenshot Path Copied", path, 1)
}

; Returns the full path of the newest screenshot across all candidate
; folders, or "" if none exist.
FindLatestScreenshot() {
    newestPath := ""
    newestTime := ""

    for dir in SCREENSHOT_DIRS {
        if !DirExist(dir)
            continue

        for ext in SCREENSHOT_EXTS {
            Loop Files, dir "\*." ext, "F" {
                if (newestTime = "" || A_LoopFileTimeModified > newestTime) {
                    newestTime := A_LoopFileTimeModified
                    newestPath := A_LoopFileFullPath
                }
            }
        }
    }

    return newestPath
}
