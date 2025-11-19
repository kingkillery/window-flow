# Template.ahk System Map
**Entry Point:** `Template.ahk`  
**Version:** 2.0 - Modular (2025-10-30)

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Function Inventory](#function-inventory)
3. [Module Dependencies](#module-dependencies)
4. [Interaction Diagram](#interaction-diagram)

---

## Architecture Overview

Template.ahk is a modular AutoHotkey v2 script that orchestrates:
- **Hotkey/Hotstring Management** - Text expansion and keyboard shortcuts
- **PromptOpt Integration** - AI-powered prompt optimization via OpenRouter/OpenAI
- **Raw-to-Prompt Tool** - Python-based text processing
- **Clipboard Management** - Enhanced clipboard operations
- **Environment Configuration** - .env file loading and secret management

---

## Function Inventory

### **Template.ahk** (Main Entry Point)
Location: `C:\Users\prest\Desktop\Others\Scripts\Template.ahk`

#### Configuration Functions
| Function | Line | Description |
|----------|------|-------------|
| `LoadDotEnv()` | 12 | Loads environment variables from .env file |
| `EnvSet(key, value)` | 913 | Sets environment variable for current process |

#### PromptOpt Functions
| Function | Line | Description |
|----------|------|-------------|
| `PromptOpt_Run()` | 203 | Main entry point for PromptOpt functionality |
| `TryRunWithAHKv2(script)` | 629 | Attempts to run script with AutoHotkey v2 |
| `RunPromptOptFallback(scriptDir)` | 648 | Fallback for running PromptOpt when AHK v2 unavailable |
| `BuildPromptOptCommand(...)` | 456 | Builds PowerShell command string for PromptOpt execution |
| `HandlePromptOptOutput(tempOut, ClipSaved)` | 698 | Reads PromptOpt output and shows result |
| `ShowPromptOptWindow(text)` | 409 | Shows PromptOpt result window with GUI |
| `PO_CopySection()` | 420 | Copies result to clipboard |
| `PO_CloseSection()` | 427 | Closes result window |
| `PO_SaveSection()` | 432 | Saves result to file |
| `PO_OpenSection()` | 446 | Opens result in Notepad |

#### PK_PROMPT Automation Functions
| Function | Line | Description |
|----------|------|-------------|
| `PK_HotstringLaunch()` | 477 | Handles PK_PROMPT hotstring trigger |
| `PK_HandleQuadQuestionHotstring(endChar)` | 510 | Handles ???? trigger to optimize entire field |
| `PK_ShowPromptOptMenu()` | 529 | Shows PromptOpt context menu |
| `PK_ShowPromptOptHelp()` | 552 | Shows comprehensive help for PromptOpt |
| `PK_HandleClipboard(Type)` | 731 | Monitors clipboard for PK_PROMPT prefix |
| `PK_RunPromptOpt(promptText)` | 774 | Executes PromptOpt workflow on provided text |
| `PK_WaitAndProcessResult(...)` | 816 | Monitors for PromptOpt completion |
| `PK_RunFallback(...)` | 838 | Direct PowerShell fallback when AHK v2 unavailable |
| `PK_ProcessResult(...)` | 869 | Handles PromptOpt output and pastes optimized prompt |
| `PK_CopyEntireFieldText(timeoutMs)` | 221 | Copies entire active control content safely |
| `PK_MenuOptimizeSelection()` | 249 | Menu handler: optimize selected text |
| `PK_MenuOptimizeField()` | 258 | Menu handler: optimize entire field |
| `PK_MenuOptimizeClipboard()` | 267 | Menu handler: optimize clipboard content |
| `PK_MenuCancel()` | 275 | Menu handler: cancel operation |
| `PK_MenuShowHelp()` | 279 | Menu handler: show help |

#### Clipboard Management Functions
| Function | Line | Description |
|----------|------|-------------|
| `FlattenClipboard()` | 288 | Flattens clipboard to single line |

#### Utility Functions
| Function | Line | Description |
|----------|------|-------------|
| `ShowTip(msg, durationMs, x, y)` | 307 | Shows a tooltip with optional auto-hide |
| `ShowErrorTip(msg, durationMs)` | 614 | Shows an error tooltip |
| `GetSelectionText(timeoutMs)` | 322 | Copies current selection and returns text |
| `WriteUtf8(path, text, overwrite)` | 347 | Writes text to file with UTF-8 encoding |
| `EnsureTxtExtension(path)` | 363 | Ensures file path ends with .txt |
| `OpenTempView(text, prefix)` | 374 | Creates temp file and opens in notepad |
| `SendKeySequence(keys)` | 385 | Sends a key sequence |
| `RunHidden(exe, params)` | 393 | Runs command hidden (no window) |
| `CreateTempFile(prefix, extension)` | 401 | Creates a temporary file path |
| `RemoveToolTip()` | 103 | Removes tooltip |
| `PromptOptHelpClose()` | 605 | Closes help window |

#### Hotkey Handlers (Template.ahk)
| Hotkey | Line | Description |
|--------|------|-------------|
| `!2::` | 72 | Alt+2: Copy to Clipextra |
| `!v::` | 79 | Alt+V: Paste from Clipextra |
| `^!+c::` | 90 | Ctrl+Alt+Shift+C: Toggle PK_PROMPT monitoring |
| `+!RButton::` | 112 | Shift+Alt+RButton: Launch Raw-to-Prompt |
| `!RButton::` | 161 | Alt+RButton: Copy (Ctrl+C) |
| `!LButton::` | 164 | Alt+LButton: Paste (Ctrl+V) |
| `:*R:PK_PROMPT::` | 171 | Hotstring: Launch inline PromptOpt |
| `:*?:????::` | 174 | Hotstring: Optimize entire field |
| `^!AppsKey::` | 177 | Ctrl+Alt+AppsKey: PromptOpt menu |
| `^!+p::` | 180 | Ctrl+Alt+Shift+P: PromptOpt menu |
| `^!p::` | 187 | Ctrl+Alt+P: Launch PromptOpt |
| `^!XButton1::` | 190 | Ctrl+Alt+XButton1: Launch PromptOpt |
| `^+XButton2::` | 197 | Ctrl+Shift+XButton2: Flatten clipboard |

---

### **core/environment.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\core\environment.ahk`

| Function | Line | Description |
|----------|------|-------------|
| `LoadDotEnv()` | 15 | Loads environment variables from .env file |
| `SendSecretFromEnv(varName, promptText)` | 47 | Safely sends secret from environment variable |
| `SendHotstringText(text)` | 63 | Sends text using clipboard paste method |
| `__HideTipSec()` | 78 | Timer callback to hide tooltip |
| `SaveClipboard()` | 87 | Saves current clipboard content |
| `RestoreClipboard(&savedClip)` | 95 | Restores previously saved clipboard |

---

### **hotstrings/api-keys.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotstrings\api-keys.ahk`

**All functions use `SendSecretFromEnv()` to safely handle API keys**

| Hotstring | Line | Environment Variable |
|-----------|------|---------------------|
| `Orouterkey` | 8 | OPENROUTER_API_KEY |
| `hftoken` | 10 | HF_TOKEN |
| `browserkeyuse` | 12 | BROWSER_USE_KEY |
| `browser-use-key` | 14 | BROWSER_USE_KEY_2 |
| `gittoken` | 16 | GH_TOKEN |
| `arceekey` | 18 | ARCEE_API_KEY |
| `perplexitykey` | 20 | PPLX_API_KEY |
| `mem0key` | 22 | MEM0_API_KEY |
| `npmtoken` | 24 | NPM_TOKEN |
| `geminikey` | 26 | GEMINI_API_KEY |
| `openpipekey` | 28 | OPENPIPE_API_KEY |
| `groqkey` | 30 | GROQ_API_KEY |
| `OAIKey` | 32 | OPENAI_API_KEY |
| `OAI2Key` | 34 | OPENAI_API_KEY_2 |
| `ClaudeKey` | 36 | CLAUDE_API_KEY |
| `cloudflare-worker-key` | 38 | CLOUDFLARE_WORKER_KEY |
| `zaikey` | 40 | ZAI_API_KEY |

---

### **hotstrings/general.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotstrings\general.ahk`

| Function | Line | Description |
|----------|------|-------------|
| `ShowHotstringsMenu()` | 65 | Displays list of all hotstrings |
| `ShowHotkeysMenu()` | 110 | Displays list of all hotkeys |
| `GprompterText()` | 16 | Returns Gemini CLI helper text |
| `CustcomText()` | 31 | Returns customer communication template |
| `AipromptText()` | 41 | Returns AI prompt template |

**Hotstrings:**
- `ahk-hotstrings-list` - Show hotstrings menu
- `ahk-hotkey-list` - Show hotkeys menu
- `p1approval` - Interconnection template
- `gprompter` - Gemini CLI helper
- `custcom` - Customer communication template
- `aiprompt` - AI job search prompt
- `xlcorr` - Correction log
- `windroid` - Path to droid.exe
- `openeminicli` - Gemini CLI command
- `shpw` - Personal macro
- `ixreject` - Interconnection rejection
- `:*r:incopw` - Password (from env)

---

### **hotstrings/templates.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotstrings\templates.ahk`

| Function | Line | Description |
|----------|------|-------------|
| `SdFramework()` | 9 | Self-Discover framework template |
| `TestHelper()` | 348 | QA/Test helper meta-prompt |
| `Prioritization()` | 468 | Prioritization prompt template |
| `RadicalUI()` | 757 | UI/UX expert agent prompt |
| `TaskTriage()` | 924 | Task triage framework |
| `MdNotesCleanup()` | 966 | Markdown notes cleanup agent |

**Hotstrings:**
- `:*:sdframework` - Self-Discover framework
- `:*R:test-helper` - Test helper template
- `:*:custcom` - Customer communication (small)
- `:*:aiprompt` - AI prompt (small)
- `:*:prioritization` - Prioritization template
- `:*:radical-ui` - Radical UI template
- `:*:task-triage` - Task triage template
- `:*:md-notes-cleanup` - Markdown cleanup template

---

### **hotstrings/role-task-constraint.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotstrings\role-task-constraint.ahk`

**Hotstring:** `:*:role-task-constraint` (Line 7)  
Provides structured debugging engineer role prompt with four phases

---

### **hotkeys/mouse.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotkeys\mouse.ahk`

| Hotkey | Description |
|--------|-------------|
| `XButton2::` | Enter key |
| `XButton1::` | Emoji picker (Ctrl+Win+Space) |
| `^RButton::` | Task View (Win+Tab) |
| `^XButton1::` | Switch virtual desktop left |
| `^XButton2::` | Switch virtual desktop right |

---

### **hotkeys/media.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotkeys\media.ahk`

| Hotkey | Description |
|--------|-------------|
| `^!WheelDown::` | Volume down (-10) |
| `^!WheelUp::` | Volume up (+10) |
| `^!MButton::` | Media Play/Pause |
| `^!RButton::` | Next track |
| `^!LButton::` | Previous track |
| `!MButton::` | Send Alt+L |

---

### **hotkeys/windows.ahk**
Location: `C:\Users\prest\Desktop\Others\Scripts\hotkeys\windows.ahk`

| Hotkey | Description |
|--------|-------------|
| `^WheelDown::` | Next tab (activate window) |
| `^WheelUp::` | Previous tab (activate window) |
| `^+RButton::` | Close tab (Ctrl+W) |
| `MButton` (hold) | Hold Ctrl+Win+Alt while pressed |
| `!WheelDown::` | Backspace |
| `^SC029::` | Enter (backtick key) |
| `Home::` | Exit app |

---

### **promptopt/promptopt.ahk** (AHK v2 Orchestrator)
Location: `C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.ahk`

#### Core Functions
| Function | Line | Description |
|----------|------|-------------|
| `InitializeErrorLogging()` | 52 | Creates error log file |
| `LogError(message)` | 67 | Logs error to file |
| `LogInfo(message)` | 81 | Logs info to file |
| `QQ(s)` | 356 | Quote helper for command line |
| `ExitCleanup(Reason, Code)` | 477 | Cleanup on exit |

#### UI Functions
| Function | Line | Description |
|----------|------|-------------|
| `GetOptimalTooltipPosition(width, height)` | 364 | Calculate screen-aware tooltip position |
| `GetOptimalWindowPosition(width, height)` | 390 | Calculate screen-aware window position |
| `ShowTip(msg)` | 416 | Show tooltip with screen positioning |
| `HideTip()` | 423 | Hide tooltip |
| `QuickTip(msg, ms)` | 433 | Show tooltip with auto-hide |
| `StartStreamTip()` | 442 | Start streaming tooltip animation |
| `StopStreamTip()` | 448 | Stop streaming tooltip |
| `UpdateStreamTip()` | 453 | Update streaming tooltip content |
| `ShowResultWindow(text)` | 509 | Display result window with statistics |
| `ShowSuccess(msg)` | 984 | Show success message |
| `ShowError(msg)` | 991 | Show error message |

#### Profile/Model Selection
| Function | Line | Description |
|----------|------|-------------|
| `GetConfigIniPath()` | 630 | Get config file path |
| `LoadLastProfile()` | 636 | Load last used profile |
| `SaveLastProfile(token)` | 646 | Save profile selection |
| `LoadAutoSelect()` | 653 | Check if auto-select enabled |
| `SaveAutoSelect(on)` | 660 | Enable/disable auto-select |
| `GetSupportedModels()` | 666 | Get list of supported models |
| `GetSupportedModelLabels()` | 677 | Get friendly model names |
| `LoadLastModel(profile)` | 687 | Load last used model |
| `SaveLastModel(modelName)` | 705 | Save model selection |
| `LoadModelAutoSelect()` | 717 | Check if model auto-select enabled |
| `SaveModelAutoSelect(on)` | 724 | Enable/disable model auto-select |
| `GetDefaultModelForProfile(profile)` | 195 | Get default model for profile |
| `ShowProfileHelp()` | 729 | Show profile help window |
| `PickProfile(defaultToken)` | 790 | Show profile picker GUI |
| `PickProfile_Ok(...)` | 832 | Profile picker OK handler |
| `PickProfile_Cancel(...)` | 841 | Profile picker cancel handler |
| `ShowModelHelp()` | 850 | Show model help window |
| `PickModel(defaultModel)` | 923 | Show model picker GUI |
| `PickModel_Ok(...)` | 965 | Model picker OK handler |
| `PickModel_Cancel(...)` | 974 | Model picker cancel handler |

#### Result Window Functions
| Function | Line | Description |
|----------|------|-------------|
| `CopyToClipboard(text)` | 569 | Copy text to clipboard with feedback |
| `CopyResult()` | 585 | Copy result from edit control |
| `CloseResultWindow()` | 590 | Close result window |
| `SaveResult()` | 595 | Save result to file |
| `OpenInEditor()` | 612 | Open result in Notepad |
| `PathShort(p)` | 624 | Shorten long paths for display |

---

### **promptopt/promptopt.ps1** (PowerShell Bridge)
Location: `C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.ps1`

#### Parameters
- `$Mode` - Optimization mode (default: "meta")
- `$SelectionFile` - Path to input file
- `$OutputFile` - Path to output file
- `$MetaPromptDir` - Directory containing meta-prompts
- `$ApiKey` - API key for LLM service
- `$Model` - LLM model to use
- `$BaseUrl` - API endpoint URL
- `$Profile` - Domain profile (browser/coding/writing/rag/general)
- `$LogFile` - Path to log file
- `$CopyToClipboard` - Switch to copy result

#### Functions
| Function | Line | Description |
|----------|------|-------------|
| `Write-Log($msg)` | 20 | Write to log file |
| `Import-DotEnv($path)` | 48 | Load .env file into environment |
| `Get-MetaPrompt($path)` | 95 | Extract meta prompt from file |
| `Get-Python()` | 173 | Find Python executable |

---

### **promptopt/promptopt.py** (Python Backend)
Location: `C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.py`

#### Functions
| Function | Line | Description |
|----------|------|-------------|
| `dbg(msg)` | 13 | Debug logging to stderr |
| `read_text(path)` | 20 | Read text file with UTF-8 encoding |
| `write_text(path, content)` | 25 | Write text file with UTF-8 encoding |
| `build_payload(model, sys_prompt, user_input)` | 32 | Build API request payload |
| `extract_output_text(obj)` | 42 | Extract text from API response |
| `post_json(url, body, api_key, ...)` | 74 | Make JSON POST request |
| `stream_chat_completions(...)` | 89 | Stream API responses |
| `try_call(...)` | 131 | Attempt API call with model |
| `try_stream(...)` | 166 | Attempt streaming API call |
| `main()` | 199 | Main entry point |

---

## Module Dependencies

```
Template.ahk (Entry Point)
├── core/environment.ahk
│   ├── LoadDotEnv()
│   ├── SendSecretFromEnv()
│   ├── SendHotstringText()
│   ├── SaveClipboard()
│   └── RestoreClipboard()
├── hotstrings/
│   ├── api-keys.ahk (uses SendSecretFromEnv)
│   ├── general.ahk (uses SendHotstringText)
│   ├── templates.ahk (uses SendHotstringText)
│   └── role-task-constraint.ahk (uses SaveClipboard/RestoreClipboard)
├── hotkeys/
│   ├── mouse.ahk
│   ├── media.ahk
│   └── windows.ahk
└── promptopt/
    ├── promptopt.ahk (AHK v2 Orchestrator)
    │   ├── Profile/Model Selection UI
    │   ├── Result Window UI
    │   ├── Error Logging
    │   └── Calls → promptopt.ps1
    ├── promptopt.ps1 (PowerShell Bridge)
    │   ├── Environment Loading
    │   ├── Meta Prompt Loading
    │   ├── API Key Management
    │   └── Calls → promptopt.py
    └── promptopt.py (Python Backend)
        ├── OpenRouter API Integration
        ├── OpenAI API Integration
        ├── Streaming Support
        └── Model Fallback Logic
```

---

## Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                          │
└───────────────┬──────────────────────────┬──────────────────────┘
                │                          │
    ┌───────────▼───────────┐   ┌─────────▼────────────┐
    │  Hotkey/Hotstring     │   │  PromptOpt Hotkeys  │
    │  • Text Expansion     │   │  • Ctrl+Alt+P       │
    │  • Media Controls     │   │  • Ctrl+Alt+Shift+P │
    │  • Window Management  │   │  • PK_PROMPT        │
    └───────────┬───────────┘   └─────────┬────────────┘
                │                         │
    ┌───────────▼───────────┐   ┌─────────▼────────────┐
    │  core/environment.ahk │   │   Template.ahk       │
    │  • LoadDotEnv()       │   │   • PromptOpt_Run()  │
    │  • SendSecretFromEnv()│   │   • PK_RunPromptOpt()│
    │  • SaveClipboard()    │   │   • BuildCommand()   │
    └───────────┬───────────┘   └─────────┬────────────┘
                │                         │
                └──────────┬──────────────┘
                           │
                ┌──────────▼──────────────┐
                │  TryRunWithAHKv2()      │
                │  Attempts AHK v2 launch │
                └──────────┬──────────────┘
                           │
                ┌──────────▼──────────────────────────┐
                │  Is AHK v2 Available?              │
                └──┬─────────────────────────────┬───┘
                   │ YES                   NO    │
         ┌─────────▼──────────┐   ┌──────────────▼──────────────┐
         │ promptopt.ahk      │   │  RunPromptOptFallback()     │
         │ (AHK v2 Version)   │   │  (Direct PowerShell)        │
         │ • Profile Picker   │   │  • BuildPromptOptCommand()  │
         │ • Model Picker     │   │  • HandlePromptOptOutput()  │
         │ • Streaming UI     │   └──────────────┬──────────────┘
         │ • Result Window    │                  │
         └─────────┬──────────┘                  │
                   │                             │
                   └──────────┬──────────────────┘
                              │
                   ┌──────────▼──────────────┐
                   │  promptopt.ps1          │
                   │  (PowerShell Bridge)    │
                   │  • Load .env            │
                   │  • Get Meta Prompt      │
                   │  • API Key Selection    │
                   │  • Provider Detection   │
                   └──────────┬──────────────┘
                              │
                   ┌──────────▼──────────────┐
                   │  promptopt.py           │
                   │  (Python Backend)       │
                   │  • API Communication    │
                   │  • Streaming Support    │
                   │  • Model Fallback       │
                   │  • Response Parsing     │
                   └──────────┬──────────────┘
                              │
                   ┌──────────▼──────────────┐
                   │  LLM API Services       │
                   │  • OpenRouter           │
                   │  • OpenAI               │
                   └──────────┬──────────────┘
                              │
                   ┌──────────▼──────────────┐
                   │  Response Processing    │
                   │  • Extract Output       │
                   │  • Write to File        │
                   │  • Copy to Clipboard    │
                   └──────────┬──────────────┘
                              │
                   ┌──────────▼──────────────┐
                   │  ShowPromptOptWindow()  │
                   │  • Display Result       │
                   │  • Save Option          │
                   │  • Copy Option          │
                   │  • Open in Notepad      │
                   └─────────────────────────┘
```

---

## Key Integration Points

### 1. **Environment Configuration Flow**
```
.env file → LoadDotEnv() → EnvSet() → Global Variables
```

### 2. **Clipboard Safety Pattern**
```
SaveClipboard() → Operation → RestoreClipboard()
```

### 3. **PromptOpt Execution Chain**
```
Hotkey Trigger → PromptOpt_Run() → TryRunWithAHKv2()
                                    ├─ Success → promptopt.ahk
                                    └─ Fail → RunPromptOptFallback()
                                              → promptopt.ps1
                                              → promptopt.py
                                              → API
```

### 4. **PK_PROMPT Automation Flow**
```
Clipboard Change → PK_HandleClipboard()
                   → Detect "PK_PROMPT" prefix
                   → PK_RunPromptOpt()
                   → Process and paste result
```

### 5. **API Key Security Pattern**
```
User Input (Hotstring) → SendSecretFromEnv(varName)
                       → EnvGet(varName)
                       → SendRaw (never logged)
```

---

## Global Variables

### Template.ahk
| Variable | Purpose |
|----------|---------|
| `RAW_TO_PROMPT_DIR` | Path to raw-to-prompt tool |
| `RAW_TO_PROMPT_MAIN` | Path to main.py |
| `CLIPBOARD_TIMEOUT` | Clipboard operation timeout (1000ms) |
| `TOOLTIP_DURATION` | Tooltip display duration (1200ms) |
| `PROMPTOPT_LAUNCH_DELAY` | Delay before launching PromptOpt (500ms) |
| `PK_TRIGGER_PREFIX` | Automation trigger text ("PK_PROMPT") |
| `PK_CLIPBOARD_GUARD` | Prevents recursive clipboard handling |
| `PK_PROMPTOPT_BUSY` | Prevents concurrent PromptOpt runs |
| `PK_PROMPT_MENU_BUILT` | Menu initialization flag |
| `PK_CLIPBOARD_MONITORING_ENABLED` | Toggle for clipboard monitoring |
| `Clipextra` | Secondary clipboard storage |
| `AHK_V2_PATH_A` | Primary AHK v2 installation path |
| `AHK_V2_PATH_B` | Secondary AHK v2 installation path |

---

## External Dependencies

### Required
- **AutoHotkey v2.0** - Main script runtime
- **Python 3.x** - Backend API communication
- **PowerShell 5.1+** - Bridge layer
- **Windows OS** - Platform requirement

### Optional
- **.env file** - Environment configuration
- **meta-prompts/*.md** - Profile-specific prompts
- **Raw-to-Prompt tool** - Text processing utility

### API Services
- **OpenRouter API** - Primary LLM provider
- **OpenAI API** - Alternative LLM provider

---

## Usage Examples

### Basic PromptOpt
1. Select text in any application
2. Press `Ctrl+Alt+P`
3. Choose profile and model
4. Review optimized prompt

### PK_PROMPT Automation
1. Enable monitoring: `Ctrl+Alt+Shift+C`
2. Type: `PK_PROMPT your task here`
3. Copy text (Ctrl+C)
4. Optimized prompt auto-pastes

### API Key Expansion
1. Type hotstring: `OAIKey`
2. Secret auto-expands from environment
3. Never logged or displayed

### Clipboard Extras
1. Press `Alt+2` to save to extra clipboard
2. Press `Alt+V` to paste from extra clipboard

---

## Configuration Files

### .env (in Scripts directory)
```ini
OPENROUTER_API_KEY=sk-or-...
OPENAI_API_KEY=sk-...
RAW_TO_PROMPT_DIR=C:\path\to\raw-to-prompt
PROMPTOPT_MODE=meta
PROMPTOPT_PROFILE=coding
PROMPTOPT_STREAM=1
```

### config.ini (in %AppData%\PromptOpt\)
Stores user preferences:
- Last selected profile
- Last selected model per profile
- Auto-select preferences

---

## Error Handling

### Template.ahk
- Validates paths before execution
- Checks Python availability
- Timeout handling for clipboard operations
- Graceful fallback when AHK v2 unavailable

### promptopt.ahk
- Error logging to temp directory
- Screen-aware positioning for all UI
- Clipboard restore on error
- Temp file cleanup on exit

### promptopt.ps1
- Environment variable cascading
- Provider auto-detection
- Dry-run mode support
- Detailed logging

### promptopt.py
- Model fallback chain
- HTTP error handling
- Stream reconnection
- Response parsing with multiple formats

---

## Performance Characteristics

- **Hotkey Response**: <50ms
- **Clipboard Operations**: <100ms
- **PromptOpt Launch**: 500-1000ms
- **API Response**: 2-10s (depends on model and streaming)
- **Streaming Updates**: 200ms refresh rate

---

## Security Notes

1. **API Keys**: Never logged, always read from environment
2. **Secrets**: Use `SendSecretFromEnv()` pattern
3. **Temp Files**: Cleaned up on exit
4. **Clipboard**: Restored after operations
5. **Logs**: Stored in temp directory, rotated daily

---

## Maintenance

### Adding New Hotstrings
1. Edit appropriate file in `hotstrings/`
2. Use `SendHotstringText()` for text
3. Use `SendSecretFromEnv()` for secrets
4. Update `ShowHotstringsMenu()` in general.ahk

### Adding New Hotkeys
1. Edit appropriate file in `hotkeys/`
2. Update `ShowHotkeysMenu()` in general.ahk

### Adding New Profiles
1. Create `Meta_Prompt.<profile>.md` in meta-prompts/
2. Add profile to picker in promptopt.ahk
3. Set default model in `GetDefaultModelForProfile()`

---

**Last Updated:** 2025-11-17  
**Maintainer:** Template.ahk System  
**Version:** 2.0
