#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Screenshot / Clipboard-Image Path Grabber
; Quick path-sharing of images with coding agents.
;
; Hotkeys:
;   Alt+S             -> save clipboard image to ~\Pictures\
;                        clipboard-save and copy its path
;   Ctrl+Alt+S        -> copy newest screenshot path to clipboard
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
^!s::CopyLatestScreenshotPath(false)
^!+s::CopyLatestScreenshotPath(true)
!s::SaveClipboardImageToPath()

; Saves the image currently on the clipboard to a PNG file under
; ~\Pictures\clipboard-save, then replaces the clipboard with that
; file's full path (for quick path-sharing with coding agents).
SaveClipboardImageToPath() {
    psScript := A_ScriptDir "\save-clipboard-image.ps1"
    if !FileExist(psScript) {
        TrayTip("Clipboard Image", "Helper script not found:`n" psScript, 3)
        return
    }

    outFile := A_Temp "\clipboard-image-path.txt"
    try FileDelete(outFile)

    cmd := A_ComSpec ' /c powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "'
        . psScript '" > "' outFile '" 2>nul'
    exitCode := RunWait(cmd, , "Hide")

    if (exitCode != 0) {
        TrayTip("Clipboard Image", "No image on the clipboard.", 2)
        return
    }

    path := ""
    try path := Trim(FileRead(outFile, "UTF-8"), " `t`r`n")
    if (path = "" || !FileExist(path)) {
        TrayTip("Clipboard Image", "Failed to save clipboard image.", 3)
        return
    }

    A_Clipboard := path
    if !ClipWait(1) {
        TrayTip("Clipboard Image", "Saved, but failed to set clipboard:`n" path, 3)
        return
    }

    ; Persist for non-interactive consumers (tools/agents).
    try FileDelete(SIDECAR_FILE)
    try FileAppend(path, SIDECAR_FILE, "UTF-8")

    TrayTip("Clipboard Image Saved", path, 1)
}

CopyLatestScreenshotPath(revealInExplorer) {
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
