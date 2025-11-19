#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================================
; Window-Flow Native AHK v2 Implementation
; High-performance window switching application with native UI
; ===================================================================

; === GLOBAL CONFIGURATION ===
global TOGGLE_HOTKEY := "^!Space"        ; Ctrl+Alt+Space to toggle UI
global WHEEL_MODIFIER := "^!Alt"         ; Ctrl+Alt+Wheel for navigation  
global ACTIVATE_KEY := "Enter"           ; Enter to activate selected window
global DISMISS_KEYS := ["Esc", "Space"]  ; Keys to dismiss UI
global UI_BG_COLOR := "0x0a0a0a"         ; Dark background color
global SELECTED_COLOR := "0x00f3ff"      ; Neon blue selection
global HOVER_COLOR := "0x1a1a1a"         ; Hover state color
global TEXT_COLOR := "0xffffff"          ; White text
global BORDER_COLOR := "0x333333"        ; Border color

; === AGENT DEFINITIONS ===
; Configure your applications here. Add/remove agents as needed.
global AGENTS := Map(
    "cursor", {
        name: "Cursor",
        icon: "⌨️",
        processName: "Cursor.exe",
        category: "Development",
        shortcut: "Alt+C"
    },
    "browser", {
        name: "Browser", 
        icon: "🌐",
        processName: "chrome.exe",
        category: "Browsing",
        shortcut: "Alt+B"
    },
    "terminal", {
        name: "Terminal",
        icon: "💻", 
        processName: "WindowsTerminal.exe",
        category: "Development",
        shortcut: "Alt+T"
    },
    "spotify", {
        name: "Spotify",
        icon: "🎵",
        processName: "Spotify.exe", 
        category: "Media",
        shortcut: "Alt+S"
    },
    "slack", {
        name: "Slack",
        icon: "💬",
        processName: "Slack.exe",
        category: "Social", 
        shortcut: "Alt+L"
    }
)

; === APPLICATION STATE ===
global g_uiVisible := false
global g_selectedIndex := 0
global g_mainGui := ""
global g_agentButtons := []
global g_primaryMonitor := {}

; === TRAY SETUP ===
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Window Flow", (*) => ShowUI())
A_TrayMenu.Add("Hide Window Flow", (*) => HideUI()) 
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show Window Flow"
A_TrayMenu.ClickCount := 1

; Set tray icon and tooltip
if FileExists("icon.ico")
    A_Icon := "icon.ico"
A_IconTip := "Window-Flow - Press " TOGGLE_HOTKEY " to activate"

; === INITIALIZATION ===
InitializeApp() {
    DetectHiddenWindows(true)
    SetWinDelay(0)
    SetControlDelay(0
    
    ; Get primary monitor dimensions
    g_primaryMonitor := GetPrimaryMonitor()
    
    ; Register global hotkeys
    RegisterHotkeys()
    
    ; Create main GUI (hidden initially)
    CreateMainGUI()
}

; === HOTKEY REGISTRATION ===
RegisterHotkeys() {
    ; Toggle UI hotkey
    Hotkey(TOGGLE_HOTKEY, (*) => ToggleUI())
    
    ; Mouse wheel navigation
    Hotkey(WHEEL_MODIFIER "WheelUp", (*) => NavigateAgents(-1))
    Hotkey(WHEEL_MODIFIER "WheelDown", (*) => NavigateAgents(1))
    
    ; Activation key when UI is visible
    Hotkey(ACTIVATE_KEY, (*) => ActivateSelectedAgent())
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
    g_mainGui := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox +LastFound", "Window-Flow")
    g_mainGui.BackColor := UI_BG_COLOR
    g_mainGui.SetFont("s14 c" TEXT_COLOR, "Segoe UI")
    
    ; Make GUI click-through to dismiss
    g_mainGui.OnEvent("Close", (*) => HideUI())
    
    ; Set full screen on primary monitor
    g_mainGui.Show("x" g_primaryMonitor.left " y" g_primaryMonitor.top " w" g_primaryMonitor.width " h" g_primaryMonitor.height " Hide")
    
    ; Create transparent overlay for click-outside detection
    g_mainGui.Add("Text", "x0 y0 w" g_primaryMonitor.width " h" g_primaryMonitor.height " BackgroundTrans")
    
    ; Create agent grid
    CreateAgentGrid()
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
    cols := Ceil(Sqrt(agentCount))
    rows := Ceil(agentCount / cols)
    
    ; Button dimensions
    btnWidth := 200
    btnHeight := 120
    padding := 20
    
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
            "x" x " y" y " w" btnWidth " h" btnHeight " +0x200000",  ; BS_MULTILINE
            agentData.icon "`n" agentData.name "`n" agentData.category
        )
        
        ; Store agent info with button
        btn.AgentId := agentId
        btn.AgentIndex := index
        
        ; Set button styling
        btn.SetFont("s18 bold")
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
        btn.SetFont("s18 bold c" TEXT_COLOR)
    }
    
    ; Highlight selected button
    if g_agentButtons.Has(newIndex) {
        selectedBtn := g_agentButtons[newIndex + 1]  ; AHK arrays are 1-based
        selectedBtn.Opt("Background" SELECTED_COLOR)
        selectedBtn.SetFont("s18 bold c" UI_BG_COLOR)
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
        WinActivate()
        
        ; Ensure window is on primary monitor
        WinMove(g_primaryMonitor.left, g_primaryMonitor.top, , , "ahk_exe " processName)
        
        ; Log successful activation
        TrayTip("Window-Flow", "Activated " agent.name, 1, 1)
    } else {
        ; Window not found - try to launch the application
        TrayTip("Window-Flow", agent.name " not found. Please launch it first.", 2, 2)
    }
}

; === KEYBOARD HANDLING ===
#HotIf g_uiVisible
Esc::HideUI()
Space::HideUI()
#HotIf

; === STARTUP ===
InitializeApp()

; === CLEANUP ===
OnExit(ExitApp)
