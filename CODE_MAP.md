# PromptOpt System Code Map

## Component Definitions

### 1. Entry Point Layer
**Template.ahk** (920 lines)
- **Purpose**: Main orchestrator and hotkey entry point
- **Key Functions**:
  - `LoadDotEnv()` - Loads environment variables from `.env`
  - `PromptOpt_Run()` - Main PromptOpt entry point
  - `PK_RunPromptOpt()` - PK_PROMPT automation handler
  - `TryRunWithAHKv2()` - Launches AHK v2 scripts
  - `RunPromptOptFallback()` - Fallback when AHK v2 unavailable
- **Hotkeys**:
  - `Ctrl+Alt+P` - Launch PromptOpt
  - `Ctrl+Alt+XButton1` - Launch PromptOpt (mouse)
  - `Shift+Alt+RButton` - Launch Raw-to-Prompt tool
  - `Ctrl+Alt+Shift+P` - PromptOpt context menu
  - `Ctrl+Alt+AppsKey` - PromptOpt context menu
- **Includes**: All modular components below

### 2. Core Environment Module
**core/environment.ahk** (98 lines)
- **Purpose**: Environment loading, clipboard management, secret handling
- **Key Functions**:
  - `LoadDotEnv()` - Parses `.env` file and sets environment variables
  - `SendSecretFromEnv()` - Safely sends secrets from environment (never logs)
  - `SendHotstringText()` - Reliable text sending via clipboard paste
  - `SaveClipboard()` / `RestoreClipboard()` - Clipboard state management
- **Security**: Never prompts for or logs secrets

### 3. Hotstring Modules (Text Expansion)

**hotstrings/api-keys.ahk** (41 lines)
- **Purpose**: API key hotstrings (security-focused)
- **Hotstrings**: `Orouterkey`, `hftoken`, `browserkeyuse`, `gittoken`, `arceekey`, `perplexitykey`, `mem0key`, `npmtoken`, `geminikey`, `openpipekey`, `groqkey`, `OAIKey`, `OAI2Key`, `ClaudeKey`, `cloudflare-worker-key`, `zaikey`
- **Security**: All read from environment variables only

**hotstrings/general.ahk** (138 lines)
- **Purpose**: General text expansion hotstrings
- **Hotstrings**: `p1approval`, `gprompter`, `custcom`, `aiprompt`, `xlcorr`, `windroid`, `openeminicli`, `shpw`, `ixreject`, `incopw`
- **Features**: Includes menu functions to list all hotstrings/hotkeys

**hotstrings/templates.ahk** (1072 lines)
- **Purpose**: Large multi-line template expansions
- **Hotstrings**: `sdframework`, `test-helper`, `custcom`, `aiprompt`, `prioritization`, `radical-ui`, `task-triage`, `md-notes-cleanup`
- **Content**: Complex frameworks and prompts (Self-Discover, Test-Helper, Prioritization, UI/UX, etc.)

**hotstrings/role-task-constraint.ahk** (126 lines)
- **Purpose**: Role-task-constraint template hotstring
- **Hotstring**: `role-task-constraint`
- **Content**: Three-phase maintenance cycle prompt

### 4. Hotkey Modules (Keyboard/Mouse Shortcuts)

**hotkeys/mouse.ahk** (37 lines)
- **Purpose**: Mouse button remapping
- **Hotkeys**:
  - `XButton2` → Enter
  - `XButton1` → Ctrl+Win+Space (emoji picker)
  - `Ctrl+RButton` → Win+Tab (Task View)
  - `Ctrl+XButton1` → Switch desktop left
  - `Ctrl+XButton2` → Switch desktop right

**hotkeys/media.ahk** (30 lines)
- **Purpose**: Media playback and volume control
- **Hotkeys**:
  - `Ctrl+Alt+WheelDown` → Volume -10
  - `Ctrl+Alt+WheelUp` → Volume +10
  - `Ctrl+Alt+MButton` → Media Play/Pause
  - `Ctrl+Alt+RButton` → Media Next Track
  - `Ctrl+Alt+LButton` → Media Previous Track
  - `Alt+MButton` → Alt+L (app-specific)

**hotkeys/windows.ahk** (54 lines)
- **Purpose**: Window switching and tab management
- **Hotkeys**:
  - `Ctrl+WheelDown` → Activate window + Next Tab
  - `Ctrl+WheelUp` → Activate window + Previous Tab
  - `Ctrl+Shift+RButton` → Close Tab
  - `MButton` (hold) → Hold Ctrl+Win+Alt
  - `Alt+WheelDown` → Backspace
  - `Ctrl+` (grave) → Enter
  - `Home` → Exit app

### 5. PromptOpt System (AI Prompt Optimization)

**promptopt/promptopt.ahk** (997 lines)
- **Purpose**: AHK v2 orchestrator for PromptOpt workflow
- **Key Functions**:
  - Clipboard selection capture (with retry logic)
  - Profile selection GUI (`PickProfile()`)
  - Model selection GUI (`PickModel()`)
  - Streaming tooltip updates (`StartStreamTip()`, `UpdateStreamTip()`)
  - Result window display (`ShowResultWindow()`)
  - Error logging (`LogError()`, `LogInfo()`)
- **Flow**:
  1. Copy selection from clipboard
  2. Validate text size
  3. Get API key (from env or prompt)
  4. Select profile (with memory/auto-select)
  5. Select model (with memory/auto-select)
  6. Create temp files
  7. Launch PowerShell bridge
  8. Monitor output file for streaming
  9. Display result window
- **Config**: Reads from `%AppData%\PromptOpt\config.ini` for profile/model preferences

**promptopt/promptopt.ps1** (275 lines)
- **Purpose**: PowerShell bridge and control plane
- **Key Functions**:
  - `Import-DotEnv()` - Loads `.env` files
  - `Get-MetaPrompt()` - Extracts meta-prompt from markdown files
- **Flow**:
  1. Parse command-line arguments
  2. Load environment variables (with overrides)
  3. Resolve meta-prompt file based on Mode + Profile
  4. Extract meta-prompt content from markdown
  5. Handle dry-run mode (offline testing)
  6. Locate Python executable
  7. Call Python API client with parameters
  8. Handle streaming output
  9. Copy result to clipboard if requested
- **Meta-Prompt Resolution**:
  - Mode: `meta` or `edit`
  - Profile: `browser`, `coding`, `writing`, `rag`, `general`
  - File pattern: `Meta_Prompt[.Profile].md` or `Meta_Prompt_Edits[.Profile].md`
  - Fallback: Base `Meta_Prompt.md`

**promptopt/promptopt.py** (306 lines)
- **Purpose**: Python API client for OpenAI/OpenRouter
- **Key Functions**:
  - `try_call()` - Non-streaming API call
  - `try_stream()` - Streaming API call (SSE)
  - `extract_output_text()` - Parses various response formats
  - `post_json()` - HTTP POST with JSON payload
  - `stream_chat_completions()` - SSE stream parser
- **Flow**:
  1. Read system prompt and user input from files
  2. Get API key from environment
  3. Detect provider (OpenRouter vs OpenAI)
  4. Build Chat Completions payload
  5. Make API call (streaming or non-streaming)
  6. Parse response (handles multiple formats)
  7. Write output incrementally to temp file (for streaming)
  8. Return exit code
- **Provider Detection**:
  - OpenRouter: Base URL contains `openrouter.ai` OR key starts with `sk-or-`
  - OpenAI: Default Chat Completions endpoint
- **Model Fallbacks**: Tries requested model, then fallback list

**meta-prompts/** (Directory)
- **Purpose**: Meta-prompt templates that guide AI optimization
- **Files**:
  - `Meta_Prompt.md` - Base meta prompt
  - `Meta_Prompt_Edits.md` - Edit mode meta prompt
  - `Meta_Prompt.{browser,coding,rag,general,writing}.md` - Profile variants
  - `Meta_Prompt_Edits.{browser,coding,rag,general,writing}.md` - Profile-specific edit modes
- **Format**: Contains `META_PROMPT = """ ... """` anchor for extraction

### 6. External Tools

**Raw-to-Prompt Tool** (External Python Script)
- **Trigger**: `Shift+Alt+RButton`
- **Path**: Configurable via `RAW_TO_PROMPT_DIR` environment variable
- **Default**: `C:\Users\prest\Desktop\Desktop_Projects\May-Dec-2025\raw-to-prompt\main.py`
- **Purpose**: Python-based text processing tool

## Execution Flow Diagrams

### Primary Flow: PromptOpt Optimization

```
User Action: Ctrl+Alt+P (or Ctrl+Alt+XButton1)
    │
    ▼
Template.ahk::PromptOpt_Run()
    │
    ├─► TryRunWithAHKv2("promptopt/promptopt.ahk")
    │       │
    │       ▼
    │   promptopt.ahk (AHK v2 orchestrator)
    │       │
    │       ├─► Copy selection (Ctrl+C) → Clipboard
    │       ├─► Validate text size
    │       ├─► Get API key (env or prompt)
    │       ├─► PickProfile() → GUI selection
    │       ├─► PickModel() → GUI selection
    │       ├─► Create temp files (tmpSel, tmpOut)
    │       ├─► StartStreamTip() → Live preview tooltip
    │       │
    │       └─► Launch PowerShell:
    │               │
    │               ▼
    │           promptopt.ps1 (PowerShell bridge)
    │               │
    │               ├─► Load .env files
    │               ├─► Resolve meta-prompt file:
    │               │       meta-prompts/Meta_Prompt[.Profile].md
    │               ├─► Extract META_PROMPT = """..."""
    │               ├─► Write system prompt to temp file
    │               │
    │               └─► Launch Python:
    │                       │
    │                       ▼
    │                   promptopt.py (API client)
    │                       │
    │                       ├─► Read system prompt + user input
    │                       ├─► Detect provider (OpenRouter/OpenAI)
    │                       ├─► Build Chat Completions payload
    │                       ├─► Make API call (streaming or non-stream)
    │                       ├─► Parse response (multiple formats)
    │                       └─► Write output to tmpOut (incremental for streaming)
    │                               │
    │                               ▼
    │                           promptopt.ahk monitors tmpOut
    │                               │
    │                               ├─► UpdateStreamTip() → Live preview
    │                               └─► ShowResultWindow() → GUI display
    │                                       │
    │                                       └─► Copy to clipboard + SoundBeep
    │
    └─► RunPromptOptFallback() [if AHK v2 unavailable]
            │
            └─► Direct PowerShell call (same flow as above)
```

### Secondary Flow: PK_PROMPT Automation

```
User Action: Type "PK_PROMPT <text>" + Copy (Ctrl+C)
    │
    ▼
Template.ahk::PK_HandleClipboard() [if monitoring enabled]
    │
    ├─► Check for "PK_PROMPT" prefix
    ├─► Extract prompt text
    │
    └─► PK_RunPromptOpt(promptText)
            │
            ├─► PK_CopyEntireFieldText() → Get full field content
            ├─► Create temp files
            │
            └─► Same flow as PromptOpt_Run()
                    │
                    └─► PK_ProcessResult()
                            │
                            └─► SendHotstringText() → Paste optimized prompt inline
```

### Hotstring Expansion Flow

```
User Types: Trigger text (e.g., "sdframework")
    │
    ▼
Template.ahk (includes hotstrings/*.ahk)
    │
    ├─► hotstrings/api-keys.ahk
    │       └─► SendSecretFromEnv() → Read from environment
    │
    ├─► hotstrings/general.ahk
    │       └─► SendHotstringText() → Clipboard paste method
    │
    ├─► hotstrings/templates.ahk
    │       └─► Large function → Build text → SendHotstringText()
    │
    └─► hotstrings/role-task-constraint.ahk
            └─► Function → Build text → SendHotstringText()
```

### Raw-to-Prompt Tool Flow

```
User Action: Shift+Alt+RButton
    │
    ▼
Template.ahk::+!RButton
    │
    ├─► Validate RAW_TO_PROMPT_DIR path
    ├─► Check Python availability
    ├─► Copy selection (Ctrl+C)
    │
    └─► Run('python "main.py"', RAW_TO_PROMPT_DIR)
            │
            └─► External Python script (not in this repo)
```

## Data Flow

### Clipboard Flow
```
Original Clipboard
    │
    ├─► SaveClipboard() → Saved state
    ├─► A_Clipboard := "" → Clear
    ├─► Send("^c") → Copy selection
    ├─► ClipWait() → Wait for content
    │
    └─► Process text
            │
            └─► RestoreClipboard() → Restore original
```

### Temp File Flow
```
Temp Directory: %TEMP%
    │
    ├─► promptopt_sel_[timestamp].txt → User selection
    ├─► promptopt_out_[timestamp].txt → AI output (streaming)
    ├─► promptopt_[timestamp].log → PowerShell logs
    ├─► promptopt_sys_[timestamp].txt → Extracted meta-prompt
    └─► promptopt_error_[YYYYMMDD].log → Error log
```

### Environment Variable Flow
```
.env file (root directory)
    │
    ├─► LoadDotEnv() → Parse and set env vars
    │
    ├─► API Keys:
    │       ├─► OPENAI_API_KEY
    │       ├─► OPENROUTER_API_KEY
    │       └─► PROMPTOPT_API_KEY (set by promptopt.ahk)
    │
    ├─► Configuration:
    │       ├─► PROMPTOPT_MODE (meta/edit)
    │       ├─► OPENAI_MODEL
    │       ├─► PROMPTOPT_PROFILE (browser/coding/writing/rag/general)
    │       ├─► PROMPTOPT_STREAM (1/0)
    │       ├─► OPENAI_BASE_URL
    │       └─► PROMPTOPT_TIMEOUT
    │
    └─► Development:
            ├─► PROMPTOPT_DRYRUN (1/0)
            └─► PROMPTOPT_DRYRUN_STREAM (1/0)
```

## Configuration Files

### Persistent Config
**Location**: `%AppData%\PromptOpt\config.ini`
- `[profile]`
  - `last` - Last selected profile
  - `autoselect` - Auto-use last profile (0/1)
- `[model]`
  - `last` - Last selected model (global)
  - `last_[profile]` - Last selected model per profile
  - `autoselect` - Auto-use last model (0/1)

### Meta-Prompt Files
**Location**: `meta-prompts/`
- Format: Markdown with `META_PROMPT = """..."""` anchor
- Resolution order:
  1. `Meta_Prompt[.Profile].md` (profile-specific)
  2. `Meta_Prompt.md` (base fallback)
  3. Hardcoded fallback in PowerShell script

## Error Handling & Logging

### Error Logging
- **AHK**: `%TEMP%\promptopt_error_[YYYYMMDD].log`
- **PowerShell**: `%TEMP%\promptopt_[timestamp].log`
- **Python**: Debug output to stderr (captured by PowerShell)

### Error Recovery
- Clipboard operations: Retry logic with configurable timeouts
- API calls: Model fallback chain
- File operations: Try-catch with user-friendly error messages
- AHK v2 unavailable: Fallback to direct PowerShell execution

## Security Considerations

1. **API Keys**: Never logged, passed via environment only
2. **Secrets**: `SendSecretFromEnv()` reads from environment, never prompts
3. **Clipboard**: Original state always restored after operations
4. **File Paths**: Validated before use, no arbitrary execution
5. **Temp Files**: Created with unique timestamps, cleaned up on exit

