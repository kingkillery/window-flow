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
    g_DashboardGui.BackColor := "0x101010"
    g_DashboardGui.MarginX := 10
    g_DashboardGui.MarginY := 10
    
    ; Header
    g_DashboardGui.SetFont("s11 c00f3ff", "Segoe UI")
    g_DashboardGui.Add("Text", "x20 y10 w600 h20", "Control Modules")

    Loop MAX_SLOTS {
        index := A_Index
        yPos := 40 + ((index-1) * 95)

        ; === CARD BORDER (Cyan Outline) ===
        ; Using Text controls to draw 1px borders
        g_DashboardGui.Add("Text", "x10 y" yPos " w620 h1 Background0x00f3ff")      ; Top
        g_DashboardGui.Add("Text", "x10 y" yPos+90 " w620 h1 Background0x00f3ff")    ; Bottom
        g_DashboardGui.Add("Text", "x10 y" yPos " w1 h90 Background0x00f3ff")       ; Left
        g_DashboardGui.Add("Text", "x630 y" yPos " w1 h91 Background0x00f3ff")      ; Right

        ; === SLOT NUMBER ===
        g_DashboardGui.SetFont("s42 Bold c00f3ff", "Segoe UI")
        g_DashboardGui.Add("Text", "x20 y" yPos+12 " w60 Center Background0x101010", index)

        ; === WINDOW NAME DISPLAY ===
        ; Read-only text box style
        g_DashboardGui.SetFont("s10 cFFFFFF Norm", "Segoe UI")
        
        ; Background for name
        nameBg := g_DashboardGui.Add("Text", "x90 y" yPos+12 " w360 h30 Background0x222222 +0x200", "")
        
        ; Actual Text (Overlay)
        g_DashboardGui.SetFont("s10 cFFFFFF")
        nameControl := g_DashboardGui.Add("Text", "x95 y" yPos+12 " w350 h30 BackgroundTrans +0x200 vSlotName" index, "Empty Slot")
        
        ; Click name to activate
        nameControl.OnEvent("Click", ((i, *) => ActivateSlotFromDashboard(i)).Bind(index))
        g_Slots[index].GuiText := nameControl
        g_Slots[index].GuiTextBg := nameBg

        ; === SET TARGET BUTTON ===
        ; Styled as a wide dark button
        g_DashboardGui.SetFont("s9 Bold cFFFFFF")
        btnSet := g_DashboardGui.Add("Button", "x90 y" yPos+50 " w360 h28", "[+] SET TARGET")
        btnSet.OnEvent("Click", ((i, *) => StartCapture(i)).Bind(index))

        ; === MONITOR TOGGLES ([A] [1] [2] [M]) ===
        ; Using Text controls to simulate colored toggle buttons
        g_Slots[index].GuiMonBtns := Map()
        
        MakeMonBtn(label, val, xOff) {
            g_DashboardGui.SetFont("s9 Bold cFFFFFF")
            ; Background
            btn := g_DashboardGui.Add("Text", "x" (465 + xOff) " y" yPos+12 " w30 h30 Background0x333333 +0x200 Center", label)
            btn.OnEvent("Click", ((i, v, *) => SetMonitorPref(i, v)).Bind(index, val))
            return btn
        }

        g_Slots[index].GuiMonBtns[0] := MakeMonBtn("[A]", 0, 0)
        g_Slots[index].GuiMonBtns[1] := MakeMonBtn("[1]", 1, 35)
        g_Slots[index].GuiMonBtns[2] := MakeMonBtn("[2]", 2, 70)
        g_Slots[index].GuiMonBtns[99] := MakeMonBtn("[M]", 99, 105)

        ; === KEEP SAVED CHECKBOX ===
        g_DashboardGui.SetFont("s10 c00f3ff")
        chk := g_DashboardGui.Add("Checkbox", "x465 y" yPos+52 " w140 vChk" index, "Keep Saved")
        chk.OnEvent("Click", ((i, *) => ToggleSave(i)).Bind(index))
        g_Slots[index].GuiCheck := chk
    }

    g_DashboardGui.OnEvent("Close", (*) => g_DashboardGui.Hide())
    g_DashboardGui.OnEvent("Escape", (*) => g_DashboardGui.Hide())
}

ToggleDashboard() {
    global g_DashboardGui
    if WinActive("ahk_id " g_DashboardGui.Hwnd) {
        g_DashboardGui.Hide()
    } else {
        g_DashboardGui.Show("w645 AutoSize")
        ValidateAllWindows()
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
}

SetMonitorPref(index, value) {
    global g_Slots
    g_Slots[index].monitor := value
    SaveSlot(index)
    UpdateDashboardSlot(index)
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
            exists := (slot.type == "session") ? WinExist("ahk_id " slot.value) : WinExist("ahk_exe " slot.value)
            
            if (!exists) {
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
