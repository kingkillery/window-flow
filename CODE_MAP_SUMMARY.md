# PromptOpt System - Code Map Summary

## Quick Reference

### Entry Point
- **Template.ahk** (920 lines) - Main orchestrator, loads all modules

### Core Components

| Component | Lines | Purpose |
|-----------|-------|---------|
| `core/environment.ahk` | 98 | Environment loading, clipboard management |
| `promptopt/promptopt.ahk` | 997 | AHK v2 orchestrator (largest component) |
| `promptopt/promptopt.ps1` | 275 | PowerShell bridge |
| `promptopt/promptopt.py` | 306 | Python API client |
| `hotstrings/templates.ahk` | 1072 | Large template expansions (largest file) |

### Module Breakdown

**Hotstrings** (Text Expansion)
- `api-keys.ahk` - 15 API key hotstrings (security-focused)
- `general.ahk` - 10 general text expansions
- `templates.ahk` - 8 large framework templates
- `role-task-constraint.ahk` - 1 role template

**Hotkeys** (Keyboard/Mouse Shortcuts)
- `mouse.ahk` - 5 mouse button remappings
- `media.ahk` - 6 media control shortcuts
- `windows.ahk` - 7 window/tab management shortcuts

### Execution Paths

1. **PromptOpt Optimization** (`Ctrl+Alt+P`)
   ```
   Template.ahk → promptopt.ahk → promptopt.ps1 → promptopt.py → API
   ```

2. **PK_PROMPT Automation** (Clipboard monitoring)
   ```
   Clipboard Event → Template.ahk → Same as PromptOpt → Inline Paste
   ```

3. **Hotstring Expansion** (Type trigger text)
   ```
   User Input → Module Function → SendHotstringText() → Clipboard Paste
   ```

4. **Raw-to-Prompt Tool** (`Shift+Alt+RButton`)
   ```
   Template.ahk → External Python Script
   ```

### Key Functions

**Template.ahk**
- `PromptOpt_Run()` - Main entry point
- `PK_RunPromptOpt()` - PK_PROMPT handler
- `TryRunWithAHKv2()` - AHK v2 launcher
- `RunPromptOptFallback()` - Fallback handler

**promptopt.ahk**
- `PickProfile()` - Profile selection GUI
- `PickModel()` - Model selection GUI
- `StartStreamTip()` - Live preview tooltip
- `ShowResultWindow()` - Result display GUI

**promptopt.ps1**
- `Import-DotEnv()` - Environment loader
- `Get-MetaPrompt()` - Meta-prompt extractor

**promptopt.py**
- `try_call()` - Non-streaming API call
- `try_stream()` - Streaming API call
- `extract_output_text()` - Response parser

### Configuration Files

- **`.env`** (root) - Environment variables, API keys
- **`config.ini`** (`%AppData%\PromptOpt\`) - User preferences
- **`meta-prompts/*.md`** - Meta-prompt templates

### Temp Files

- `promptopt_sel_[timestamp].txt` - User selection
- `promptopt_out_[timestamp].txt` - AI output (streaming)
- `promptopt_[timestamp].log` - PowerShell logs
- `promptopt_error_[YYYYMMDD].log` - Error log

### Total Lines of Code

- **Template.ahk**: 920
- **PromptOpt System**: 1,578 (997 + 275 + 306)
- **Hotstrings**: 1,377 (41 + 138 + 1072 + 126)
- **Hotkeys**: 121 (37 + 30 + 54)
- **Core**: 98
- **Total**: ~4,094 lines

### Dependencies

**External**
- AutoHotkey v2.0
- PowerShell 5.1+
- Python 3.x
- OpenAI/OpenRouter API access

**Internal Dependencies**
- All hotstrings depend on `core/environment.ahk`
- PromptOpt system is self-contained
- Hotkeys are independent modules

### Security Features

1. API keys never logged or exposed in command-line
2. Secrets read from environment only
3. Clipboard state always restored
4. File paths validated before use
5. Temp files cleaned up on exit

### Error Recovery

- Clipboard operations: Retry with timeout
- API calls: Model fallback chain
- AHK v2 missing: PowerShell fallback
- File errors: User-friendly messages + logging

