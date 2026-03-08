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
global SWITCHER_EXE := A_ScriptDir "\bin\WindowFlow.Switcher.exe"
global MAX_SLOTS := 6
global TOGGLE_HOTKEY := "^!Space"
global WHEEL_MODIFIER := "^!"

global g_Slots := []
global g_DashboardGui := 0
global g_OverlayGui := 0
global g_PresetEditorGui := 0
global g_NewPresetGui := 0
global g_PresetEditorRowKeys := []
global g_CurrentSlotIndex := 0
global g_MonitorCount := MonitorGetCount()
global g_DwmEnabled := DwmIsEnabled()
global g_LabelPresets := Map()
global g_LabelOrder := ["none"]

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

    props := Buffer(48, 0)
    flags := 0x1 | 0x8 | 0x4
    NumPut("UInt", flags, props, 0)
    NumPut("Int", left, props, 4)
    NumPut("Int", top, props, 8)
    NumPut("Int", right, props, 12)
    NumPut("Int", bottom, props, 16)
    NumPut("UChar", 255, props, 36)
    NumPut("UChar", 1, props, 37)

    result := DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", thumbId, "Ptr", props)
    return (result == 0)
}

UpdateSlotPreview(index) {
    global g_Slots, g_DwmEnabled
    if (!g_DwmEnabled)
        return

    slot := g_Slots[index]
    if (slot.Thumb == 0)
        return

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
    if (slot.Thumb != 0) {
        UnregisterThumbnail(slot.Thumb)
        slot.Thumb := 0
    }

    srcHwnd := GetSlotHwnd(slot)
    if (!srcHwnd)
        return

    thumbId := RegisterThumbnail(g_DashboardGui.Hwnd, srcHwnd)
    if (thumbId == 0)
        return

    slot.Thumb := thumbId
    UpdateSlotPreview(index)
}

RefreshAllThumbnails() {
    global g_DwmEnabled, MAX_SLOTS
    if (!g_DwmEnabled)
        return

    Loop MAX_SLOTS
        RegisterSlotThumbnail(A_Index)
}

UnregisterAllThumbnails() {
    global g_Slots, MAX_SLOTS
    Loop MAX_SLOTS {
        slot := g_Slots[A_Index]
        if (slot.Thumb != 0) {
            UnregisterThumbnail(slot.Thumb)
            slot.Thumb := 0
        }
    }
}

Loop MAX_SLOTS {
    g_Slots.Push({
        id: A_Index,
        name: "Empty",
        type: "session",
        value: 0,
        saved: 0,
        monitor: 0,
        maximize: 0,
        transparency: 255,
        labelKey: "none",
        alias: "",
        borderEnabled: 0,
        Thumb: 0,
        BadgeGui: 0,
        BadgeText: 0,
        BorderGui: 0,
        BorderTop: 0,
        BorderBottom: 0,
        BorderLeft: 0,
        BorderRight: 0
    })
}

InitLabelPresets()
LoadSettings()
SetupTray()
CreateDashboard()
SetTimer(UpdateAllBadges, 300)
TrayTip("Ready! Press " TOGGLE_HOTKEY " to configure.", APP_NAME)

Hotkey(TOGGLE_HOTKEY, (*) => ToggleDashboard())
Hotkey(WHEEL_MODIFIER "WheelUp", (*) => CycleSlots(-1))
Hotkey(WHEEL_MODIFIER "WheelDown", (*) => CycleSlots(1))

InitLabelPresets() {
    global g_LabelPresets
    g_LabelPresets := Map()
    SetLabelPreset("none", "Unlabeled", "NONE", "444444")
    SetLabelPreset("obsidian", "Obsidian Plugins", "OBS", "00F3FF")
    SetLabelPreset("scribe", "scribe-extension", "SCRIBE", "FFBF3C")
    SetLabelPreset("pk", "private-pk-scripts", "PK", "57D17A")
    LoadPresetSettings()
    RebuildLabelOrder()
}

SetLabelPreset(key, name, shortName, colorHex) {
    global g_LabelPresets
    normalizedColor := NormalizeColorHex(colorHex, "444444")
    normalizedShort := Trim(shortName)
    if (normalizedShort == "")
        normalizedShort := BuildShortLabel(name)

    g_LabelPresets[key] := {
        key: key,
        name: name,
        short: StrUpper(normalizedShort),
        color: normalizedColor,
        textColor: GetContrastTextColor(normalizedColor)
    }
}

LoadPresetSettings() {
    global g_LabelPresets, INI_FILE
    keysRaw := IniRead(INI_FILE, "LabelPresets", "Keys", "")
    if (keysRaw == "")
        return

    loadedPresets := Map()
    loadedPresets["none"] := g_LabelPresets["none"]

    Loop Parse, keysRaw, "|" {
        key := Trim(A_LoopField)
        if (key == "" || key == "none")
            continue

        section := "Preset_" key
        presetName := IniRead(INI_FILE, section, "Name", key)
        presetShort := IniRead(INI_FILE, section, "Short", BuildShortLabel(presetName))
        presetColor := IniRead(INI_FILE, section, "Color", "444444")
        normalizedColor := NormalizeColorHex(presetColor, "444444")
        loadedPresets[key] := {
            key: key,
            name: presetName,
            short: StrUpper(presetShort),
            color: normalizedColor,
            textColor: GetContrastTextColor(normalizedColor)
        }
    }

    if (loadedPresets.Count > 1)
        g_LabelPresets := loadedPresets
}

SavePresetSettings() {
    global g_LabelPresets, INI_FILE
    keys := []

    for key, preset in g_LabelPresets {
        if (key == "none")
            continue

        keys.Push(key)
        section := "Preset_" key
        IniWrite(preset.name, INI_FILE, section, "Name")
        IniWrite(preset.short, INI_FILE, section, "Short")
        IniWrite(preset.color, INI_FILE, section, "Color")
    }

    IniWrite(keys.Length ? JoinArray(keys, "|") : "", INI_FILE, "LabelPresets", "Keys")
}

LoadSettings() {
    global g_Slots, INI_FILE, MAX_SLOTS
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
            g_Slots[index].maximize := Integer(IniRead(INI_FILE, "Slot_" index, "Maximize", 0))
            transVal := Integer(IniRead(INI_FILE, "Slot_" index, "Transparency", 255))
            g_Slots[index].transparency := ClampTransparency(transVal)
            g_Slots[index].labelKey := NormalizeLabelKey(IniRead(INI_FILE, "Slot_" index, "Label", "none"))
            g_Slots[index].alias := IniRead(INI_FILE, "Slot_" index, "Alias", "")
            g_Slots[index].borderEnabled := Integer(IniRead(INI_FILE, "Slot_" index, "Border", 0))
        }
    }
}

SaveSlot(index) {
    global g_Slots, INI_FILE
    slot := g_Slots[index]
    section := "Slot_" index

    if (slot.saved) {
        IniWrite(1, INI_FILE, section, "Saved")
        IniWrite(slot.name, INI_FILE, section, "Name")
        IniWrite(slot.type, INI_FILE, section, "Type")
        IniWrite(slot.value, INI_FILE, section, "Value")
        IniWrite(slot.monitor, INI_FILE, section, "Monitor")
        IniWrite(slot.maximize, INI_FILE, section, "Maximize")
        IniWrite(slot.transparency, INI_FILE, section, "Transparency")
        IniWrite(slot.labelKey, INI_FILE, section, "Label")
        IniWrite(slot.alias, INI_FILE, section, "Alias")
        IniWrite(slot.borderEnabled, INI_FILE, section, "Border")
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

NormalizeLabelKey(labelKey) {
    global g_LabelPresets
    return g_LabelPresets.Has(labelKey) ? labelKey : "none"
}

NormalizeColorHex(colorHex, fallback := "444444") {
    colorHex := Trim(colorHex)
    colorHex := StrReplace(colorHex, "#")
    colorHex := StrReplace(colorHex, "0x")
    colorHex := RegExReplace(colorHex, "[^0-9A-Fa-f]")

    if (StrLen(colorHex) == 3) {
        colorHex := SubStr(colorHex, 1, 1) SubStr(colorHex, 1, 1)
            . SubStr(colorHex, 2, 1) SubStr(colorHex, 2, 1)
            . SubStr(colorHex, 3, 1) SubStr(colorHex, 3, 1)
    }

    if (StrLen(colorHex) != 6)
        colorHex := fallback

    return StrUpper(colorHex)
}

GetContrastTextColor(colorHex) {
    colorValue := Integer("0x" colorHex)
    red := (colorValue >> 16) & 255
    green := (colorValue >> 8) & 255
    blue := colorValue & 255
    luminance := (red * 299 + green * 587 + blue * 114) // 1000
    return (luminance >= 150) ? "111111" : "FFFFFF"
}

GetLabelPreset(labelKey) {
    global g_LabelPresets
    normalizedKey := NormalizeLabelKey(labelKey)
    return g_LabelPresets[normalizedKey]
}

GetSlotLabelText(slot) {
    preset := GetLabelPreset(slot.labelKey)
    baseText := (slot.labelKey == "none") ? "[Click to Label]" : preset.name
    return AppendSlotAlias(baseText, slot.alias)
}

GetSlotBadgeText(slot) {
    preset := GetLabelPreset(slot.labelKey)
    baseText := (slot.labelKey == "none") ? "[" slot.id "] UNLABELED" : "[" slot.id "] " preset.short
    return AppendSlotAlias(baseText, slot.alias, " / ")
}

GetSlotHwnd(slot) {
    if (slot.value == 0 || slot.name == "Empty")
        return 0

    if (slot.type == "session")
        return WinExist("ahk_id " slot.value) ? slot.value : 0

    return WinExist("ahk_exe " slot.value)
}

GetSlotTarget(slot) {
    hwnd := GetSlotHwnd(slot)
    return hwnd ? "ahk_id " hwnd : ""
}

AppendSlotAlias(baseText, aliasText, separator := " - ") {
    aliasText := Trim(aliasText)
    return (aliasText == "") ? baseText : baseText separator aliasText
}

BuildShortLabel(name) {
    shortName := RegExReplace(StrUpper(name), "[^A-Z0-9]+")
    if (shortName == "")
        return "LABEL"
    return SubStr(shortName, 1, 8)
}

MakePresetKey(name) {
    key := Trim(StrLower(name))
    key := RegExReplace(key, "[^a-z0-9]+", "-")
    key := Trim(key, "-")
    return (key == "") ? "label" : key
}

CreateUniquePresetKey(name) {
    global g_LabelPresets
    baseKey := MakePresetKey(name)
    key := baseKey
    suffix := 2

    while g_LabelPresets.Has(key) {
        key := baseKey "-" suffix
        suffix += 1
    }

    return key
}

GetEditableLabelKeys() {
    global g_LabelOrder
    keys := []
    for _, key in g_LabelOrder {
        if (key != "none")
            keys.Push(key)
    }
    return keys
}

JoinArray(items, delimiter := "|") {
    output := ""
    for _, item in items {
        if (output != "")
            output .= delimiter
        output .= item
    }
    return output
}

RebuildLabelOrder() {
    global g_LabelPresets, g_LabelOrder
    g_LabelOrder := ["none"]
    for key, preset in g_LabelPresets {
        if (key != "none")
            g_LabelOrder.Push(key)
    }
}

CreateDashboard() {
    global g_DashboardGui, g_Slots, APP_NAME, MAX_SLOTS

    g_DashboardGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", APP_NAME)
    g_DashboardGui.BackColor := "0x101010"
    g_DashboardGui.MarginX := 10
    g_DashboardGui.MarginY := 10

    g_DashboardGui.SetFont("s11 c00f3ff", "Segoe UI")
    g_DashboardGui.Add("Text", "x20 y10 w500 h20", "Control Modules")
    btnPresets := g_DashboardGui.Add("Button", "x575 y8 w130 h26", "Edit Presets")
    btnPresets.OnEvent("Click", (*) => OpenPresetEditor())

    Loop MAX_SLOTS {
        index := A_Index
        yPos := 40 + ((index - 1) * 110)

        g_DashboardGui.Add("Text", "x10 y" yPos " w700 h1 Background0x00f3ff")
        g_DashboardGui.Add("Text", "x10 y" yPos + 105 " w700 h1 Background0x00f3ff")
        g_DashboardGui.Add("Text", "x10 y" yPos " w1 h105 Background0x00f3ff")
        g_DashboardGui.Add("Text", "x710 y" yPos " w1 h106 Background0x00f3ff")

        previewBox := g_DashboardGui.Add("Text", "x20 y" yPos + 8 " w140 h88 Background0x0a0a0a", "")
        g_Slots[index].PreviewBox := previewBox
        g_Slots[index].PreviewX := 20
        g_Slots[index].PreviewY := yPos + 8
        g_Slots[index].PreviewW := 140
        g_Slots[index].PreviewH := 88

        g_DashboardGui.SetFont("s28 Bold c00f3ff", "Segoe UI")
        g_DashboardGui.Add("Text", "x170 y" yPos + 8 " w40 Center Background0x101010", index)

        g_DashboardGui.SetFont("s10 cFFFFFF Norm", "Segoe UI")
        nameBg := g_DashboardGui.Add("Text", "x215 y" yPos + 8 " w345 h28 Background0x222222 +0x200", "")
        g_DashboardGui.SetFont("s10 Bold cFFFFFF", "Segoe UI")
        nameControl := g_DashboardGui.Add("Text", "x222 y" yPos + 8 " w330 h28 BackgroundTrans +0x200 vSlotName" index, "Empty Slot")
        nameControl.OnEvent("Click", ((i, *) => ActivateSlotFromDashboard(i)).Bind(index))
        g_Slots[index].GuiText := nameControl
        g_Slots[index].GuiTextBg := nameBg

        labelBg := g_DashboardGui.Add("Text", "x170 y" yPos + 40 " w260 h24 Background0x444444 +0x200", "")
        g_DashboardGui.SetFont("s10 Bold cFFFFFF", "Segoe UI")
        labelText := g_DashboardGui.Add("Text", "x180 y" yPos + 43 " w240 h18 BackgroundTrans +0x200", "")
        labelBg.OnEvent("Click", ((i, *) => CycleSlotLabel(i)).Bind(index))
        labelText.OnEvent("Click", ((i, *) => CycleSlotLabel(i)).Bind(index))
        g_Slots[index].GuiLabelBg := labelBg
        g_Slots[index].GuiLabelText := labelText

        g_DashboardGui.SetFont("s8 c7f8b94", "Segoe UI")
        g_DashboardGui.Add("Text", "x440 y" yPos + 26 " w190 h14 BackgroundTrans", "Alias distinguishes same-label windows")
        g_DashboardGui.SetFont("s9 cFFFFFF", "Segoe UI")
        g_DashboardGui.Add("Text", "x440 y" yPos + 46 " w34 h18 BackgroundTrans", "Alias")
        aliasEdit := g_DashboardGui.Add("Edit", "x478 y" yPos + 40 " w150 h24", g_Slots[index].alias)
        aliasEdit.OnEvent("Change", ((i, ctrl, *) => SetSlotAlias(i, ctrl.Text)).Bind(index))
        g_Slots[index].GuiAlias := aliasEdit

        g_Slots[index].GuiMonBtns := Map()
        MakeMonBtn(label, val, xOff) {
            g_DashboardGui.SetFont("s8 Bold cFFFFFF", "Segoe UI")
            btn := g_DashboardGui.Add("Text", "x" (594 + xOff) " y" yPos + 8 " w26 h26 Background0x333333 +0x200 Center", label)
            btn.OnEvent("Click", ((i, v, *) => SetMonitorPref(i, v)).Bind(index, val))
            return btn
        }
        g_Slots[index].GuiMonBtns[0] := MakeMonBtn("[A]", 0, 0)
        g_Slots[index].GuiMonBtns[1] := MakeMonBtn("[1]", 1, 28)
        g_Slots[index].GuiMonBtns[2] := MakeMonBtn("[2]", 2, 56)
        g_Slots[index].GuiMonBtns[99] := MakeMonBtn("[M]", 99, 84)

        g_DashboardGui.SetFont("s9 Bold cFFFFFF", "Segoe UI")
        btnSet := g_DashboardGui.Add("Button", "x170 y" yPos + 70 " w130 h26", "[+] SET TARGET")
        btnSet.OnEvent("Click", ((i, *) => StartCapture(i)).Bind(index))

        g_DashboardGui.SetFont("s9 cFFFFFF", "Segoe UI")
        g_DashboardGui.Add("Text", "x315 y" yPos + 74 " w45 h22 BackgroundTrans", "Opacity")
        slider := g_DashboardGui.Add("Slider", "x365 y" yPos + 70 " w115 h26 Range25-255 ToolTip", g_Slots[index].transparency)
        slider.OnEvent("Change", ((i, ctrl, *) => SetTransparency(i, ctrl.Value)).Bind(index))
        g_Slots[index].GuiSlider := slider

        g_DashboardGui.SetFont("s9 c00f3ff", "Segoe UI")
        chk := g_DashboardGui.Add("Checkbox", "x482 y" yPos + 72 " w88 h24 vChk" index, "Saved")
        chk.OnEvent("Click", ((i, *) => ToggleSave(i)).Bind(index))
        g_Slots[index].GuiCheck := chk

        g_DashboardGui.SetFont("s9 c00f3ff", "Segoe UI")
        maximizeChk := g_DashboardGui.Add("Checkbox", "x574 y" yPos + 72 " w58 h24", "Max")
        maximizeChk.OnEvent("Click", ((i, ctrl, *) => ToggleMaximize(i, ctrl.Value)).Bind(index))
        g_Slots[index].GuiMaxCheck := maximizeChk

        outlineChk := g_DashboardGui.Add("Checkbox", "x636 y" yPos + 72 " w68 h24", "Outline")
        outlineChk.OnEvent("Click", ((i, ctrl, *) => ToggleBorder(i, ctrl.Value)).Bind(index))
        g_Slots[index].GuiBorderCheck := outlineChk
    }

    g_DashboardGui.OnEvent("Close", (*) => (UnregisterAllThumbnails(), g_DashboardGui.Hide()))
    g_DashboardGui.OnEvent("Escape", (*) => (UnregisterAllThumbnails(), g_DashboardGui.Hide()))
    RefreshDashboard()
}

OpenPresetEditor() {
    global g_PresetEditorGui, g_PresetEditorRowKeys

    if IsObject(g_PresetEditorGui) {
        try g_PresetEditorGui.Destroy()
        g_PresetEditorGui := 0
    }

    g_PresetEditorRowKeys := GetEditableLabelKeys()
    rowCount := g_PresetEditorRowKeys.Length
    windowHeight := 140 + (rowCount * 42)
    if (windowHeight < 240)
        windowHeight := 240

    g_PresetEditorGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Edit Label Presets")
    g_PresetEditorGui.BackColor := "0x101010"
    g_PresetEditorGui.MarginX := 14
    g_PresetEditorGui.MarginY := 14

    g_PresetEditorGui.SetFont("s10 Bold c00f3ff", "Segoe UI")
    g_PresetEditorGui.Add("Text", "x14 y12 w110", "Preset")
    g_PresetEditorGui.Add("Text", "x140 y12 w250", "Label")
    g_PresetEditorGui.Add("Text", "x402 y12 w80", "Short")
    g_PresetEditorGui.Add("Text", "x494 y12 w90", "Color")
    g_PresetEditorGui.Add("Text", "x596 y12 w84", "Preview")
    g_PresetEditorGui.SetFont("s8 c7f8b94", "Segoe UI")
    g_PresetEditorGui.Add("Text", "x140 y28 w320 h14", "Use strong names and short tags for quick switching")

    Loop g_PresetEditorRowKeys.Length {
        key := g_PresetEditorRowKeys[A_Index]
        preset := GetLabelPreset(key)
        yPos := 44 + ((A_Index - 1) * 42)

        g_PresetEditorGui.SetFont("s9 Bold c" preset.color, "Segoe UI")
        g_PresetEditorGui.Add("Text", "x14 y" yPos + 4 " w110 h22", preset.key)

        g_PresetEditorGui.SetFont("s9 cFFFFFF", "Segoe UI")
        g_PresetEditorGui.Add("Edit", "x140 y" yPos " w250 h24 vPresetName_" key, preset.name)
        g_PresetEditorGui.Add("Edit", "x402 y" yPos " w80 h24 vPresetShort_" key, preset.short)
        g_PresetEditorGui.Add("Edit", "x494 y" yPos " w90 h24 vPresetColor_" key, "#" preset.color)
        previewBg := g_PresetEditorGui.Add("Text", "x596 y" yPos " w84 h24 Background0x" preset.color " +0x200", "")
        g_PresetEditorGui.SetFont("s8 Bold c" preset.textColor, "Segoe UI")
        g_PresetEditorGui.Add("Text", "x600 y" yPos + 4 " w76 h16 BackgroundTrans +0x200 Center", preset.short)
    }

    footerY := 58 + (rowCount * 42)
    btnAdd := g_PresetEditorGui.Add("Button", "x14 y" footerY " w110 h28", "Add Label")
    btnSave := g_PresetEditorGui.Add("Button", "x402 y" footerY " w110 h28", "Save")
    btnCancel := g_PresetEditorGui.Add("Button", "x524 y" footerY " w110 h28", "Cancel")
    btnAdd.OnEvent("Click", (*) => OpenNewPresetDialog())
    btnSave.OnEvent("Click", (*) => SavePresetEditor())
    btnCancel.OnEvent("Click", (*) => ClosePresetEditor())
    g_PresetEditorGui.OnEvent("Close", (*) => ClosePresetEditor())
    g_PresetEditorGui.Show("w700 h" windowHeight)
}

SavePresetEditor() {
    global g_PresetEditorGui, g_PresetEditorRowKeys, g_LabelPresets
    updatedPresets := Map()
    updatedPresets["none"] := g_LabelPresets["none"]

    for _, key in g_PresetEditorRowKeys {
        currentPreset := GetLabelPreset(key)
        nameValue := Trim(g_PresetEditorGui["PresetName_" key].Text)
        shortValue := Trim(g_PresetEditorGui["PresetShort_" key].Text)
        colorValue := Trim(g_PresetEditorGui["PresetColor_" key].Text)

        if (nameValue == "")
            nameValue := currentPreset.name
        if (shortValue == "")
            shortValue := currentPreset.short

        normalizedColor := NormalizeColorHex(colorValue, currentPreset.color)
        updatedPresets[key] := {
            key: key,
            name: nameValue,
            short: StrUpper(shortValue),
            color: normalizedColor,
            textColor: GetContrastTextColor(normalizedColor)
        }
    }

    g_LabelPresets := updatedPresets
    RebuildLabelOrder()
    SavePresetSettings()
    RefreshPresetVisuals()
    ClosePresetEditor()
}

OpenNewPresetDialog() {
    global g_NewPresetGui

    if IsObject(g_NewPresetGui) {
        try g_NewPresetGui.Destroy()
        g_NewPresetGui := 0
    }

    g_NewPresetGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Add Label Preset")
    g_NewPresetGui.BackColor := "0x101010"
    g_NewPresetGui.MarginX := 14
    g_NewPresetGui.MarginY := 14

    g_NewPresetGui.SetFont("s10 Bold c00f3ff", "Segoe UI")
    g_NewPresetGui.Add("Text", "x14 y14 w90", "Label")
    g_NewPresetGui.Add("Text", "x14 y52 w90", "Short")
    g_NewPresetGui.Add("Text", "x14 y90 w90", "Color")

    g_NewPresetGui.SetFont("s9 cFFFFFF", "Segoe UI")
    g_NewPresetGui.Add("Edit", "x110 y10 w240 h24 vNewPresetName", "")
    g_NewPresetGui.Add("Edit", "x110 y48 w120 h24 vNewPresetShort", "")
    g_NewPresetGui.Add("Edit", "x110 y86 w120 h24 vNewPresetColor", "#5A7FFF")

    btnSave := g_NewPresetGui.Add("Button", "x154 y130 w90 h28", "Create")
    btnCancel := g_NewPresetGui.Add("Button", "x254 y130 w90 h28", "Cancel")
    btnSave.OnEvent("Click", (*) => SaveNewPresetDialog())
    btnCancel.OnEvent("Click", (*) => CloseNewPresetDialog())
    g_NewPresetGui.OnEvent("Close", (*) => CloseNewPresetDialog())
    g_NewPresetGui.Show("w370 h175")
}

SaveNewPresetDialog() {
    global g_NewPresetGui
    nameValue := Trim(g_NewPresetGui["NewPresetName"].Text)
    shortValue := Trim(g_NewPresetGui["NewPresetShort"].Text)
    colorValue := Trim(g_NewPresetGui["NewPresetColor"].Text)

    if (nameValue == "") {
        MsgBox("Label name is required.")
        return
    }

    key := CreateUniquePresetKey(nameValue)
    SetLabelPreset(key, nameValue, shortValue, colorValue)
    RebuildLabelOrder()
    SavePresetSettings()
    CloseNewPresetDialog()
    RefreshPresetVisuals()
    OpenPresetEditor()
}

CloseNewPresetDialog() {
    global g_NewPresetGui
    if IsObject(g_NewPresetGui) {
        try g_NewPresetGui.Destroy()
        g_NewPresetGui := 0
    }
}

ClosePresetEditor() {
    global g_PresetEditorGui
    if IsObject(g_PresetEditorGui) {
        try g_PresetEditorGui.Destroy()
        g_PresetEditorGui := 0
    }
}

RefreshPresetVisuals() {
    RefreshDashboard()
    UpdateAllBadges()
}

ToggleDashboard() {
    global g_DashboardGui
    if WinActive("ahk_id " g_DashboardGui.Hwnd) {
        g_DashboardGui.Hide()
        UnregisterAllThumbnails()
    } else {
        g_DashboardGui.Show("w725 AutoSize")
        ValidateAllWindows()
        RefreshAllThumbnails()
    }
}

UpdateDashboardSlot(index) {
    global g_Slots
    slot := g_Slots[index]

    slot.GuiText.Text := (slot.name == "Empty") ? "--- Empty Slot ---" : slot.name

    if (slot.name == "Empty") {
        slot.GuiText.Opt("c666666")
        slot.GuiTextBg.Opt("Background0x222222")
    } else {
        slot.GuiText.Opt("cFFFFFF")
        slot.GuiTextBg.Opt("Background0x333333")
    }

    slot.GuiCheck.Value := slot.saved
    if (slot.GuiMaxCheck)
        slot.GuiMaxCheck.Value := slot.maximize
    if (slot.GuiBorderCheck)
        slot.GuiBorderCheck.Value := slot.borderEnabled

    preset := GetLabelPreset(slot.labelKey)
    slot.GuiLabelBg.Opt("Background0x" preset.color)
    slot.GuiLabelText.Opt("c" preset.textColor)
    slot.GuiLabelText.Text := GetSlotLabelText(slot)

    if (slot.GuiAlias && slot.GuiAlias.Text != slot.alias)
        slot.GuiAlias.Text := slot.alias

    if (slot.GuiAlias) {
        if (slot.name == "Empty")
            slot.GuiAlias.Opt("Background0x1a1a1a c777777")
        else
            slot.GuiAlias.Opt("Background0x151515 cFFFFFF")
    }

    currentMon := slot.monitor
    if !slot.GuiMonBtns.Has(currentMon)
        currentMon := 0

    for val, ctrl in slot.GuiMonBtns {
        if (val == currentMon)
            ctrl.Opt("Background0x00f3ff c000000")
        else
            ctrl.Opt("Background0x333333 cAAAAAA")
    }

    if (slot.GuiSlider)
        slot.GuiSlider.Value := slot.transparency
}

RefreshDashboard() {
    global MAX_SLOTS
    Loop MAX_SLOTS
        UpdateDashboardSlot(A_Index)
    ValidateAllWindows()
    RefreshAllThumbnails()
}

CycleSlotLabel(index) {
    global g_Slots, g_LabelOrder
    slot := g_Slots[index]
    currentPos := 1

    Loop g_LabelOrder.Length {
        if (g_LabelOrder[A_Index] == slot.labelKey) {
            currentPos := A_Index
            break
        }
    }

    nextPos := currentPos + 1
    if (nextPos > g_LabelOrder.Length)
        nextPos := 1

    slot.labelKey := g_LabelOrder[nextPos]
    UpdateDashboardSlot(index)
    SaveSlot(index)
    SyncSlotBadge(index)
}

SetMonitorPref(index, value) {
    global g_Slots
    g_Slots[index].monitor := value
    SaveSlot(index)
    UpdateDashboardSlot(index)
}

ToggleMaximize(index, enabled := "") {
    global g_Slots
    slot := g_Slots[index]
    slot.maximize := (enabled == "") ? !slot.maximize : !!enabled
    SaveSlot(index)
    UpdateDashboardSlot(index)
}

SetSlotAlias(index, aliasText) {
    global g_Slots
    g_Slots[index].alias := Trim(aliasText)
    SaveSlot(index)
    UpdateDashboardSlot(index)
    SyncSlotBadge(index)
}

ToggleBorder(index, enabled := "") {
    global g_Slots
    slot := g_Slots[index]
    slot.borderEnabled := (enabled == "") ? !slot.borderEnabled : !!enabled
    SaveSlot(index)
    UpdateDashboardSlot(index)
    SyncSlotBorder(index)
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

ActivateSlotFromDashboard(index) {
    global g_Slots, g_DashboardGui

    if (g_Slots[index].name == "Empty" || g_Slots[index].value == 0) {
        StartCapture(index)
        return
    }

    if ActivateSlot(index) {
        g_DashboardGui.Hide()
        ShowOverlay(index)
    } else {
        if (MsgBox("Window not found. Clear slot?", "Missing", "YesNo") == "Yes")
            ClearSlot(index)
    }
}

ClearSlot(index) {
    global g_Slots
    slot := g_Slots[index]

    if (slot.Thumb != 0) {
        UnregisterThumbnail(slot.Thumb)
        slot.Thumb := 0
    }

    DestroySlotBadge(index)
    DestroySlotBorder(index)
    slot.name := "Empty"
    slot.type := "session"
    slot.value := 0
    slot.saved := 0
    slot.monitor := 0
    slot.maximize := 0
    slot.transparency := 255
    slot.labelKey := "none"
    slot.alias := ""
    slot.borderEnabled := 0

    UpdateDashboardSlot(index)
    SaveSlot(index)
}

ValidateAllWindows() {
    global g_Slots, MAX_SLOTS
    Loop MAX_SLOTS {
        index := A_Index
        slot := g_Slots[index]
        if (slot.value != 0 && slot.name != "Empty") {
            exists := (slot.type == "session") ? WinExist("ahk_id " slot.value) : WinExist("ahk_exe " slot.value)
            if (!exists) {
                if (slot.Thumb != 0) {
                    UnregisterThumbnail(slot.Thumb)
                    slot.Thumb := 0
                }
                slot.GuiText.Opt("cff6666")
                slot.GuiTextBg.Opt("Background0x2a0000")
                HideSlotBadge(index)
                HideSlotBorder(index)
            }
        }
    }
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
    RegisterSlotThumbnail(index)
    SyncSlotBadge(index)
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
            HideSlotBadge(index)
            HideSlotBorder(index)
        }
    }

    SaveSlot(index)
}

CycleSlots(direction) {
    global g_CurrentSlotIndex, g_Slots, MAX_SLOTS
    loopCount := 0

    Loop {
        g_CurrentSlotIndex += direction

        if (g_CurrentSlotIndex > MAX_SLOTS)
            g_CurrentSlotIndex := 1
        if (g_CurrentSlotIndex < 1)
            g_CurrentSlotIndex := MAX_SLOTS

        loopCount += 1
        if (loopCount > MAX_SLOTS)
            return

        slot := g_Slots[g_CurrentSlotIndex]
        if (slot.value != 0) {
            if ActivateSlot(g_CurrentSlotIndex) {
                ShowOverlay(g_CurrentSlotIndex)
                return
            }
        }
    }
}

ActivateSlot(index) {
    if (ActivateSlotWithHelper(index))
        return true
    return ActivateSlotLegacy(index)
}

ActivateSlotWithHelper(index) {
    global g_Slots, SWITCHER_EXE
    slot := g_Slots[index]

    if !FileExist(SWITCHER_EXE)
        return false

    if (slot.value == 0 || slot.name == "Empty")
        return false

    monitorRect := GetSlotMonitorRectArg(slot)
    command := QuoteCommandArg(SWITCHER_EXE)
        . " activate"
        . " --slot-type " QuoteCommandArg(slot.type)
        . " --slot-value " QuoteCommandArg(slot.value)
        . " --monitor " QuoteCommandArg(slot.monitor)
        . " --maximize " QuoteCommandArg(slot.maximize)
        . " --transparency " QuoteCommandArg(slot.transparency)
    if (monitorRect != "")
        command .= " --monitor-rect " QuoteCommandArg(monitorRect)

    try exitCode := RunWait(command, A_ScriptDir, "Hide UseErrorLevel")
    catch {
        return false
    }

    if (exitCode = 0) {
        SyncSlotBadge(index)
        SyncSlotBorder(index)
        return true
    }

    return false
}

GetSlotMonitorRectArg(slot) {
    if (slot.monitor <= 0 || slot.monitor == 99)
        return ""

    try {
        MonitorGet(slot.monitor, &left, &top, &right, &bottom)
        return left "," top "," right "," bottom
    } catch {
        return ""
    }
}

QuoteCommandArg(value) {
    text := value . ""
    return Chr(34) text Chr(34)
}

ActivateSlotLegacy(index) {
    global g_Slots
    slot := g_Slots[index]
    target := GetSlotTarget(slot)

    if (target != "") {
        if (slot.monitor != 0) {
            targetMon := 0

            if (slot.monitor == 99) {
                MouseGetPos(&mx, &my)
                Loop MonitorGetCount() {
                    MonitorGet(A_Index, &L, &T, &R, &B)
                    if (mx >= L && mx < R && my >= T && my < B) {
                        targetMon := A_Index
                        break
                    }
                }
                if (targetMon == 0)
                    targetMon := MonitorGetPrimary()
            } else {
                targetMon := slot.monitor
            }

            if (targetMon > 0 && targetMon <= MonitorGetCount())
                WinMoveToMonitor(target, targetMon, slot.maximize)
        }

        WinActivate(target)
        ApplyTransparencyToSlot(index, target)
        SyncSlotBadge(index)
        return true
    }
    return false
}

WinMoveToMonitor(winTitle, monIndex, maximize := 0) {
    try {
        MonitorGet(monIndex, &mL, &mT, &mR, &mB)
        mW := mR - mL
        mH := mB - mT
        WinGetPos(&wX, &wY, &wW, &wH, winTitle)
        newX := mL + (mW - wW) // 2
        newY := mT + (mH - wH) // 2
        WinMove(newX, newY, , , winTitle)
        if (maximize)
            WinMaximize(winTitle)
    }
}

UpdateAllBadges(*) {
    global MAX_SLOTS
    Loop MAX_SLOTS {
        SyncSlotBadge(A_Index)
        SyncSlotBorder(A_Index)
    }
}

EnsureSlotBadge(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BadgeGui)
        return

    badgeGui := Gui("+AlwaysOnTop +ToolWindow +Disabled -Caption +E0x20", "SlotBadge" index)
    badgeGui.MarginX := 0
    badgeGui.MarginY := 0
    badgeGui.BackColor := "0x444444"
    badgeGui.SetFont("s10 Bold cFFFFFF", "Segoe UI")
    badgeText := badgeGui.Add("Text", "x0 y0 w220 h28 Center BackgroundTrans +0x200", "")

    slot.BadgeGui := badgeGui
    slot.BadgeText := badgeText
}

HideSlotBadge(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BadgeGui)
        slot.BadgeGui.Hide()
}

DestroySlotBadge(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BadgeGui) {
        try slot.BadgeGui.Destroy()
        slot.BadgeGui := 0
        slot.BadgeText := 0
    }
}

EnsureSlotBorder(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BorderGui)
        return

    borderGui := Gui("+AlwaysOnTop +ToolWindow +Disabled -Caption +E0x20", "SlotBorder" index)
    borderGui.MarginX := 0
    borderGui.MarginY := 0
    borderGui.BackColor := "0x000000"

    top := borderGui.Add("Text", "x0 y0 w10 h4 Background0xFFFFFF", "")
    bottom := borderGui.Add("Text", "x0 y6 w10 h4 Background0xFFFFFF", "")
    left := borderGui.Add("Text", "x0 y0 w4 h10 Background0xFFFFFF", "")
    right := borderGui.Add("Text", "x6 y0 w4 h10 Background0xFFFFFF", "")

    slot.BorderGui := borderGui
    slot.BorderTop := top
    slot.BorderBottom := bottom
    slot.BorderLeft := left
    slot.BorderRight := right
}

HideSlotBorder(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BorderGui)
        slot.BorderGui.Hide()
}

DestroySlotBorder(index) {
    global g_Slots
    slot := g_Slots[index]
    if IsObject(slot.BorderGui) {
        try slot.BorderGui.Destroy()
        slot.BorderGui := 0
        slot.BorderTop := 0
        slot.BorderBottom := 0
        slot.BorderLeft := 0
        slot.BorderRight := 0
    }
}

SyncSlotBorder(index) {
    global g_Slots
    slot := g_Slots[index]
    if (!slot.borderEnabled) {
        HideSlotBorder(index)
        return
    }

    hwnd := GetSlotHwnd(slot)
    if (!hwnd) {
        HideSlotBorder(index)
        return
    }

    try {
        if (WinGetMinMax("ahk_id " hwnd) == -1) {
            HideSlotBorder(index)
            return
        }
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
    } catch {
        HideSlotBorder(index)
        return
    }

    EnsureSlotBorder(index)

    preset := GetLabelPreset(slot.labelKey)
    thickness := 4
    guiW := winW + (thickness * 2)
    guiH := winH + (thickness * 2)

    slot.BorderTop.Opt("Background0x" preset.color)
    slot.BorderBottom.Opt("Background0x" preset.color)
    slot.BorderLeft.Opt("Background0x" preset.color)
    slot.BorderRight.Opt("Background0x" preset.color)

    slot.BorderTop.Move(0, 0, guiW, thickness)
    slot.BorderBottom.Move(0, guiH - thickness, guiW, thickness)
    slot.BorderLeft.Move(0, 0, thickness, guiH)
    slot.BorderRight.Move(guiW - thickness, 0, thickness, guiH)

    slot.BorderGui.Show("x" (winX - thickness) " y" (winY - thickness) " w" guiW " h" guiH " NoActivate")
    WinSetTransColor("0x000000", "ahk_id " slot.BorderGui.Hwnd)
    WinSetTransparent(235, "ahk_id " slot.BorderGui.Hwnd)
}

SyncSlotBadge(index) {
    global g_Slots
    slot := g_Slots[index]
    hwnd := GetSlotHwnd(slot)
    if (!hwnd) {
        HideSlotBadge(index)
        return
    }

    try {
        if (WinGetMinMax("ahk_id " hwnd) == -1) {
            HideSlotBadge(index)
            return
        }
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
    } catch {
        HideSlotBadge(index)
        return
    }

    EnsureSlotBadge(index)
    preset := GetLabelPreset(slot.labelKey)
    badgeText := GetSlotBadgeText(slot)
    badgeWidth := (StrLen(badgeText) > 20) ? 220 : ((StrLen(badgeText) > 14) ? 176 : 124)
    badgeHeight := 28
    badgeX := winX + 12
    badgeY := winY + 12

    slot.BadgeGui.BackColor := "0x" preset.color
    slot.BadgeText.Opt("c" preset.textColor)
    slot.BadgeText.Text := badgeText
    slot.BadgeGui.Show("x" badgeX " y" badgeY " w" badgeWidth " h" badgeHeight " NoActivate")
    WinSetTransparent(232, "ahk_id " slot.BadgeGui.Hwnd)
}

ShowOverlay(index) {
    global g_OverlayGui, g_Slots
    slot := g_Slots[index]
    preset := GetLabelPreset(slot.labelKey)

    if IsObject(g_OverlayGui) {
        try g_OverlayGui.Destroy()
        g_OverlayGui := 0
    }

    overlayGui := Gui("+AlwaysOnTop +ToolWindow +Disabled -Caption", "Overlay")
    overlayGui.BackColor := "0x101010"

    overlayGui.SetFont("s17 Bold c" preset.color, "Segoe UI")
    overlayGui.Add("Text", "x12 y13 w42 Center", "[" index "]")

    overlayGui.SetFont("s11 Bold c" preset.color, "Segoe UI")
    overlayGui.Add("Text", "x66 y10 w330 h18", GetSlotLabelText(slot))

    overlayGui.SetFont("s12 cFFFFFF", "Segoe UI")
    overlayBaseTitle := AppendSlotAlias(slot.name, slot.alias, " / ")
    overlayTitle := (StrLen(overlayBaseTitle) > 42) ? SubStr(overlayBaseTitle, 1, 39) "..." : overlayBaseTitle
    overlayGui.Add("Text", "x66 y31 w360", overlayTitle)

    MonitorGet(MonitorGetPrimary(), &l, &t, &r, &b)
    width := 460
    height := 72
    x := r - width - 20
    y := b - height - 60

    g_OverlayGui := overlayGui
    overlayGui.Show("x" x " y" y " w" width " h" height " NoActivate")
    WinSetRegion("0-0 w" width " h" height " R10-10", overlayGui.Hwnd)
    WinSetTransparent(230, "ahk_id " overlayGui.Hwnd)
    SetTimer(DestroyOverlay, -1500)
}

DestroyOverlay() {
    global g_OverlayGui
    if IsObject(g_OverlayGui) {
        g_OverlayGui.Destroy()
        g_OverlayGui := 0
    }
}

SetupTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Configure", (*) => ToggleDashboard())
    A_TrayMenu.Add("Edit Label Presets", (*) => OpenPresetEditor())
    A_TrayMenu.Add("Refresh Badges", (*) => UpdateAllBadges())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}
