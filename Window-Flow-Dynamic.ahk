#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Window-Flow Dynamic
; Dynamic Window Assignment & Switching Tool
; ===================================================================

; === AUTO-ELEVATE TO ADMIN ===
if !A_IsAdmin {
    try {
        Run("*RunAs " A_ScriptFullPath)
    } catch {
        MsgBox("Failed to run as administrator. Some windows may not be capturable.")
    }
    ExitApp
}

; === GLOBAL SETTINGS ===
global APP_NAME := "Window-Flow Dynamic"
global INI_FILE := "settings.ini"
global MAX_SLOTS := 6
global TOGGLE_HOTKEY := "^!Space"    ; Ctrl+Alt+Space to show Dashboard
global WHEEL_MODIFIER := "^!"        ; Ctrl+Alt+Wheel to switch

; === STATE ===
global g_Slots := []
global g_DashboardGui := ""
global g_OverlayGui := ""
global g_CurrentSlotIndex := 0
global g_MonitorCount := MonitorGetCount()
global g_DwmEnabled := DwmIsEnabled()

; ===================================================================
; DWM THUMBNAIL HELPERS
; ===================================================================
DwmIsEnabled() {
    enabled := 0
    result := DllCall("dwmapi\DwmIsCompositionEnabled", "Int*", &enabled)
    return (result == 0 && enabled)
}

RegisterThumbnail(destHwnd, srcHwnd) {
    thumbId := 0
    result := DllCall("dwmapi\DwmRegisterThumbnail", "Ptr", destHwnd, "Ptr", srcHwnd, "Ptr*", &thumbId)
    return (result == 0) ? thumbId : 0
}

UnregisterThumbnail(thumbId) {
    if (thumbId != 0)
        DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", thumbId)
}

UpdateThumbnailRect(thumbId, left, top, right, bottom) {
    if (thumbId == 0)
        return false

    ; DWM_THUMBNAIL_PROPERTIES structure (32 bytes on x64)
    ; dwFlags (4) + rcDestination (16) + rcSource (16) + opacity (1) + visible (1) + sourceClientAreaOnly (1) + padding
    props := Buffer(48, 0)

    ; DWM_TNP_RECTDESTINATION = 0x1, DWM_TNP_VISIBLE = 0x8, DWM_TNP_OPACITY = 0x4
    flags := 0x1 | 0x8 | 0x4
    NumPut("UInt", flags, props, 0)

    ; rcDestination RECT (left, top, right, bottom) at offset 4
    NumPut("Int", left, props, 4)
    NumPut("Int", top, props, 8)
    NumPut("Int", right, props, 12)
    NumPut("Int", bottom, props, 16)

    ; opacity at offset 36 (after rcDestination + rcSource)
    NumPut("UChar", 255, props, 36)

    ; visible (BOOL) at offset 37
    NumPut("UChar", 1, props, 37)

    result := DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", thumbId, "Ptr", props)
    return (result == 0)
}

UpdateSlotPreview(index) {
    global g_Slots, g_DashboardGui, g_DwmEnabled
    if (!g_DwmEnabled)
        return

    slot := g_Slots[index]

    ; Skip if no thumbnail registered
    if (slot.Thumb == 0)
        return

    ; Get the dashboard's client area position on screen
    ; The preview box coordinates are relative to the GUI client area
    ; DWM needs coordinates relative to the destination window's client area
    left := slot.PreviewX
    top := slot.PreviewY
    right := left + slot.PreviewW
    bottom := top + slot.PreviewH

    UpdateThumbnailRect(slot.Thumb, left, top, right, bottom)
}

RegisterSlotThumbnail(index) {
    global g_Slots, g_DashboardGui, g_DwmEnabled
    if (!g_DwmEnabled)
        return

    slot := g_Slots[index]

    ; Unregister existing thumbnail if any
    if (slot.Thumb != 0) {
        UnregisterThumbnail(slot.Thumb)
        slot.Thumb := 0
    }

    ; Get source window HWND
    if (slot.value == 0 || slot.name == "Empty")
        return

    srcHwnd := 0
    if (slot.type == "session") {
        srcHwnd := slot.value
        if !WinExist("ahk_id " srcHwnd)
            return
    } else {
        ; Permanent slot - get HWND from process name
        srcHwnd := WinExist("ahk_exe " slot.value)
        if (!srcHwnd)
            return
    }

    ; Register thumbnail
    thumbId := RegisterThumbnail(g_DashboardGui.Hwnd, srcHwnd)
    if (thumbId == 0) {
        ; Registration failed - silently continue
        return
    }

    slot.Thumb := thumbId
    UpdateSlotPreview(index)
}

RefreshAllThumbnails() {
    global g_DwmEnabled
    if (!g_DwmEnabled)
        return

    Loop MAX_SLOTS {
        RegisterSlotThumbnail(A_Index)
    }
}

UnregisterAllThumbnails() {
    global g_Slots
    Loop MAX_SLOTS {
        slot := g_Slots[A_Index]
        if (slot.Thumb != 0) {
            UnregisterThumbnail(slot.Thumb)
            slot.Thumb := 0
        }
    }
}

; Initialize Slots
Loop MAX_SLOTS {
    g_Slots.Push({
        id: A_Index,
        name: "Empty",
        type: "session",    ; "session" (HWND) or "permanent" (EXE)
        value: 0,           ; HWND or process name
        saved: 0,           ; 0 or 1 (Checkbox state)
        monitor: 0,         ; 0=Auto/None, 1=Mon1, 2=Mon2, 3=Mouse
        transparency: 255,  ; 25-255 alpha
        Thumb: 0            ; DWM thumbnail handle
    })
}

; === STARTUP ===
LoadSettings()
SetupTray()
CreateDashboard()
TrayTip(APP_NAME, "Ready! Press " TOGGLE_HOTKEY " to configure.", 1)

; === HOTKEYS ===
Hotkey(TOGGLE_HOTKEY, (*) => ToggleDashboard())
Hotkey(WHEEL_MODIFIER "WheelUp", (*) => CycleSlots(-1))
Hotkey(WHEEL_MODIFIER "WheelDown", (*) => CycleSlots(1))

; ===================================================================
; DATA LAYER
; ===================================================================
LoadSettings() {
    global g_Slots
    if !FileExist(INI_FILE)
        return

    Loop MAX_SLOTS {
        index := A_Index
        savedState := IniRead(INI_FILE, "Slot_" index, "Saved", 0)

        if (savedState == "1") {
            g_Slots[index].saved := 1
            g_Slots[index].name := IniRead(INI_FILE, "Slot_" index, "Name", "Empty")
            g_Slots[index].type := IniRead(INI_FILE, "Slot_" index, "Type", "session")
            g_Slots[index].value := IniRead(INI_FILE, "Slot_" index, "Value", 0)
            g_Slots[index].monitor := Integer(IniRead(INI_FILE, "Slot_" index, "Monitor", 0))
            transVal := Integer(IniRead(INI_FILE, "Slot_" index, "Transparency", 255))
            g_Slots[index].transparency := ClampTransparency(transVal)

            ; If permanent, try to reconnect to existing window
            if (g_Slots[index].type == "permanent" && g_Slots[index].value != 0) {
                if WinExist("ahk_exe " g_Slots[index].value) {
                    ; Window exists
                }
            }
        }
    }
}

SaveSlot(index) {
    global g_Slots
    slot := g_Slots[index]

    section := "Slot_" index
    if (slot.saved) {
        IniWrite(1, INI_FILE, section, "Saved")
        IniWrite(slot.name, INI_FILE, section, "Name")
        IniWrite(slot.type, INI_FILE, section, "Type")
        IniWrite(slot.value, INI_FILE, section, "Value")
        IniWrite(slot.monitor, INI_FILE, section, "Monitor")
        IniWrite(slot.transparency, INI_FILE, section, "Transparency")
    } else {
        IniDelete(INI_FILE, section)
    }
}

ClampTransparency(value) {
    value := Integer(value)
    if (value < 25)
        value := 25
    if (value > 255)
        value := 255
    return value
}

; ===================================================================
; UI: DASHBOARD
; ===================================================================
CreateDashboard() {
    global g_DashboardGui, g_Slots

    g_DashboardGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", APP_NAME)
    g_DashboardGui.BackColor := "0x101010"
    g_DashboardGui.MarginX := 10
    g_DashboardGui.MarginY := 10

    ; Header
    g_DashboardGui.SetFont("s11 c00f3ff", "Segoe UI")
    g_DashboardGui.Add("Text", "x20 y10 w600 h20", "Control Modules")

    Loop MAX_SLOTS {
        index := A_Index
        yPos := 40 + ((index-1) * 110)

        ; === CARD BORDER (Cyan Outline) ===
        g_DashboardGui.Add("Text", "x10 y" yPos " w620 h1 Background0x00f3ff")       ; Top
        g_DashboardGui.Add("Text", "x10 y" yPos+105 " w620 h1 Background0x00f3ff")   ; Bottom
        g_DashboardGui.Add("Text", "x10 y" yPos " w1 h105 Background0x00f3ff")       ; Left
        g_DashboardGui.Add("Text", "x630 y" yPos " w1 h106 Background0x00f3ff")      ; Right

        ; === PREVIEW BOX (DWM Thumbnail Target) ===
        previewBox := g_DashboardGui.Add("Text", "x20 y" yPos+8 " w140 h88 Background0x0a0a0a", "")
        g_Slots[index].PreviewBox := previewBox
        g_Slots[index].PreviewX := 20
        g_Slots[index].PreviewY := yPos + 8
        g_Slots[index].PreviewW := 140
        g_Slots[index].PreviewH := 88

        ; === SLOT NUMBER (top right of preview) ===
        g_DashboardGui.SetFont("s28 Bold c00f3ff", "Segoe UI")
        g_DashboardGui.Add("Text", "x170 y" yPos+8 " w40 Center Background0x101010", index)

        ; === WINDOW NAME DISPLAY ===
        g_DashboardGui.SetFont("s10 cFFFFFF Norm", "Segoe UI")
        nameBg := g_DashboardGui.Add("Text", "x215 y" yPos+8 " w290 h28 Background0x222222 +0x200", "")
        g_DashboardGui.SetFont("s10 cFFFFFF")
        nameControl := g_DashboardGui.Add("Text", "x220 y" yPos+8 " w280 h28 BackgroundTrans +0x200 vSlotName" index, "Empty Slot")
        nameControl.OnEvent("Click", ((i, *) => ActivateSlotFromDashboard(i)).Bind(index))
        g_Slots[index].GuiText := nameControl
        g_Slots[index].GuiTextBg := nameBg

        ; === MONITOR TOGGLES ([A] [1] [2] [M]) - top right ===
        g_Slots[index].GuiMonBtns := Map()
        MakeMonBtn(label, val, xOff) {
            g_DashboardGui.SetFont("s8 Bold cFFFFFF")
            btn := g_DashboardGui.Add("Text", "x" (515 + xOff) " y" yPos+8 " w26 h26 Background0x333333 +0x200 Center", label)
            btn.OnEvent("Click", ((i, v, *) => SetMonitorPref(i, v)).Bind(index, val))
            return btn
        }
        g_Slots[index].GuiMonBtns[0] := MakeMonBtn("[A]", 0, 0)
        g_Slots[index].GuiMonBtns[1] := MakeMonBtn("[1]", 1, 28)
        g_Slots[index].GuiMonBtns[2] := MakeMonBtn("[2]", 2, 56)
        g_Slots[index].GuiMonBtns[99] := MakeMonBtn("[M]", 99, 84)

        ; === ROW 2: SET TARGET + OPACITY + KEEP SAVED ===
        g_DashboardGui.SetFont("s9 Bold cFFFFFF")
        btnSet := g_DashboardGui.Add("Button", "x170 y" yPos+70 " w120 h26", "[+] SET TARGET")
        btnSet.OnEvent("Click", ((i, *) => StartCapture(i)).Bind(index))

        g_DashboardGui.SetFont("s9 cFFFFFF")
        g_DashboardGui.Add("Text", "x300 y" yPos+74 " w45 h22 BackgroundTrans", "Opacity")
        slider := g_DashboardGui.Add("Slider", "x350 y" yPos+70 " w100 h26 Range25-255 ToolTip", g_Slots[index].transparency)
        slider.OnEvent("Change", ((i, ctrl, *) => SetTransparency(i, ctrl.Value)).Bind(index))
        g_Slots[index].GuiSlider := slider

        g_DashboardGui.SetFont("s9 c00f3ff")
        chk := g_DashboardGui.Add("Checkbox", "x470 y" yPos+72 " w140 h24 vChk" index, "Keep Saved")
        chk.OnEvent("Click", ((i, *) => ToggleSave(i)).Bind(index))
        g_Slots[index].GuiCheck := chk
    }

    g_DashboardGui.OnEvent("Close", (*) => (UnregisterAllThumbnails(), g_DashboardGui.Hide()))
    g_DashboardGui.OnEvent("Escape", (*) => (UnregisterAllThumbnails(), g_DashboardGui.Hide()))
}

ToggleDashboard() {
    global g_DashboardGui
    if WinActive("ahk_id " g_DashboardGui.Hwnd) {
        g_DashboardGui.Hide()
        UnregisterAllThumbnails()
    } else {
        g_DashboardGui.Show("w645 AutoSize")
        ValidateAllWindows()
        RefreshAllThumbnails()
    }
}

UpdateDashboardSlot(index) {
    global g_Slots
    slot := g_Slots[index]
    
    ; Update Name
    slot.GuiText.Text := (slot.name == "Empty") ? "--- Empty Slot ---" : slot.name
    
    ; Update Name Color (Grey if empty, White if set)
    if (slot.name == "Empty") {
        slot.GuiText.Opt("c666666")
        slot.GuiTextBg.Opt("Background0x222222")
    } else {
        slot.GuiText.Opt("cFFFFFF")
        slot.GuiTextBg.Opt("Background0x333333")
    }

    ; Update Checkbox
    slot.GuiCheck.Value := slot.saved

    ; Update Monitor Buttons (Radio Logic)
    currentMon := slot.monitor
    
    ; Check if monitor is valid (defaults to 0 if not found)
    if !slot.GuiMonBtns.Has(currentMon)
        currentMon := 0
        
    for val, ctrl in slot.GuiMonBtns {
        if (val == currentMon) {
            ; Active: Cyan BG, Black Text
            ctrl.Opt("Background0x00f3ff c000000")
        } else {
            ; Inactive: Dark BG, Grey Text
            ctrl.Opt("Background0x333333 cAAAAAA")
        }
    }

    if (slot.GuiSlider)
        slot.GuiSlider.Value := slot.transparency
}

SetMonitorPref(index, value) {
    global g_Slots
    g_Slots[index].monitor := value
    SaveSlot(index)
    UpdateDashboardSlot(index)
}

; ===================================================================
; TRANSPARENCY
; ===================================================================
GetSlotTarget(slot) {
    if (slot.value == 0)
        return ""

    if (slot.type == "session") {
        return WinExist("ahk_id " slot.value) ? "ahk_id " slot.value : ""
    }

    return WinExist("ahk_exe " slot.value) ? "ahk_exe " slot.value : ""
}

ApplyTransparencyToSlot(index, target := "") {
    global g_Slots
    slot := g_Slots[index]

    if (target == "")
        target := GetSlotTarget(slot)

    if (target != "") {
        try WinSetTransparent(slot.transparency, target)
    }
}

SetTransparency(index, newValue := "") {
    global g_Slots
    slot := g_Slots[index]

    if (newValue != "")
        slot.transparency := ClampTransparency(newValue)
    else
        slot.transparency := ClampTransparency(slot.transparency)

    if (slot.GuiSlider && slot.GuiSlider.Value != slot.transparency)
        slot.GuiSlider.Value := slot.transparency

    SaveSlot(index)
    ApplyTransparencyToSlot(index)
}

; ===================================================================
; INTERACTIVE HANDLERS
; ===================================================================
ActivateSlotFromDashboard(index) {
    global g_Slots

    if (g_Slots[index].name == "Empty" || g_Slots[index].value == 0) {
        ; If empty, treat click as "Set"
        StartCapture(index)
        return
    }

    ; Activate logic
    if ActivateSlot(index) {
        global g_DashboardGui
        g_DashboardGui.Hide()
        ShowOverlay(index, g_Slots[index].name)
    } else {
        ; Window might be gone
        if (MsgBox("Window not found. Clear slot?", "Missing", "YesNo") == "Yes")
            ClearSlot(index)
    }
}

ClearSlot(index) {
    global g_Slots
    slot := g_Slots[index]

    ; Unregister thumbnail if active
    if (slot.Thumb != 0) {
        UnregisterThumbnail(slot.Thumb)
        slot.Thumb := 0
    }

    slot.name := "Empty"
    slot.type := "session"
    slot.value := 0
    slot.saved := 0
    slot.monitor := 0
    slot.transparency := 255

    UpdateDashboardSlot(index)
    SaveSlot(index)
}

ValidateAllWindows() {
    global g_Slots
    Loop MAX_SLOTS {
        index := A_Index
        slot := g_Slots[index]
        if (slot.value != 0 && slot.name != "Empty") {
            exists := (slot.type == "session") ? WinExist("ahk_id " slot.value) : WinExist("ahk_exe " slot.value)

            if (!exists) {
                ; Unregister thumbnail for missing window
                if (slot.Thumb != 0) {
                    UnregisterThumbnail(slot.Thumb)
                    slot.Thumb := 0
                }
                ; Visual indicator for missing window
                slot.GuiText.Opt("cff6666") ; Red text
                slot.GuiTextBg.Opt("Background0x2a0000")
            }
        }
    }
}

RefreshDashboard() {
    Loop MAX_SLOTS
        UpdateDashboardSlot(A_Index)
    ValidateAllWindows()
    RefreshAllThumbnails()
    ToolTip("Refreshed")
    SetTimer(() => ToolTip(), -1000)
}

#HotIf WinActive("ahk_id " g_DashboardGui.Hwnd)
1::ActivateSlotFromDashboard(1)
2::ActivateSlotFromDashboard(2)
3::ActivateSlotFromDashboard(3)
4::ActivateSlotFromDashboard(4)
5::ActivateSlotFromDashboard(5)
6::ActivateSlotFromDashboard(6)
r::RefreshDashboard()
Esc::g_DashboardGui.Hide()
#HotIf

; ===================================================================
; MONITOR LOGIC
; ===================================================================
; (Replaced by SetMonitorPref above)

; ===================================================================
; LOGIC: CAPTURE & ASSIGN
; ===================================================================
StartCapture(index) {
    global g_DashboardGui

    g_DashboardGui.Hide()
    ToolTip(">>> CLICK A WINDOW TO ASSIGN TO SLOT " index " <<<`n(Press ESC to cancel)")

    if KeyWait("LButton", "D T10") {
        MouseGetPos(,, &hwnd)

        if (hwnd == g_DashboardGui.Hwnd) {
            MsgBox("Cannot assign the dashboard itself!")
            ToolTip()
            g_DashboardGui.Show()
            return
        }

        AssignWindow(index, hwnd)
    }

    ToolTip()
    g_DashboardGui.Show()
}

AssignWindow(index, hwnd) {
    global g_Slots

    title := WinGetTitle("ahk_id " hwnd)
    process := WinGetProcessName("ahk_id " hwnd)
    isPermanent := g_Slots[index].saved

    g_Slots[index].name := (title != "") ? SubStr(title, 1, 25) : process

    if (isPermanent) {
        g_Slots[index].type := "permanent"
        g_Slots[index].value := process
    } else {
        g_Slots[index].type := "session"
        g_Slots[index].value := hwnd
    }

    UpdateDashboardSlot(index)
    SaveSlot(index)
    ApplyTransparencyToSlot(index)

    ; Register DWM thumbnail for live preview
    RegisterSlotThumbnail(index)
}

ToggleSave(index) {
    global g_Slots
    slot := g_Slots[index]
    slot.saved := !slot.saved

    if (slot.saved && slot.value != 0) {
        if (slot.type == "session") {
             try {
                 slot.type := "permanent"
                 slot.value := WinGetProcessName("ahk_id " slot.value)
             } catch {
                 slot.saved := 0
                 MsgBox("Window is gone, cannot convert to permanent.")
             }
        }
    } else if (!slot.saved) {
        slot.type := "session"
        if (hwnd := WinExist("ahk_exe " slot.value)) {
            slot.value := hwnd
        } else {
            slot.value := 0
            slot.name := "Empty"
            UpdateDashboardSlot(index)
        }
    }

    SaveSlot(index)
}

; ===================================================================
; LOGIC: SWITCHING
; ===================================================================
CycleSlots(direction) {
    global g_CurrentSlotIndex, g_Slots

    startIndex := g_CurrentSlotIndex
    loopCount := 0

    Loop {
        g_CurrentSlotIndex += direction

        if (g_CurrentSlotIndex > MAX_SLOTS)
            g_CurrentSlotIndex := 1
        if (g_CurrentSlotIndex < 1)
            g_CurrentSlotIndex := MAX_SLOTS

        loopCount++
        if (loopCount > MAX_SLOTS)
            return

        slot := g_Slots[g_CurrentSlotIndex]
        if (slot.value != 0) {
            if ActivateSlot(g_CurrentSlotIndex) {
                ShowOverlay(g_CurrentSlotIndex, slot.name)
                return
            }
        }
    }
}

ActivateSlot(index) {
    global g_Slots
    slot := g_Slots[index]
    target := GetSlotTarget(slot)

    if (target != "") {
        ; Handle Monitor Logic
        if (slot.monitor != 0) {
            targetMon := 0

            if (slot.monitor == 99) {
                ; Move to Monitor with Mouse
                MonitorFromPoint := DllCall.Bind("MonitorFromPoint", "Int64", 0, "UInt", 1) ; 1=MONITOR_DEFAULTTOPRIMARY
                MouseGetPos(&mx, &my)
                ; Get current monitor count and bounds
                loop MonitorGetCount() {
                    MonitorGet(A_Index, &L, &T, &R, &B)
                    if (mx >= L && mx < R && my >= T && my < B) {
                        targetMon := A_Index
                        break
                    }
                }
                if (targetMon == 0) ; Fallback
                    targetMon := MonitorGetPrimary()
            } else {
                ; Specific Monitor
                targetMon := slot.monitor
            }

            if (targetMon > 0 && targetMon <= MonitorGetCount()) {
                WinMoveToMonitor(target, targetMon)
            }
        }

        WinActivate(target)
        ApplyTransparencyToSlot(index, target)
        return true
    }
    return false
}

WinMoveToMonitor(winTitle, monIndex) {
    try {
        MonitorGet(monIndex, &mL, &mT, &mR, &mB)
        mW := mR - mL
        mH := mB - mT

        WinGetPos(&wX, &wY, &wW, &wH, winTitle)

        ; Center on new monitor (simple approach)
        ; Or keep relative position? Let's Center for "Pop up" feel
        newX := mL + (mW - wW) // 2
        newY := mT + (mH - wH) // 2

        WinMove(newX, newY, , , winTitle)
    }
}

; ===================================================================
; UI: OVERLAY
; ===================================================================
ShowOverlay(index, text) {
    global g_OverlayGui

    if (g_OverlayGui)
        g_OverlayGui.Destroy()

    g_OverlayGui := Gui("+AlwaysOnTop +ToolWindow +Disabled -Caption", "Overlay")
    g_OverlayGui.BackColor := "0x101010" ; Darker theme match
    
    ; Layout: [2] Window Name
    g_OverlayGui.SetFont("s16 Bold c00f3ff", "Segoe UI")
    g_OverlayGui.Add("Text", "x10 y10 w40 Center", "[" index "]")
    
    g_OverlayGui.SetFont("s12 cFFFFFF", "Segoe UI")
    g_OverlayGui.Add("Text", "x60 y13 w300", (StrLen(text) > 30 ? SubStr(text, 1, 27) "..." : text))

    ; Position: Bottom Right Toast
    info := MonitorGet(MonitorGetPrimary(), &l, &t, &r, &b)
    width := 380
    height := 50
    x := r - width - 20
    y := b - height - 60

    g_OverlayGui.Show("x" x " y" y " w" width " h" height " NoActivate")
    
    ; Cyan Border for overlay
    WinSetRegion("0-0 w" width " h" height " R10-10", g_OverlayGui.Hwnd) ; Rounded? Or just standard.
    ; Let's simulate border with a frame if possible, or just transparency.
    WinSetTransparent(230, g_OverlayGui)

    SetTimer(DestroyOverlay, -1500)
}

DestroyOverlay() {
    global g_OverlayGui
    if (g_OverlayGui) {
        g_OverlayGui.Destroy()
        g_OverlayGui := ""
    }
}

SetupTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Configure", (*) => ToggleDashboard())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}
