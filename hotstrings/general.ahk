#Requires AutoHotkey v2.0
; ####################################################################
; # GENERAL TEXT EXPANSION HOTSTRINGS MODULE                         #
; # Note: Requires SendHotstringText() from core/environment.ahk    #
; ####################################################################

; --------------------------------------------------------------------
; Menus: list hotstrings / hotkeys
; --------------------------------------------------------------------
Hotstring(":*:ahk-hotstrings-list", (*) => ShowHotstringsMenu())

Hotstring(":*:ahk-hotkey-list", (*) => ShowHotkeysMenu())

Hotstring(":*:p1approval", (*) => SendHotstringText("Part 1 Approved - Uploaded the email to docs folder in drive. "))

GprompterText() {
    text := ""
    text .= "use the following command to offload some of your analysis.`n"
    dq := Chr(34)
    text .= "'gemini -p " . dq . "detailed prompt goes here:" . dq . " '`n"
    text .= "`n"
    text .= "- You can use this to analyze any part of the codebase; it's easiest if you manage the context extremely well.`n"
    text .= "- You can use this to ask questions or build context while devising a fix or implementing an update.`n"
    text .= "- You can use this to understand pieces of the codebase when implementing new features.`n"
    text .= "---`n"
    return text
}

Hotstring(":*:gprompter", (*) => SendHotstringText(GprompterText()))

CustcomText() {
    text := ""
    text .= "Contact:`n"
    text .= "Summary:`n"
    text .= "Next Steps:"
    return text
}

Hotstring(":*:custcom", (*) => SendHotstringText(CustcomText()))

AipromptText() {
    text := ""
    text .= "What are some good techniques for locating jobs using search engines. Specifically, what are some industry specific job boards for the solar industry? How can I find jobs immediately as soon as they are posted?"
    return text
}

Hotstring(":*:aiprompt", (*) => SendHotstringText(AipromptText()))

Hotstring(":*:xlcorr", (*) => SendHotstringText("8/26: Submitted more clear correction. "))

Hotstring(":*:windroid", (*) => SendHotstringText("C:\\Users\\prest\\bin\\droid.exe"))

Hotstring(":*:openeminicli", (*) => SendHotstringText("npx https://github.com/google-gemini/gemini-cli"))

Hotstring(":*:shpw", (*) => SendHotstringText("Shot7374"))

Hotstring(":*:ixreject", (*) => SendHotstringText("Interconnection Rejected: Other"))

; SECURITY: Replaced hardcoded password with environment variable
Hotstring(":*r:incopw", (*) => SendSecretFromEnv("INCO_PW", "Enter your INCO password"))

; --------------------------------------------------------------------
; Functions: Popup Menus
; --------------------------------------------------------------------
ShowHotstringsMenu() {
    HS := Gui("+AlwaysOnTop +Resize", "Hotstrings Directory")
    HS.Add("Text",, "Triggers (type any to expand)")
    LV := HS.Add("ListView", "w720 h420 Grid", ["Trigger", "Source", "Description"])
    ; API Keys
    LV.Add(, "Orouterkey", "api-keys.ahk", "OpenRouter API key (env)")
    LV.Add(, "hftoken", "api-keys.ahk", "HuggingFace token (env)")
    LV.Add(, "browserkeyuse", "api-keys.ahk", "Browser Use API key (env)")
    LV.Add(, "gittoken", "api-keys.ahk", "GitHub token (env)")
    LV.Add(, "arceekey", "api-keys.ahk", "Arcee API key (env)")
    LV.Add(, "perplexitykey", "api-keys.ahk", "Perplexity API key (env)")
    LV.Add(, "mem0key", "api-keys.ahk", "Mem0 API key (env)")
    LV.Add(, "npmtoken", "api-keys.ahk", "npm token (env)")
    LV.Add(, "geminikey", "api-keys.ahk", "Google AI Studio key (env)")
    LV.Add(, "openpipekey", "api-keys.ahk", "OpenPipe API key (env)")
    LV.Add(, "groqkey", "api-keys.ahk", "Groq API key (env)")
    LV.Add(, "OAIKey", "api-keys.ahk", "OpenAI primary key (env)")
    LV.Add(, "OAI2Key", "api-keys.ahk", "OpenAI secondary key (env)")
    LV.Add(, "ClaudeKey", "api-keys.ahk", "Anthropic key (env)")
    LV.Add(, "zaikey", "api-keys.ahk", "ZAI API key (env)")
    ; General
    LV.Add(, "p1approval", "general.ahk", "Interconnection template")
    LV.Add(, "gprompter", "general.ahk", "Gemini CLI helper text")
    LV.Add(, "custcom", "general.ahk", "Contact/Summary/Next Steps")
    LV.Add(, "aiprompt", "general.ahk", "Solar job search prompt")
    LV.Add(, "xlcorr", "general.ahk", "Spreadsheet correction log")
    LV.Add(, "windroid", "general.ahk", "Path: C:\\Users\\prest\\bin\\droid.exe")
    LV.Add(, "openeminicli", "general.ahk", "Gemini CLI command")
    LV.Add(, "shpw", "general.ahk", "Personal macro")
    LV.Add(, "ixreject", "general.ahk", "Interconnection rejection")
    LV.Add(, "incopw", "general.ahk", "Personal macro (r)")
    ; Templates
    LV.Add(, "sdframework", "templates.ahk", "Self-Discover framework")
    LV.Add(, "test-helper", "templates.ahk", "QA/Test helper meta-prompt")
    LV.Add(, "custcom", "templates.ahk", "Contact/Summary/Next Steps (large)")
    LV.Add(, "aiprompt", "templates.ahk", "Solar job search (large)")
    LV.Add(, "prioritization", "templates.ahk", "PRIORITIZATION_PROMPT")
    LV.Add(, "radical-ui", "templates.ahk", "UI/UX expert agent prompt")
    LV.Add(, "task-triage", "templates.ahk", "Task triage matrix & guidance")
    LV.Add(, "md-notes-cleanup", "templates.ahk", "Markdown Notes Cleanup agent")
    LV.ModifyCol()
    HS.Add("Button",, "Close").OnEvent("Click", (*) => HS.Destroy())
    HS.Show()
}

ShowHotkeysMenu() {
    HK := Gui("+AlwaysOnTop +Resize", "Hotkeys Directory")
    HK.Add("Text",, "Hotkeys (keyboard/mouse)")
    LV := HK.Add("ListView", "w720 h420 Grid", ["Hotkey", "Module", "Action"])
    ; Media
    LV.Add(, "^!WheelDown", "hotkeys/media.ahk", "Volume -10")
    LV.Add(, "^!WheelUp", "hotkeys/media.ahk", "Volume +10")
    LV.Add(, "^!MButton", "hotkeys/media.ahk", "Media Play/Pause")
    LV.Add(, "^!RButton", "hotkeys/media.ahk", "Next Track")
    LV.Add(, "^!LButton", "hotkeys/media.ahk", "Previous Track")
    LV.Add(, "!MButton", "hotkeys/media.ahk", "Alt+L (app-specific)")
    ; Windows
    LV.Add(, "^WheelDown", "hotkeys/windows.ahk", "Next Tab (activate window)")
    LV.Add(, "^WheelUp", "hotkeys/windows.ahk", "Prev Tab (activate window)")
    LV.Add(, "^+RButton", "hotkeys/windows.ahk", "Close Tab (Ctrl+W)")
    LV.Add(, "MButton (hold)", "hotkeys/windows.ahk", "Hold Ctrl+Win+Alt while pressed")
    LV.Add(, "!WheelDown", "hotkeys/windows.ahk", "Backspace")
    LV.Add(, "^SC029", "hotkeys/windows.ahk", "Enter")
    LV.Add(, "Home", "hotkeys/windows.ahk", "Exit app")
    ; Mouse
    LV.Add(, "XButton2", "hotkeys/mouse.ahk", "Enter")
    LV.Add(, "XButton1", "hotkeys/mouse.ahk", "Ctrl+Win+Space (emoji)")
    LV.Add(, "^RButton", "hotkeys/mouse.ahk", "Win+Tab (Task View)")
    LV.Add(, "^XButton1", "hotkeys/mouse.ahk", "Switch desktop left")
    LV.Add(, "^XButton2", "hotkeys/mouse.ahk", "Switch desktop right")
    LV.ModifyCol()
    HK.Add("Button",, "Close").OnEvent("Click", (*) => HK.Destroy())
    HK.Show()
}