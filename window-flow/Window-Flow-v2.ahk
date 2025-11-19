#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Window-Flow Native AHK v2 Implementation
; High-performance window switching application with native UI
; 
; Requirements: AutoHotkey v2.0+
; Target: Windows 10/11
; Architecture: Native tray application with full-screen overlay
; ===================================================================

; === LOAD CONFIGURATION ===
#Include config.ahk

; === APPLICATION STATE ===
global g_uiVisible := false
global g_selectedIndex := 0
global g_mainGui := ""
global g_agentButtons := []
global g_primaryMonitor := {}
global g_lastWheelTime := 0

; === TRAY SETUP ===
SetupTray() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show Window Flow", (*) => ShowUI())
    A_TrayMenu.Add("Hide Window Flow", (*) => HideUI()) 
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("Reload Config", (*) => ReloadConfig())
    A_TrayMenu.Add("Edit Config", (*) => EditConfig())
    A_TrayMenu.Add()  ; Separator
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.Default := "Show Window Flow"
    A_TrayMenu.ClickCount := 1

    ; Set tray icon and tooltip
    if FileExist("icon.ico")
        A_Icon := "icon.ico"
    A_IconTip := "Window-Flow - Press " TOGGLE_HOTKEY " to activate"
}

; === INITIALIZATION ===
InitializeApp() {
    DetectHiddenWindows(true)
    SetWinDelay(0)
    SetControlDelay(0)
    SendMode("Event")  ; More reliable for window activation
    
    ; Get primary monitor dimensions
    g_primaryMonitor := GetPrimaryMonitor()
    
    ; Register global hotkeys
    RegisterHotkeys()
    
    ; Create main GUI (hidden initially)
    CreateMainGUI()
    
    ; Show startup notification
    if SHOW_TRAY_TIPS {
        TrayTip("Window-Flow", "Ready! Press " TOGGLE_HOTKEY " to activate", 1, 1)
    }
}

; === HOTKEY REGISTRATION ===
RegisterHotkeys() {
    ; Toggle UI hotkey
    Hotkey(TOGGLE_HOTKEY, (*) => ToggleUI())
    
    ; Mouse wheel navigation with throttling
    Hotkey(WHEEL_MODIFIER "WheelUp", (*) => NavigateAgents(-1))
    Hotkey(WHEEL_MODIFIER "WheelDown", (*) => NavigateAgents(1))
    
    ; Activation key when UI is visible
    Hotkey(ACTIVATE_KEY, (*) => ActivateSelectedAgent())
    
    ; Individual agent hotkeys
    RegisterAgentHotkeys()
}

RegisterAgentHotkeys() {
    for agentId, agentData in AGENTS {
        if agentData.HasProp("shortcut") && agentData.shortcut != "" {
            hotkeyFunc := (*) => ActivateAgent(agentId)
            Hotkey(agentData.shortcut, hotkeyFunc)
        }
    }
}

; === PRIMARY MONITOR DETECTION ===
GetPrimaryMonitor() {
    ; Get monitor work area (excluding taskbar)
    monitorInfo := MonitorGet(1)  ; Monitor 1 is primary
    return {
        left: monitorInfo.Left,
        top: monitorInfo.Top, 
        right: monitorInfo.Right,
        bottom: monitorInfo.Bottom,
        width: monitorInfo.Right - monitorInfo.Left,
        height: monitorInfo.Bottom - monitorInfo.Top
    }
}

; === MAIN GUI CREATION ===
CreateMainGUI() {
    g_mainGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox +LastFound +OwnDialogs", "Window-Flow")
    g_mainGui.BackColor := UI_BG_COLOR
    g_mainGui.SetFont("s14 c" TEXT_COLOR, "Segoe UI")
    
    ; Set GUI properties
    g_mainGui.OnEvent("Close", (*) => HideUI())
    g_mainGui.OnEvent("Escape", (*) => HideUI())
    
    ; Set full screen on primary monitor
    g_mainGui.Show("x" g_primaryMonitor.left " y" g_primaryMonitor.top " w" g_primaryMonitor.width " h" g_primaryMonitor.height " Hide")
    
    ; Create transparent overlay for click-outside detection
    overlay := g_mainGui.Add("Text", "x0 y0 w" g_primaryMonitor.width " h" g_primaryMonitor.height " BackgroundTrans")
    overlay.OnEvent("Click", (*) => HideUI())
    
    ; Create agent grid
    CreateAgentGrid()
    
    ; Add keyboard navigation
    g_mainGui.OnEvent("KeyDown", OnGuiKeyDown)
}

; === AGENT GRID CREATION ===
CreateAgentGrid() {
    ; Clear existing buttons
    for btn in g_agentButtons {
        btn.Delete()
    }
    g_agentButtons := []
    
    ; Calculate grid layout
    agentCount := AGENTS.Count
    if agentCount = 0 {
        g_mainGui.Add("Text", "x0 y0 Center c" TEXT_COLOR, "No agents configured. Edit config.ahk to add agents.")
        return
    }
    
    cols := Ceil(Sqrt(agentCount))
    rows := Ceil(agentCount / cols)
    
    ; Button dimensions
    btnWidth := 220
    btnHeight := 140
    padding := 30
    
    ; Calculate starting position to center the grid
    totalWidth := (cols * btnWidth) + ((cols - 1) * padding)
    totalHeight := (rows * btnHeight) + ((rows - 1) * padding)
    
    startX := (g_primaryMonitor.width - totalWidth) // 2
    startY := (g_primaryMonitor.height - totalHeight) // 2
    
    ; Create buttons for each agent
    index := 0
    for agentId, agentData in AGENTS {
        row := index // cols
        col := Mod(index, cols)
        
        x := startX + (col * (btnWidth + padding))
        y := startY + (row * (btnHeight + padding))
        
        ; Create button with agent info
        btn := g_mainGui.Add("Button", 
            "x" x " y" y " w" btnWidth " h" btnHeight " +0x200000 +Center",  ; BS_MULTILINE
            agentData.icon "`n" agentData.name "`n" agentData.category
        )
        
        ; Store agent info with button
        btn.AgentId := agentId
        btn.AgentIndex := index
        
        ; Set button styling
        btn.SetFont("s20 bold")
        btn.Opt("Background" UI_BG_COLOR " c" TEXT_COLOR)
        
        ; Add event handlers
        btn.OnEvent("Click", (*) => OnAgentClick(agentId))
        btn.OnEvent("Focus", (*) => OnAgentHover(index))
        
        g_agentButtons.Push(btn)
        index++
    }
    
    ; Highlight first agent by default
    UpdateSelection(0)
}

; === KEYBOARD HANDLING ===
OnGuiKeyDown(Gui, Key, ShiftCtrlAlt) {
    if Key = "Esc" {
        HideUI()
    } else if Key = "Enter" {
        ActivateSelectedAgent()
    } else if Key = "Up" {
        NavigateAgents(-1)
    } else if Key = "Down" {
        NavigateAgents(1)
    } else if Key = "Left" {
        NavigateAgents(-1)
    } else if Key = "Right" {
        NavigateAgents(1)
    }
}

; === UI VISIBILITY CONTROL ===
ToggleUI() {
    if g_uiVisible {
        HideUI()
    } else {
        ShowUI()
    }
}

ShowUI() {
    if !g_uiVisible {
        g_uiVisible := true
        g_mainGui.Show("Activate")
        WinSetAlwaysOnTop(true, g_mainGui)
        UpdateSelection(g_selectedIndex)
        
        ; Focus the GUI for keyboard input
        WinActivate(g_mainGui)
    }
}

HideUI() {
    if g_uiVisible {
        g_uiVisible := false
        g_mainGui.Hide()
    }
}

; === AGENT NAVIGATION ===
NavigateAgents(direction) {
    ; Throttle wheel events
    currentTime := A_TickCount
    if (currentTime - g_lastWheelTime) < THROTTLE_WHEEL {
        return
    }
    g_lastWheelTime := currentTime
    
    if !g_uiVisible {
        ShowUI()
    }
    
    newIndex := g_selectedIndex + direction
    if newIndex < 0
        newIndex := g_agentButtons.Length - 1
    if newIndex >= g_agentButtons.Length
        newIndex := 0
        
    UpdateSelection(newIndex)
}

UpdateSelection(newIndex) {
    ; Reset all buttons to normal state
    for i, btn in g_agentButtons {
        btn.Opt("Background" UI_BG_COLOR)
        btn.SetFont("s20 bold c" TEXT_COLOR)
    }
    
    ; Highlight selected button
    if g_agentButtons.Has(newIndex + 1) {  ; AHK arrays are 1-based
        selectedBtn := g_agentButtons[newIndex + 1]
        selectedBtn.Opt("Background" SELECTED_COLOR)
        selectedBtn.SetFont("s20 bold c" UI_BG_COLOR)
        g_selectedIndex := newIndex
    }
}

; === AGENT INTERACTION ===
OnAgentClick(agentId) {
    ActivateAgent(agentId)
    HideUI()
}

OnAgentHover(index) {
    if g_uiVisible {
        UpdateSelection(index)
    }
}

ActivateSelectedAgent() {
    if g_uiVisible && g_agentButtons.Has(g_selectedIndex + 1) {
        btn := g_agentButtons[g_selectedIndex + 1]
        ActivateAgent(btn.AgentId)
        HideUI()
    }
}

; === WINDOW ACTIVATION ===
ActivateAgent(agentId) {
    if !AGENTS.Has(agentId) {
        MsgBox("Agent not found: " agentId, "Error", "Icon!")
        return
    }
    
    agent := AGENTS[agentId]
    processName := agent.processName
    
    ; Try to find and activate the window
    if WinExist("ahk_exe " processName) {
        ; Activate the window
        WinActivate("ahk_exe " processName)
        
        ; Ensure window is on primary monitor if configured
        if MOVE_TO_PRIMARY {
            WinMove(g_primaryMonitor.left, g_primaryMonitor.top, , , "ahk_exe " processName)
        }
        
        ; Log successful activation
        if SHOW_TRAY_TIPS {
            TrayTip("Window-Flow", "Activated " agent.name, 1, 1)
        }
    } else {
        ; Window not found
        msg := agent.name " not found. Please launch it first."
        if AUTO_LAUNCH_MISSING {
            msg .= " Auto-launch feature not implemented yet."
        }
        
        if SHOW_TRAY_TIPS {
            TrayTip("Window-Flow", msg, 2, 2)
        }
    }
}

; === CONFIGURATION MANAGEMENT ===
ReloadConfig() {
    ; Reload the configuration file
    try {
        #Include *i config.ahk  ; *i prevents error if file doesn't exist
        
        ; Recreate the agent grid with new configuration
        if g_mainGui {
            CreateAgentGrid()
        }
        
        ; Re-register hotkeys
        RegisterHotkeys()
        
        if SHOW_TRAY_TIPS {
            TrayTip("Window-Flow", "Configuration reloaded", 1, 1)
        }
    } catch as e {
        MsgBox("Failed to reload configuration: " e.message, "Error", "Icon!")
    }
}

EditConfig() {
    ; Open config file in default editor
    if FileExist("config.ahk") {
        Run("config.ahk")
    } else {
        MsgBox("Configuration file not found: config.ahk", "Error", "Icon!")
    }
}

; === GLOBAL KEYBOARD SHORTCUTS ===
#HotIf g_uiVisible
Esc::HideUI()
Space::HideUI()
Up::NavigateAgents(-1)
Down::NavigateAgents(1)
Left::NavigateAgents(-1)
Right::NavigateAgents(1)
#HotIf

; === STARTUP ===
SetupTray()
InitializeApp()

; === CLEANUP ===
OnExit(ExitApp)
