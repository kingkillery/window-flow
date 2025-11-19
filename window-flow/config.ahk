; ===================================================================
; Window-Flow Agent Configuration
; Edit this file to add/remove/modify agents
; ===================================================================

; === AGENT DEFINITIONS ===
; Each agent requires:
; - name: Display name for the agent
; - icon: Emoji or symbol to display
; - processName: Windows executable name (case-sensitive)
; - category: Group for organization
; - shortcut: Optional keyboard shortcut reference

global AGENTS := Map(
    ; === DEVELOPMENT TOOLS ===
    "cursor", {
        name: "Cursor",
        icon: "⌨️",
        processName: "Cursor.exe",
        category: "Development",
        shortcut: "Alt+C"
    },
    "vscode", {
        name: "VS Code", 
        icon: "💻",
        processName: "Code.exe",
        category: "Development",
        shortcut: "Alt+V"
    },
    "terminal", {
        name: "Terminal",
        icon: "🖥️",
        processName: "WindowsTerminal.exe", 
        category: "Development",
        shortcut: "Alt+T"
    },
    "gitkraken", {
        name: "GitKraken",
        icon: "🔀",
        processName: "GitKraken.exe",
        category: "Development",
        shortcut: "Alt+G"
    },
    
    ; === BROWSING ===
    "browser", {
        name: "Browser",
        icon: "🌐",
        processName: "chrome.exe",  ; Change to arc.exe, firefox.exe, etc.
        category: "Browsing", 
        shortcut: "Alt+B"
    },
    "edge", {
        name: "Edge",
        icon: "🌊",
        processName: "msedge.exe",
        category: "Browsing",
        shortcut: "Alt+E"
    },
    
    ; === COMMUNICATION ===
    "slack", {
        name: "Slack",
        icon: "💬",
        processName: "Slack.exe",
        category: "Communication",
        shortcut: "Alt+L"
    },
    "discord", {
        name: "Discord",
        icon: "🎮",
        processName: "Discord.exe",
        category: "Communication",
        shortcut: "Alt+D"
    },
    "zoom", {
        name: "Zoom",
        icon: "📹",
        processName: "zoom.exe",
        category: "Communication", 
        shortcut: "Alt+Z"
    },
    
    ; === MEDIA ===
    "spotify", {
        name: "Spotify",
        icon: "🎵",
        processName: "Spotify.exe",
        category: "Media",
        shortcut: "Alt+S"
    },
    "vlc", {
        name: "VLC",
        icon: "🎬",
        processName: "vlc.exe",
        category: "Media",
        shortcut: "Alt+M"
    },
    
    ; === PRODUCTIVITY ===
    "notion", {
        name: "Notion",
        icon: "📝",
        processName: "Notion.exe",
        category: "Productivity",
        shortcut: "Alt+N"
    },
    "obsidian", {
        name: "Obsidian",
        icon: "💎",
        processName: "Obsidian.exe",
        category: "Productivity",
        shortcut: "Alt+O"
    },
    "figma", {
        name: "Figma",
        icon: "🎨",
        processName: "Figma.exe",
        category: "Productivity",
        shortcut: "Alt+F"
    }
)

; === HOTKEY CONFIGURATION ===
; Customize global hotkeys here
global TOGGLE_HOTKEY := "^!Space"        ; Ctrl+Alt+Space to toggle UI
global WHEEL_MODIFIER := "^!Alt"         ; Ctrl+Alt+Wheel for navigation  
global ACTIVATE_KEY := "Enter"           ; Enter to activate selected window
global DISMISS_KEYS := ["Esc", "Space"]  ; Keys to dismiss UI

; === UI APPEARANCE ===
; Customize colors and styling
global UI_BG_COLOR := "0x0a0a0a"         ; Dark background color
global SELECTED_COLOR := "0x00f3ff"      ; Neon blue selection
global HOVER_COLOR := "0x1a1a1a"         ; Hover state color
global TEXT_COLOR := "0xffffff"          ; White text
global BORDER_COLOR := "0x333333"        ; Border color

; === BEHAVIOR SETTINGS ===
global AUTO_LAUNCH_MISSING := false      ; Try to launch apps if not found
global MOVE_TO_PRIMARY := true           ; Move activated windows to primary monitor
global SHOW_TRAY_TIPS := true            ; Show notification tips
global THROTTLE_WHEEL := 150             ; Mouse wheel throttle in milliseconds
