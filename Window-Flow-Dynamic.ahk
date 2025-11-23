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

; Initialize Slots
Loop MAX_SLOTS {
    g_Slots.Push({
        id: A_Index,
        name: "Empty",
        type: "session",    ; "session" (HWND) or "permanent" (EXE)
        value: 0,           ; HWND or process name
        saved: 0,           ; 0 or 1 (Checkbox state)
        monitor: 0          ; 0=Auto/None, 1=Mon1, 2=Mon2, 3=Mouse
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
    } else {
        IniDelete(INI_FILE, section)
    }
}

; ===================================================================
; UI: DASHBOARD
; ===================================================================
CreateDashboard() {
    global g_DashboardGui, g_Slots

    g_DashboardGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", APP_NAME)
    g_DashboardGui.BackColor := "0x1a1a1a"
    g_DashboardGui.MarginX := 15
    g_DashboardGui.MarginY := 15

    ; Set default font with white text for readability
    g_DashboardGui.SetFont("s10 cFFFFFF", "Segoe UI")

    g_DashboardGui.SetFont("s14 Bold c00f3ff")
    g_DashboardGui.Add("Text", "x0 y10 w500 Center", "Window-Flow Dynamic")

    g_DashboardGui.SetFont("s9 cAAAAAA")
    g_DashboardGui.Add("Text", "x0 y35 w500 Center", "Assign windows to slots. Use " WHEEL_MODIFIER " + Wheel to switch. Click names to activate. Press 1-6, R to refresh.")

    ; Separator
    g_DashboardGui.SetFont("s10 cFFFFFF")
    g_DashboardGui.Add("Text", "x0 y60 w500 h1 Background0x444444")

    ; Column Headers with Refresh button
    g_DashboardGui.SetFont("s9 c888888")
    g_DashboardGui.Add("Text", "x20 y70 w40", "Slot")
    g_DashboardGui.Add("Text", "x70 y70 w160", "Application")
    g_DashboardGui.Add("Text", "x240 y70 w80 Center", "Monitor")
    g_DashboardGui.Add("Text", "x330 y70 w60", "Action")
    g_DashboardGui.Add("Text", "x400 y70 w60", "Persist")

    ; Refresh button
    g_DashboardGui.SetFont("s8 Bold c00f3ff")
    btnRefresh := g_DashboardGui.Add("Button", "x460 y67 w30 h20 Background0x2a2a2a", "⟳")
    btnRefresh.OnEvent("Click", (*) => RefreshDashboard())
    btnRefresh.ToolTip := "Validate all windows and refresh status"

    Loop MAX_SLOTS {
        index := A_Index
        ; INCREASED SPACING: 55px per row instead of 45
        yPos := 95 + ((index-1) * 55)

        ; Slot Number (Bold)
        g_DashboardGui.SetFont("s12 Bold c00f3ff")
        slotLabel := g_DashboardGui.Add("Text", "x20 y" yPos+5 " w40", index)

        ; Status/Name Text (Interactive - Click to activate)
        nameText := g_Slots[index].name
        color := (nameText = "Empty") ? "0x666666" : "0xffffff"
        bgColor := (nameText != "Empty") ? "0x2a2a2a" : "0x1a1a1a"

        g_DashboardGui.SetFont("s11 c" color " Underline")
        nameControl := g_DashboardGui.Add("Text", "x70 y" yPos+5 " w160 h25 Background" bgColor " vSlotName" index " Center", nameText)

        ; Make clickable only if window is assigned
        if (nameText != "Empty") {
            nameControl.OnEvent("Click", ((i, *) => ActivateSlotFromDashboard(i)).Bind(index))
        }

        g_Slots[index].GuiText := nameControl

        ; Monitor Button (Cycle)
        monLabel := GetMonitorLabel(g_Slots[index].monitor)
        g_DashboardGui.SetFont("s9 cE0E0E0")
        btnMon := g_DashboardGui.Add("Button", "x240 y" yPos " w80 h28 Background0x2a2a2a", monLabel)
        btnMon.OnEvent("Click", ((i, ctrl, *) => CycleMonitorPref(i, ctrl)).Bind(index))
        g_Slots[index].GuiMonBtn := btnMon

        ; Assign Button (Dark theme)
        g_DashboardGui.SetFont("s9 Bold cFFFFFF")
        btn := g_DashboardGui.Add("Button", "x330 y" yPos " w60 h28 Background0x333333", "Set")
        btn.OnEvent("Click", ((i, *) => StartCapture(i)).Bind(index))

        ; Save Checkbox (Styled)
        g_DashboardGui.SetFont("s10 c0xffffff")
        chk := g_DashboardGui.Add("Checkbox", "x410 y" yPos+5 " w80 vChk" index, "Save")
        chk.Value := g_Slots[index].saved
        chk.OnEvent("Click", ((i, *) => ToggleSave(i)).Bind(index))
        g_Slots[index].GuiCheck := chk

        ; Row Separator (Subtle)
        if (index < MAX_SLOTS)
            g_DashboardGui.Add("Text", "x20 y" yPos+45 " w460 h1 Background0x222222")
    }

    g_DashboardGui.OnEvent("Close", (*) => g_DashboardGui.Hide())
    g_DashboardGui.OnEvent("Escape", (*) => g_DashboardGui.Hide())
}

ToggleDashboard() {
    global g_DashboardGui
    if WinActive("ahk_id " g_DashboardGui.Hwnd) {
        g_DashboardGui.Hide()
        SetTimer(CheckHover, 0) ; Stop hover check
    } else {
        g_DashboardGui.Show("w500 AutoSize") ; Fixed width, auto height
        SetTimer(CheckHover, 50) ; Start hover check
        ; Auto-refresh window status when opening dashboard
        ValidateAllWindows()
    }
}

CheckHover() {
    global g_Slots, g_DashboardGui

    try {
        MouseGetPos(,,, &hCtrl, 2) ; Get HWND of control under mouse
    } catch {
        return
    }

    Loop MAX_SLOTS {
        if !g_Slots.Has(A_Index) || !g_Slots[A_Index].HasProp("GuiText")
            continue

        ctrl := g_Slots[A_Index].GuiText
        if (ctrl && ctrl.Hwnd == hCtrl)
            OnWindowNameHover(A_Index, ctrl, true)
        else if (ctrl)
            OnWindowNameHover(A_Index, ctrl, false)
    }
}

UpdateDashboardSlot(index) {
    global g_Slots
    g_Slots[index].GuiText.Value := g_Slots[index].name

    ; Update appearance based on slot status
    nameText := g_Slots[index].name
    color := (nameText = "Empty") ? "0x666666" : "0xffffff"
    bgColor := (nameText != "Empty") ? "0x2a2a2a" : "0x1a1a1a"
    hasUnderline := (nameText != "Empty")

    g_Slots[index].GuiText.Opt("Background" bgColor)
    g_Slots[index].GuiText.SetFont("c" color " " (hasUnderline ? "Underline" : "Norm"))
    g_Slots[index].GuiCheck.Value := g_Slots[index].saved
    g_Slots[index].GuiMonBtn.Text := GetMonitorLabel(g_Slots[index].monitor)

    ; Re-bind click events if window is now assigned
    if (nameText != "Empty") {
        g_Slots[index].GuiText.OnEvent("Click", ((i, *) => ActivateSlotFromDashboard(i)).Bind(index))
    }
}

; ===================================================================
; INTERACTIVE WINDOW NAME HANDLERS
; ===================================================================
ActivateSlotFromDashboard(index) {
    global g_Slots

    if (g_Slots[index].name == "Empty") {
        MsgBox("Slot " index " is empty. Click 'Set' to assign a window.", "Empty Slot", "T2")
        return
    }

    ; Check if window exists before activating
    target := ""
    slot := g_Slots[index]

    if (slot.type == "session") {
        if WinExist("ahk_id " slot.value)
            target := "ahk_id " slot.value
    } else {
        if WinExist("ahk_exe " slot.value)
            target := "ahk_exe " slot.value
    }

    if (target != "") {
        if ActivateSlot(index) {
            ; Close dashboard after successful activation for better UX
            global g_DashboardGui
            g_DashboardGui.Hide()
            SetTimer(CheckHover, 0) ; Stop hover check
            ShowOverlay(index, slot.name)
        } else {
            MsgBox("Failed to activate window: " slot.name, "Activation Error", "T2")
        }
    } else {
        ; Window no longer exists
        result := MsgBox("Window '" slot.name "' is no longer available.`n`nWould you like to clear this slot?", "Window Not Found", "T2 YesNo")

        if (result = "Yes") {
            ClearSlot(index)
        }
    }
}

OnWindowNameHover(index, ctrl, isHovering) {
    global g_Slots

    if (g_Slots[index].name == "Empty")
        return

    if (isHovering) {
        ; Hover effect: brighten color and change cursor
        ctrl.Opt("Background0x333333")
        ctrl.SetFont("s11 c0x00f3ff Underline")
        ; Note: AHK doesn't directly support cursor changes on text controls
        ; This is a limitation, but the color change provides visual feedback
    } else {
        ; Normal state
        ctrl.Opt("Background0x2a2a2a")
        ctrl.SetFont("s11 c0xffffff Underline")
    }
}

ClearSlot(index) {
    global g_Slots
    g_Slots[index].name := "Empty"
    g_Slots[index].type := "session"
    g_Slots[index].value := 0
    g_Slots[index].saved := 0
    g_Slots[index].monitor := 0

    UpdateDashboardSlot(index)
    SaveSlot(index)
}

ValidateAllWindows() {
    global g_Slots

    Loop MAX_SLOTS {
        index := A_Index
        slot := g_Slots[index]

        if (slot.value != 0 && slot.name != "Empty") {
            exists := false

            if (slot.type == "session") {
                exists := WinExist("ahk_id " slot.value)
            } else {
                exists := WinExist("ahk_exe " slot.value)
            }

            if (!exists) {
                ; Mark as unavailable but don't clear automatically
                if (g_Slots[index].GuiText) {
                    g_Slots[index].GuiText.Opt("Background0x2a0000")
                    g_Slots[index].GuiText.SetFont("c0xff6666")
                }
            } else {
                ; Restore normal color if window exists
                if (g_Slots[index].GuiText) {
                    g_Slots[index].GuiText.Opt("Background0x2a2a2a")
                    g_Slots[index].GuiText.SetFont("c0xffffff")
                }
            }
        }
    }
}

RefreshDashboard() {
    ; Update all slots with current window status
    Loop MAX_SLOTS {
        UpdateDashboardSlot(A_Index)
    }

    ; Validate all windows and update colors
    ValidateAllWindows()

    ; Brief feedback to user
    ToolTip("Window status refreshed")
    SetTimer(() => ToolTip(), -1500)
}

#HotIf WinActive("ahk_id " g_DashboardGui.Hwnd)
1::ActivateSlotFromDashboard(1)
2::ActivateSlotFromDashboard(2)
3::ActivateSlotFromDashboard(3)
4::ActivateSlotFromDashboard(4)
5::ActivateSlotFromDashboard(5)
6::ActivateSlotFromDashboard(6)
r::RefreshDashboard()
c::
{
    ToolTip("Press number key 1-6 to activate, R to refresh")
    SetTimer(() => ToolTip(), -2000)
}
#HotIf

; ===================================================================
; MONITOR LOGIC
; ===================================================================
GetMonitorLabel(val) {
    if (val == 0)
        return "Auto"
    if (val == 99)
        return "Mouse"
    return "Mon " val
}

CycleMonitorPref(index, ctrl) {
    global g_Slots, g_MonitorCount

    current := g_Slots[index].monitor

    ; Cycle: 0 (Auto) -> 1 -> 2... -> 99 (Mouse) -> 0
    if (current == 0)
        current := 1
    else if (current < g_MonitorCount)
        current++
    else if (current == g_MonitorCount)
        current := 99 ; Mouse
    else
        current := 0

    g_Slots[index].monitor := current
    ctrl.Text := GetMonitorLabel(current)

    SaveSlot(index) ; Persist change
}

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
    target := ""

    ; Find Target
    if (slot.type == "session") {
        if WinExist("ahk_id " slot.value)
            target := "ahk_id " slot.value
    } else {
        if WinExist("ahk_exe " slot.value)
            target := "ahk_exe " slot.value
    }

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
    g_OverlayGui.BackColor := "000000"
    g_OverlayGui.SetFont("s24 bold", "Segoe UI")

    g_OverlayGui.SetFont("s18 Bold c00f3ff")
    g_OverlayGui.Add("Text", "x0 y10 w400 Center", "Activating")

    g_OverlayGui.SetFont("s16 cFFFFFF")
    g_OverlayGui.Add("Text", "x0 y35 w400 Center", "Slot " index)

    g_OverlayGui.SetFont("s12 cCCCCCC")
    g_OverlayGui.Add("Text", "x0 y55 w400 Center", text)

    info := MonitorGet(MonitorGetPrimary(), &l, &t, &r, &b)
    width := 400
    height := 100
    x := l + (r-l - width) // 2
    y := t + (b-t - height) // 2

    g_OverlayGui.Show("x" x " y" y " w" width " h" height " NoActivate")
    WinSetTransparent(240, g_OverlayGui)

    SetTimer(DestroyOverlay, -1000)
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
