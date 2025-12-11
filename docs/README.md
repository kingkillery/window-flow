# Scripts Directory - Comprehensive Index

## Table of Contents

1. [Purpose & Overview](#purpose--overview)
2. [Core Principles](#core-principles)
3. [Quick Start](#quick-start)
4. [Directory Structure](#directory-structure)
5. [Main Components](#main-components)
6. [Complete Hotkey Reference](#complete-hotkey-reference)
7. [Complete Hotstring Reference](#complete-hotstring-reference)
8. [Meta-Prompt Profiles](#meta-prompt-profiles)
9. [Configuration & Environment](#configuration--environment)
10. [Standalone Tools](#standalone-tools)
11. [Development Resources](#development-resources)
12. [Safety & Troubleshooting](#safety--troubleshooting)

---

## Purpose & Overview

This repository contains a comprehensive suite of Windows automation tools, hotkeys, and utilities designed to enhance daily workflow efficiency. The system integrates:

- **AI-powered prompt optimization** via OpenAI/OpenRouter APIs
- **Advanced hotkey system** with 50+ shortcuts for common tasks
- **Text expansion hotstrings** for API keys, templates, and common phrases
- **Standalone utility tools** for specialized tasks
- **Multi-layer architecture** using AHK → PowerShell → Python pipeline

All scripts are carefully designed with **unique, non-intrusive triggers** to prevent accidental activation during normal computer use.

---

## Core Principles

- **Minimal Disruption**: Multi-key combinations (Ctrl+Alt, Shift+Alt, mouse buttons) prevent accidental triggers
- **Safe Triggers**: No single-key hotkeys or common shortcuts that could interfere with typing
- **Modular Design**: Organized into functional directories for easy maintenance and updates
- **Security**: API keys stored in environment variables, never hardcoded or logged
- **Workflow Enhancement**: Focus on repetitive tasks, text expansion, and external service integration
- **Backwards Compatibility**: All existing hotkeys/hotstrings preserved during modularization

---

## Quick Start

### First-Time Setup (5 minutes)

1. **Run the script**: Double-click `Template.ahk` (or add to Windows startup folder)
2. **Create `.env` file** in the Scripts directory with your API key:
   ```env
   OPENROUTER_API_KEY=sk-or-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   # OR use OpenAI directly:
   OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
3. **Test it**: Select any text, press `Ctrl+Alt+P` → optimized prompt appears in clipboard!

### Essential Hotkeys (Start Using Immediately)

| What You Want | Press This | Result |
|---------------|------------|--------|
| Optimize text to AI prompt | `Ctrl+Alt+P` | Selected text → optimized prompt in clipboard |
| Copy (mouse-friendly) | `Alt+RButton` | Copy without keyboard |
| Paste (mouse-friendly) | `Alt+LButton` | Paste without keyboard |
| Next/Previous tab | `Ctrl+WheelDown/Up` | Navigate tabs with mouse wheel |
| Volume control | `Ctrl+Alt+WheelUp/Down` | Adjust volume by 10 dB |
| Play/Pause media | `Ctrl+Alt+MButton` | Media control |

### Essential Hotstrings (Type These Anywhere)

| Type This | Gets You |
|-----------|----------|
| `Orouterkey` | Your OpenRouter API key (from env) |
| `OAIKey` | Your OpenAI API key (from env) |
| `zaikey` | Your ZAI API key (from env) |
| `sdframework` | Self-Discover framework template |

**That's it!** Everything else is optional configuration.

---

## Directory Structure

```
Scripts/
├── core/                              # Core system files
│   ├── Template.ahk                   # Main entry point (hotkeys, hotstrings, GUI)
│   └── environment.ahk                # .env loading and helper functions
│
├── promptopt/                         # AI Prompt Optimization System
│   ├── promptopt.ahk                  # AHK v2 orchestrator (text selection, UI)
│   ├── promptopt.ps1                  # PowerShell bridge (config, Python caller)
│   ├── promptopt.py                   # Python API client (OpenAI/OpenRouter)
│   └── [Integration Point: meta-prompts/]
│
├── meta-prompts/                      # AI Meta-Prompt Profiles
│   ├── Meta_Prompt.md                 # Default meta-prompt (create/optimize)
│   ├── Meta_Prompt_Edits.md           # Edit mode (improve existing prompts)
│   ├── Meta_Prompt.browser.md         # Web browsing context
│   ├── Meta_Prompt.coding.md          # Software development context
│   ├── Meta_Prompt.general.md         # General-purpose context
│   ├── Meta_Prompt.rag.md             # Retrieval-augmented generation
│   ├── Meta_Prompt.writing.md         # Writing & content creation
│   └── [Corresponding _Edits.* variants for each profile]
│
├── hotkeys/                           # Organized Hotkey Modules
│   ├── media.ahk                      # Media playback & volume control
│   ├── windows.ahk                    # Window management & tab switching
│   └── mouse.ahk                      # Mouse button remapping
│
├── hotstrings/                        # Text Expansion Modules
│   ├── api-keys.ahk                   # API key expansion hotstrings
│   ├── general.ahk                    # General text expansions
│   └── templates.ahk                  # Large template hotstrings (sdframework, task-triage, etc.)
│
├── tools/                             # Standalone Utility Scripts
│   ├── directorymapper.ahk            # Directory structure visualization & mapping
│   ├── prompter.ahk                   # Additional prompt helper tools
│   ├── tabfiller.ahk                  # Smart tab-filling for web forms
│   └── xml_tag_autoclose.ahk          # Automatic XML/HTML tag closing
│
├── docs/                              # Documentation
│   ├── README.md                      # This file - complete index
│   ├── AGENTS.md                      # Agent architecture and conventions
│   ├── CLAUDE.md                      # AI coding guidelines for developers
│   └── CONTRIBUTING.md                # Development guidelines
│
├── meta-prompts/                      # Reference files (also in separate Meta_Prompt.md index)
├── Ambia/                             # Solar/business specific scripts
├── CONSOLESCRIPTS/                    # Console utility scripts
├── USERSCRIPTS (tampermonkey)/        # Browser extension scripts
├── prest/                             # Personal workspace scripts
│
├── .env                               # Environment variables (secrets)
├── .github/                           # GitHub workflows and CI/CD
├── PLAN.md                            # Modularization implementation plan
├── AGENTS.md                          # Architecture & agent conventions
├── CLAUDE.md                          # Coding guidelines
├── Template.ahk                       # Entry point (legacy location, loaded from core/)
└── [Log files, temp files, archives]
```

---

## Main Components

### 1. Core System

#### `Template.ahk` - Main Entry Point
The central hotkey script that loads all functionality. Contains:
- Hotkey definitions (50+ shortcuts)
- Hotstring definitions (20+ text expansions)
- GUI for profile/model selection
- PromptOpt launcher integration
- Helper functions for common operations

**Key Features:**
- Auto-loads `.env` for environment variables
- GUI modals for selecting profiles and models
- Streaming support for live prompt display
- Clipboard integration for results

**Security:**
- Never hardcodes API keys
- All credentials stored in environment variables
- Keys are passed via files, not command-line arguments

#### `environment.ahk` - Helper Module
Utility functions for core operations:
- Environment variable loading (`LoadDotEnv()`)
- Helper functions for hotstring text operations
- GUI utilities and dialogs

### 2. PromptOpt System - AI Prompt Optimization

**Purpose:** Transform selected text into optimized AI prompts following best practices

**Trigger:** `Ctrl+Alt+P` or `Ctrl+Alt+XButton1`

**Architecture:**
```
1. User selects text → Ctrl+Alt+P
2. promptopt.ahk copies selection to temp file
3. promptopt.ahk launches PowerShell via promptopt.ps1
4. promptopt.ps1 loads meta-prompt from meta-prompts/Meta_Prompt.md
5. promptopt.ps1 calls promptopt.py with API credentials
6. promptopt.py makes streaming request to OpenAI/OpenRouter API
7. Response streamed back to temp file in real-time
8. promptopt.ahk displays tooltip with live streaming preview
9. Final result copied to clipboard automatically
```

**Components:**

- **promptopt.ahk** (17.6 KB)
  - User interface orchestration
  - Text selection handling
  - Profile/model picker GUI
  - Streaming tooltip display
  - Clipboard operations
  - File handoff with PowerShell

- **promptopt.ps1** (11.6 KB)
  - Environment configuration
  - Meta-prompt loading from `meta-prompts/`
  - Python executable discovery
  - API credential preparation
  - Process management and logging
  - Error handling and retry logic

- **promptopt.py** (12.3 KB)
  - OpenAI-compatible Chat Completions API client
  - Streaming and non-streaming modes
  - Provider detection (OpenAI vs OpenRouter)
  - Request construction and retry logic
  - Incremental output to temp file

**Supported Modes:**
- **meta**: Create new optimized prompts from selected text
- **edit**: Improve and refactor existing prompts

**Profiles:** browser, coding, general, rag, writing, custom (with separate meta-prompts for each, except custom which uses user-defined instructions)

---

### 3. Hotkey System (50+ Shortcuts)

All hotkeys use safe multi-key combinations to prevent accidental triggers during normal computer use.

#### Prompt Optimization
| Hotkey | Action | Profile |
|--------|--------|---------|
| `Ctrl+Alt+P` | Optimize selected text into AI prompt | All profiles |
| `Ctrl+Alt+XButton1` | Alternative PromptOpt trigger | All profiles |
| `Shift+Alt+RButton` | Raw-to-Prompt tool | Specialized |

#### Window & Desktop Management
| Hotkey | Action | Effect |
|--------|--------|--------|
| `Ctrl+XButton1` | Previous virtual desktop | Win+Ctrl+Left |
| `Ctrl+XButton2` | Next virtual desktop | Win+Ctrl+Right |
| `Ctrl+RButton` | Switch windows (Alt+Tab) | Win+Tab |
| `Ctrl+Shift+RButton` | Close window/tab | Ctrl+W |
| `MButton` | Show desktop toggle | Win+Shift+D (while held) |

#### Mouse Wheel Navigation
| Hotkey | Action | Effect |
|--------|--------|--------|
| `Ctrl+WheelUp` | Previous tab | Ctrl+PgUp (auto-activates window) |
| `Ctrl+WheelDown` | Next tab | Ctrl+PgDn (auto-activates window) |
| `Ctrl+Alt+WheelUp` | Volume up | +10 dB |
| `Ctrl+Alt+WheelDown` | Volume down | -10 dB |
| `Alt+WheelDown` | Backspace | Single backspace press |

#### Clipboard & Text Utilities
| Hotkey | Action | Purpose |
|--------|--------|---------|
| `Alt+2` | Save clipboard to secondary storage | Quick clipboard swap |
| `Alt+V` | Paste from secondary clipboard | Recover previous clipboard |
| `Alt+RButton` | Copy selection | Ctrl+C (mouse-friendly) |
| `Alt+LButton` | Paste | Ctrl+V (mouse-friendly) |
| `Ctrl+Shift+XButton2` | Flatten text to single line | Remove extra whitespace |

#### Media Controls
| Hotkey | Action | Function |
|--------|--------|----------|
| `Ctrl+Alt+MButton` | Play/Pause | Media toggle |
| `Ctrl+Alt+RButton` | Next track | Skip forward |
| `Ctrl+Alt+LButton` | Previous track | Skip backward |
| `Alt+MButton` | Activate Mouse Jump | PowerToys integration |

#### Navigation & Quick Actions
| Hotkey | Action | Function |
|--------|--------|----------|
| `XButton2` | Text Extractor | Win+Alt+T (PowerToys) |
| `XButton1` | Show/hide files | Win+H |
| `Ctrl+Backtick` | Send Enter | Keyboard alternative |
| `Home` | Exit/reload script | Application control |

---

### 4. Hotstring System (20+ Text Expansions)

Text shortcuts that auto-expand as you type. All use distinctive prefixes to avoid accidental triggers.

#### API Key Hotstrings

| Hotstring | Expands To | Source |
|-----------|-----------|--------|
| `Orouterkey` | OpenRouter API key | `OPENROUTER_API_KEY` env var |
| `OAIKey` | OpenAI API key | `OPENAI_API_KEY` env var |
| `ClaudeKey` | Anthropic API key | `ANTHROPIC_API_KEY` env var |
| `geminikey` | Google Gemini key | `GOOGLE_API_KEY` env var |
| `groqkey` | Groq API key | `GROQ_API_KEY` env var |
| `hftoken` | HuggingFace token | `HUGGINGFACE_TOKEN` env var |
| `gittoken` | GitHub token | `GITHUB_TOKEN` env var |
| `npmtoken` | npm token | `NPM_TOKEN` env var |

**Security Note:** Keys are pulled from environment variables, never hardcoded. Ideal for use in private code, config files, or sensitive contexts.

#### General Utility Hotstrings

| Hotstring | Expands To | Purpose |
|-----------|-----------|---------|
| `p1approval` | "Part 1 Approved - Uploaded..." | Interconnection team template |
| `textnote` | Multi-line solar customer message | Customer communication template |
| `custcom` | "Contact: Summary: Next Steps:" | Customer communication structure |
| `aiprompt` | Solar industry job search prompt | Example AI prompt |
| `xlcorr` | "8/26: Submitted more clear correction." | Spreadsheet correction log |
| `ixreject` | "Interconnection Rejected: Other" | Interconnection status |
| `windroid` | `C:\Users\prest\bin\droid.exe` | Droid command path |
| `openeminicli` | `npx https://github.com/google-gemini/gemini-cli` | Gemini CLI installer |
| `shpw` | `Shot7374` | [Personal credential - may be test] |
| `incopw` | `Shot73747374@@` | [Personal credential - may be test] |

#### AI & Framework Hotstrings

| Hotstring | Expands To | Purpose |
|-----------|-----------|---------|
| `gprompter` | Multi-line gemini command template | Prompt offloading for AI assistants |
| `opengeminicli` | Gemini CLI npm command | Quick reference for CLI installation |
| `sdframework` | Self-Discover framework system prompt | 50+ line AI reasoning framework |

**Source Files:**
- **api-keys.ahk** - API credential expansion (1.6 KB)
- **general.ahk** - General utility and business hotstrings (2.3 KB)
- **templates.ahk** - Large template expansions like sdframework (65.4 KB)

---

### 5. Meta-Prompt Profiles

**Purpose:** Context-specific AI optimization for different use cases

**System:** Each profile has both `Meta_Prompt.{profile}.md` (create mode) and `Meta_Prompt_Edits.{profile}.md` (edit mode)

#### Available Profiles

| Profile | Use Case | Best For |
|---------|----------|----------|
| **browser** | Web research & navigation | Analyzing web content, SEO optimization |
| **coding** | Software development | Code explanations, optimization suggestions |
| **general** | Default/fallback | General-purpose prompt optimization |
| **rag** | Retrieval-augmented generation | Prompt templates with external knowledge |
| **writing** | Content creation | Blog posts, articles, creative writing |
| **custom** | User-defined instructions | Custom optimization rules entered via dialog (no meta-prompt file fallback) |

**Meta-Prompt Philosophy:**
- Output contains only the final prompt (no preamble/postscript)
- Begin with single-line Prompt Title, then optimized body
- Follows AI cookbook best practices (constraints, priorities, minimal examples)
- Never reveals chain-of-thought in output
- Edit mode includes `<reasoning>...</reasoning>` analysis section

**Files:**
- 6 × Create mode prompts
- 6 × Edit mode prompts
- Total: 12 meta-prompt files (40+ KB)

---

### 6. Standalone Tools

#### DirectoryMapper
**File:** `tools/directorymapper.ahk` (12.8 KB)
**Purpose:** Visualize and map directory structures
**Capabilities:**
- Directory tree generation
- Path visualization
- Structure export/reporting

#### Prompter Tool
**File:** `tools/prompter.ahk` (2.6 KB)
**Purpose:** Additional prompt helper utilities
**Capabilities:**
- Prompt template management
- Quick prompt generation

#### Tab Filler
**File:** `tools/tabfiller.ahk` (1.3 KB)
**Purpose:** Smart form filling via Tab key
**Capabilities:**
- Auto-fill web forms
- Tab navigation shortcuts
- Data entry acceleration

#### XML Tag Autoclose
**File:** `tools/xml_tag_autoclose.ahk` (1.5 KB)
**Purpose:** Automatic XML/HTML tag closing
**Capabilities:**
- Auto-complete closing tags
- XML/HTML syntax assistance
- Developer productivity enhancement

---

### 7. Additional Directories

#### Ambia/
Business-specific scripts for solar interconnection workflows (subdirectory with local tools)

#### CONSOLESCRIPTS/
Windows console and PowerShell utilities
- `DTE SEARCH Status.txt` - Utility for DTE status checks

#### USERSCRIPTS (Tampermonkey)/
Browser extension scripts for web automation (Tampermonkey/Greasemonkey)

#### prest/
Personal workspace and experimental scripts

---

## Complete Hotkey Reference

### Safety Patterns Used
- **Multi-modifier combinations** (Ctrl+Alt, Shift+Alt)
- **Mouse button combos** (XButton1/XButton2 with modifiers)
- **Wheel events** with modifiers
- **No single letters** to avoid typing conflicts

### All 40+ Hotkeys

#### PromptOpt (2)
1. `Ctrl+Alt+P` → Optimize prompt
2. `Ctrl+Alt+XButton1` → Optimize prompt (mouse)

#### Window Management (5)
3. `Ctrl+XButton1` → Prev desktop
4. `Ctrl+XButton2` → Next desktop
5. `Ctrl+RButton` → Switch windows
6. `Ctrl+Shift+RButton` → Close window
7. `MButton` → Show desktop (hold)

#### Tab Navigation (2)
8. `Ctrl+WheelUp` → Prev tab
9. `Ctrl+WheelDown` → Next tab

#### Volume & Media (5)
10. `Ctrl+Alt+WheelUp` → Volume +10
11. `Ctrl+Alt+WheelDown` → Volume -10
12. `Ctrl+Alt+MButton` → Play/Pause
13. `Ctrl+Alt+RButton` → Next track
14. `Ctrl+Alt+LButton` → Prev track

#### Clipboard (5)
15. `Alt+2` → Save to secondary
16. `Alt+V` → Paste secondary
17. `Alt+RButton` → Copy
18. `Alt+LButton` → Paste
19. `Alt+MButton` → Mouse Jump

#### Text Operations (2)
20. `Ctrl+Shift+XButton2` → Flatten text
21. `Alt+WheelDown` → Backspace

#### Navigation (3)
22. `XButton2` → Text Extractor
23. `XButton1` → Show/hide files
24. `Ctrl+Backtick` → Enter key

#### Application Control (1)
25. `Home` → Exit/reload

---

## Complete Hotstring Reference

Below is a complete, up-to-date directory of all hotstrings defined in the repository, grouped by module. Triggers are case-sensitive.

### API Keys (16)
| Hotstring | Expands From | Notes |
|-----------|--------------|-------|
| Orouterkey | `OPENROUTER_API_KEY` | OpenRouter API key |
| hftoken | `HF_TOKEN` | HuggingFace token |
| browserkeyuse | `BROWSER_USE_KEY` | Browser Use API key |
| browser-use-key | `BROWSER_USE_KEY_2` | Browser Use API key (alternate) |
| gittoken | `GH_TOKEN` | GitHub token |
| arceekey | `ARCEE_API_KEY` | Arcee API key |
| perplexitykey | `PPLX_API_KEY` | Perplexity API key |
| mem0key | `MEM0_API_KEY` | Mem0 API key |
| npmtoken | `NPM_TOKEN` | npm token |
| geminikey | `GEMINI_API_KEY` | Google AI Studio key |
| openpipekey | `OPENPIPE_API_KEY` | OpenPipe API key |
| groqkey | `GROQ_API_KEY` | Groq API key |
| OAIKey | `OPENAI_API_KEY` | OpenAI primary key |
| OAI2Key | `OPENAI_API_KEY_2` | OpenAI secondary key |
| ClaudeKey | `CLAUDE_API_KEY` | Anthropic key |
| zaikey | `ZAI_API_KEY` | ZAI API key |
| cloudflare-worker-key | `CLOUDFLARE_WORKER_KEY` | Cloudflare Worker API key |

### General Utilities (12)
| Hotstring | Expansion/Behavior | Notes |
|-----------|--------------------|-------|
| p1approval | "Part 1 Approved - Uploaded the email..." | Interconnection template |
| textnote | Multi-line solar customer message | Communication template |
| gprompter | Gemini CLI prompt-offloading helper | AI helper text |
| custcom | Contact / Summary / Next Steps | Structure template |
| aiprompt | Solar industry job search prompt | Example prompt |
| xlcorr | "8/26: Submitted more clear correction." | Spreadsheet correction log |
| windroid | `C:\\Users\\prest\\bin\\droid.exe` | Path expansion |
| openeminicli | `npx https://github.com/google-gemini/gemini-cli` | CLI helper |
| shpw | `Shot7374` | Personal macro |
| ixreject | "Interconnection Rejected: Other" | Status macro |
| incopw | `Shot73747374@@` | Personal macro (r modifier) |

### Templates and Frameworks (8)
| Hotstring | Purpose |
|-----------|---------|
| sdframework | Self-Discover framework system prompt |
| test-helper | QA/Test helper meta-prompt (code verification focus) |
| custcom | Contact/Summary/Next Steps (duplicate in general, larger template) |
| aiprompt | Solar job search prompt (duplicate in general, larger template) |
| prioritization | PRIORITIZATION_PROMPT – planning and output schema |
| radical-ui | MASTER PROMPT – UI/UX expert agent (radical-simple task app) |
| task-triage | Task triage matrix and guidance |
| md-notes-cleanup | Markdown Notes Cleanup agent prompt |

Notes:
- Some triggers appear in both `general.ahk` and `templates.ahk` with different content depth (simple vs. large template). Use the one that suits the context.
- API key hotstrings read from environment variables and never hardcode secrets.

**Total Hotstrings:** 36+ (see individual module files for complete list)


---

## Meta-Prompt Profiles

### Profile Selection

Users can select profiles via GUI when pressing `Ctrl+Alt+P`:
- **First run:** Profile picker appears
- **Subsequent runs:** Uses saved profile
- **Force picker:** Hold `Shift` during hotkey
- **"Don't ask again":** Option to skip picker on next run
- **Custom profile:** When selected, opens a dialog for entering custom optimization instructions (instructions are used directly, no meta-prompt file fallback)

### Profile Details

#### Browser Profile
- **Best for:** Web research, content analysis
- **Optimizes:** Queries for search engines, web scraping, navigation
- **File:** `Meta_Prompt.browser.md` (3.8 KB)

#### Coding Profile
- **Best for:** Programming tasks
- **Optimizes:** Code explanations, debugging prompts, API documentation requests
- **File:** `Meta_Prompt.coding.md` (2.3 KB)

#### General Profile
- **Best for:** Default/fallback use
- **Optimizes:** General-purpose prompts
- **File:** `Meta_Prompt.general.md` (3.1 KB)

#### RAG (Retrieval-Augmented Generation) Profile
- **Best for:** Knowledge synthesis
- **Optimizes:** Prompts that combine documents with queries
- **File:** `Meta_Prompt.rag.md` (2.0 KB)

#### Writing Profile
- **Best for:** Content creation
- **Optimizes:** Blog posts, articles, creative writing
- **File:** `Meta_Prompt.writing.md` (3.1 KB)

#### Custom Profile
- **Best for:** Specialized use cases requiring custom optimization rules
- **Optimizes:** Uses user-defined instructions entered via dialog
- **File:** None - instructions entered directly in dialog, saved to temp file, passed to API
- **Behavior:** When "Custom" is selected, a multi-line text input dialog appears. Enter your custom optimization instructions, click OK, and they will be used as the system prompt (no fallback to base meta-prompt files)

### Edit Mode

Each profile includes an `_Edits` variant for improving existing prompts:
- Provides context-specific rewriting suggestions
- Includes reasoning analysis before output
- Files: `Meta_Prompt_Edits.{profile}.md`

---

## Configuration & Environment

### .env File Format

Store sensitive credentials and configuration:

```env
# API Credentials
OPENROUTER_API_KEY=sk-or-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GOOGLE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Model Selection (default: openai/gpt-oss-120b)
OPENAI_MODEL=openai/gpt-5-mini
OPENAI_BASE_URL=https://openrouter.ai/api/v1

# PromptOpt Configuration
PROMPTOPT_MODE=meta                    # meta|edit
PROMPTOPT_PROFILE=browser              # browser|coding|general|rag|writing|custom
PROMPTOPT_STREAM=1                     # 1 for streaming, 0 for non-stream
PROMPTOPT_TIMEOUT=20                   # Timeout in seconds

# Development/Debug
PROMPTOPT_DRYRUN=0                     # Set to 1 for offline testing
PROMPTOPT_DRYRUN_STREAM=0              # Simulate streaming in dry-run

# Raw-to-Prompt Tool (Optional)
RAW_TO_PROMPT_DIR=C:\path\to\raw-to-prompt  # Override default path

# Other Service Credentials
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...
GROQ_API_KEY=...
HUGGINGFACE_TOKEN=hf_...
GITHUB_TOKEN=ghp_...
NPM_TOKEN=npm_...
```

### Environment Variables

#### API Configuration
- `OPENROUTER_API_KEY` - OpenRouter API key (auto-detected by `sk-or-` prefix)
- `OPENAI_API_KEY` - OpenAI API key
- `OPENAI_BASE_URL` - Override API base URL (e.g., OpenRouter endpoint)
- `OPENAI_MODEL` - Default model selection

#### PromptOpt Configuration
- `PROMPTOPT_MODE` - `meta` (create) or `edit` (improve)
- `PROMPTOPT_PROFILE` - `browser|coding|general|rag|writing|custom`
  - **custom**: Opens dialog for user-defined instructions (no meta-prompt file fallback)
- `PROMPTOPT_STREAM` - `1` for live streaming output, `0` for single response
- `PROMPTOPT_TIMEOUT` - Request timeout in seconds (default: 20)

#### Development Modes
- `PROMPTOPT_DRYRUN=1` - Offline testing (no network calls)
- `PROMPTOPT_DRYRUN_STREAM=1` - Simulate streaming in offline mode

#### Hotstring Environment Variables
API key hotstrings automatically expand credentials from environment:
- `OPENROUTER_API_KEY` → `Orouterkey` hotstring
- `OPENAI_API_KEY` → `OAIKey` hotstring
- `OPENAI_API_KEY_2` → `OAI2Key` hotstring (secondary)
- `ANTHROPIC_API_KEY` → `ClaudeKey` hotstring
- `ZAI_API_KEY` → `zaikey` hotstring
- `GEMINI_API_KEY` → `geminikey` hotstring
- `GROQ_API_KEY` → `groqkey` hotstring
- `HF_TOKEN` → `hftoken` hotstring
- `GH_TOKEN` → `gittoken` hotstring
- `NPM_TOKEN` → `npmtoken` hotstring
- And more (see Complete Hotstring Reference section)

#### Raw-to-Prompt Tool Configuration
- `RAW_TO_PROMPT_DIR` - Path to raw-to-prompt tool directory (optional, defaults to hard-coded path)
  - If set, must point to directory containing `main.py`
  - Tool validates path and Python availability before launching

### Model Selection

Available models (auto-updated via GUI picker):
- `openai/gpt-oss-120b` (default)
- `moonshotai/kimi-k2-0905`
- `z-ai/glm-4.5v`
- `deepseek/deepseek-chat-v3.1:free`
- `qwen/qwen3-next-80b-a3b-thinking`
- `openai/gpt-5-mini`

---

## Development Resources

### Architecture Documents
- **AGENTS.md** - System architecture, agent conventions, modularization plan
- **CLAUDE.md** - AI coding guidelines, development commands, testing procedures
- **CONTRIBUTING.md** - Contribution guidelines

### Testing & Debugging

#### Live Testing
```
1. Launch Template.ahk
2. Select text in any application
3. Press Ctrl+Alt+P
4. View logs: Get-Content -Tail 80 $env:TEMP\promptopt_*.log
```

#### Offline Testing (Dry-Run Mode)
```
# Set environment variables
$env:PROMPTOPT_DRYRUN="1"
$env:PROMPTOPT_DRYRUN_STREAM="1"  # Optional: simulate streaming

# Now use normally - no network calls will be made
```

#### Direct PowerShell Testing
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\promptopt\promptopt.ps1 `
  -SelectionFile "$env:TEMP\sel.txt" `
  -OutputFile "$env:TEMP\out.txt" `
  -MetaPromptDir . `
  -LogFile "$env:TEMP\promptopt_test.log" `
  -Model "gpt-4o-mini" `
  -Mode meta `
  -CopyToClipboard
```

#### Viewing Logs
```powershell
Get-Content -Tail 80 $env:TEMP\promptopt_*.log
```

### File Structure for Development

- **Path Independence:** Use relative paths where possible
- **Backwards Compatibility:** All existing hotkeys/hotstrings must work unchanged
- **Modularization:** Files organized into functional directories
- **Security:** API keys never hardcoded; use environment variables only

### Development Workflow

1. **Read** AGENTS.md for architecture overview
2. **Check** CLAUDE.md for coding guidelines
3. **Test** offline with `PROMPTOPT_DRYRUN=1`
4. **Verify** hotkeys work with live testing
5. **Document** changes in PLAN.md

---

## Safety & Troubleshooting

### Safety Notes

- ✅ All triggers use **multi-key combinations** - prevents accidental firing
- ✅ Hotstrings use **distinctive prefixes** unlikely in normal typing
- ✅ **No single-key hotkeys** that could interfere with applications
- ✅ Clipboard operations **preserve original content** when possible
- ✅ **Temp files auto-cleaned** on exit
- ✅ **No destructive operations** without explicit user action
- ✅ **API keys never logged** - credentials stay in environment only
- ✅ **Secrets never exposed** in command-line arguments or log files

### Troubleshooting

#### PromptOpt Not Working
1. **Check `.env` file exists** with valid `OPENROUTER_API_KEY` or `OPENAI_API_KEY`
2. **Test offline first**: `$env:PROMPTOPT_DRYRUN=1` (no network calls)
3. **Check logs**: `Get-Content -Tail 80 $env:TEMP\promptopt_*.log`
4. **Verify Python is installed**: Script auto-detects Python, shows error if missing
5. **Check meta-prompts directory**: Should be at `meta-prompts/` relative to script root

#### Raw-to-Prompt Tool Not Working
1. **Check path**: Set `RAW_TO_PROMPT_DIR` in `.env` or ensure default path exists
2. **Verify Python**: Tool checks for Python before launching
3. **Check main.py exists**: Path must contain `main.py` file
4. **Error messages**: Tool shows helpful error tooltips if path/Python invalid

#### PK_PROMPT Clipboard Automation Not Working
1. **Check clipboard guard**: If clipboard operations seem stuck, restart Template.ahk
2. **Verify prefix**: Clipboard must start with `PK_PROMPT` exactly
3. **Check busy state**: Only one PK_PROMPT operation at a time
4. **Temp file cleanup**: Temp files auto-delete after processing

#### Hotkeys Not Firing
1. Ensure `Template.ahk` is running (check system tray)
2. Check for conflicts with application shortcuts
3. Try pressing with correct modifier combination (e.g., Ctrl+Alt+P, not just Ctrl+P)
4. Restart `Template.ahk` if hotkeys become unresponsive

#### Hotstrings Not Expanding
1. Verify hotstring trigger (e.g., `Orouterkey` - case-sensitive)
2. Check for conflicts with application text processing
3. Ensure environment variables are set (for API key hotstrings)
4. Restart `Template.ahk` if needed

#### API Authentication Failed
1. Verify `OPENROUTER_API_KEY` or `OPENAI_API_KEY` in `.env`
2. Check key format matches provider (e.g., `sk-or-` for OpenRouter, `sk-` for OpenAI)
3. Verify key is not expired or revoked in provider console
4. Check internet connection and firewall rules

#### Streaming Not Working
1. Verify `PROMPTOPT_STREAM=1` in `.env`
2. Check `PROMPTOPT_TIMEOUT` is not too short (default: 20 seconds)
3. Test with longer prompts first
4. Check network latency with provider

### Getting Help

1. **Check logs** first: `$env:TEMP\promptopt_*.log`
2. **Test offline**: `$env:PROMPTOPT_DRYRUN=1`
3. **Review CLAUDE.md** for development guidelines
4. **Check AGENTS.md** for architecture details

---

## Daily Usage Guide

### Common Workflows

#### 1. Optimize Text for AI (Most Common)
```
1. Select text in any app (browser, editor, etc.)
2. Press Ctrl+Alt+P
3. Wait 2-5 seconds (see tooltip progress)
4. Optimized prompt is in clipboard - just paste!
```

**Pro Tips:**
- Hold `Shift` while pressing `Ctrl+Alt+P` to force profile picker
- First run shows profile/model picker - select once, it remembers
- Streaming mode shows live preview in tooltip (if `PROMPTOPT_STREAM=1`)

#### 2. Quick API Key Insertion
```
Type: Orouterkey
Gets: Your OpenRouter API key (from .env)
```

Perfect for:
- Config files
- Terminal commands
- Private code repositories
- API testing

#### 3. Mouse-Only Copy/Paste
```
Copy: Alt+RButton (right-click while holding Alt)
Paste: Alt+LButton (left-click while holding Alt)
```

Great for:
- One-handed operation
- Touchpad users
- Accessibility

#### 4. Tab Navigation Without Keyboard
```
Next tab: Ctrl+WheelDown
Previous tab: Ctrl+WheelUp
```

Works in:
- Browsers (Chrome, Edge, Firefox)
- VS Code, Notepad++
- Any app with tabs

### Most Used Features

| Feature | Hotkey | What It Does | When to Use |
|---------|--------|--------------|-------------|
| Optimize prompt | `Ctrl+Alt+P` | Transform selected text to AI prompt | Converting notes/questions to optimized prompts |
| Copy text | `Alt+RButton` | Copy selection (mouse-friendly) | One-handed copying |
| Paste text | `Alt+LButton` | Paste (mouse-friendly) | One-handed pasting |
| Next tab | `Ctrl+WheelDown` | Navigate tabs with mouse wheel | Quick tab switching |
| Volume control | `Ctrl+Alt+WheelUp/Down` | Adjust volume by 10 dB | Fine volume control |
| Play/Pause | `Ctrl+Alt+MButton` | Media control | Quick media toggle |

### Most Used Hotstrings

| Hotstring | Expands To | Use Case |
|-----------|-----------|----------|
| `Orouterkey` | OpenRouter API key | API testing, config files |
| `OAIKey` | OpenAI API key | Direct OpenAI access |
| `zaikey` | ZAI API key | ZAI service integration |
| `sdframework` | Self-Discover framework | AI reasoning framework template |
| `gprompter` | Prompt offloading template | Gemini CLI helper text |

---

## File Organization Summary

### By Size (Largest First)
1. `hotstrings/templates.ahk` - 65.4 KB (large templates)
2. `Template.ahk` - 12.8 KB (main entry point)
3. `tools/directorymapper.ahk` - 12.8 KB (directory mapping)
4. `promptopt/promptopt.ahk` - 17.6 KB (orchestrator)
5. `promptopt/promptopt.ps1` - 11.6 KB (bridge)
6. `promptopt/promptopt.py` - 12.3 KB (API client)

### By Function
- **Core:** Template.ahk, environment.ahk
- **AI:** promptopt/* (3 files), meta-prompts/* (12 files)
- **Hotkeys:** hotkeys/* (3 files)
- **Hotstrings:** hotstrings/* (3 files)
- **Tools:** tools/* (4 files)
- **Documentation:** docs/* (4 files)

### Configuration Files
- `.env` - Secrets and settings
- `.gitignore` - Git exclusions
- `PLAN.md` - Development roadmap
- `AGENTS.md` - Architecture
- `CLAUDE.md` - Coding guidelines
- `CONTRIBUTING.md` - Contribution rules

---

## For More Information

- **Architecture & Modularization:** See `AGENTS.md`
- **Coding Guidelines:** See `CLAUDE.md`
- **Contribution Rules:** See `CONTRIBUTING.md`
- **Development Plan:** See `PLAN.md`
- **Configuration Reference:** See `CLAUDE.md` (environment section)

---

**Last Updated:** 2025-01-XX
**Version:** Complete Index v2.1

---

## Quick Reference Card

### Top 5 Hotkeys
1. `Ctrl+Alt+P` - Optimize selected text to AI prompt
2. `Alt+RButton` - Copy (mouse)
3. `Alt+LButton` - Paste (mouse)
4. `Ctrl+WheelDown/Up` - Navigate tabs
5. `Ctrl+Alt+WheelUp/Down` - Volume control

### Top 5 Hotstrings
1. `Orouterkey` - OpenRouter API key
2. `OAIKey` - OpenAI API key
3. `zaikey` - ZAI API key
4. `sdframework` - Self-Discover framework
5. `gprompter` - Gemini CLI helper

### Essential .env Variables
```env
OPENROUTER_API_KEY=sk-or-...    # Required for PromptOpt
PROMPTOPT_STREAM=1              # Enable live preview
PROMPTOPT_PROFILE=browser       # Default profile
```

**Print this section and keep it handy!**
