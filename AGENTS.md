# Agent Brain / System Prompt

This document serves as the **single source of truth** for agent-facing system context, operating procedures, and file references for working with this codebase.

## Purpose & Scope

You are working on **PromptOpt**, a Windows automation tool that optimizes prompts using AI. The system uses a multi-layer architecture: **AHK → PowerShell → Python** to turn selected text into highly-optimized prompts via OpenAI/OpenRouter APIs.

**Core workflow:**
1. User selects text in any application
2. Presses hotkey (`Ctrl+Alt+P` by default)
3. System copies selection, loads meta-prompt, calls AI API
4. Optimized prompt is returned to clipboard
5. User pastes the improved prompt

## Tools & Constraints

### Search Tools
- **Prefer ripgrep** (`grep` tool) when possible for code search
- Use `codebase_search` for semantic queries
- Use `glob_file_search` for finding files by pattern

### Critical Constraints
- **DO NOT modify `core/Template.ahk`** without explicit approval from user/maintainers
- **Prefer tuning via environment variables and meta-prompt edits** over code changes
- **Never log or expose API keys** - keys are passed via environment, not command-line
- **Keep changes minimal and focused** - avoid unrelated refactors
- **Maintain backwards compatibility** - all existing hotkeys/hotstrings must continue working

### AHK Hotstring Safety (MANDATORY)
- Use expression-style assembly for multi-line hotstrings: `text := ""` then many `text .= "...``n"` lines, followed by `SendHotstringText(text)`. Avoid continuation sections `( LTrim … )` when content contains leading `#`/`;`/`<tag>` lines, which AHK can misinterpret as directives or comments.
- Inside expression strings, escape quotes by doubling them: `""` (do not use backslashes like `\"`). Example: `text .= "key=""value"""` renders `key="value"`.
- For tags with attributes, split angle-brackets to avoid parser ambiguity: `"<" . "TestCode language=""[LANGUAGE]"">"` and `"</" . "TestCode>"`.
- Prefer raw hotstrings for symbol-heavy prompts: `:*R:trigger::`. Still route output through `SendHotstringText(text)` to paste reliably and restore the clipboard.
- Save `.ahk` files as UTF‑8 with BOM. Prefer ASCII quotes; if you paste smart quotes or glyphs (—, →, ×), keep them inside strings and test expansions.
- Always terminate lines with `` `n ``; do not rely on implicit newlines from continuation sections.
- **Critical Fix for "Missing space or operator" errors**: When dealing with JSON-heavy content or multiple doubled quotes in succession, avoid triple-quote patterns like `"""`. Instead:
  - Use `Chr(34)` to represent literal quotes: `text .= "key" . Chr(34) . ":" . Chr(34) . "value" . Chr(34)` produces `key":"value"`.
  - For large JSON blocks, split each line using concatenation with `Chr(34)` to avoid parser ambiguity.
  - Example fix: Replace `text .= """title"": ""string"",` with `text .= Chr(34) . "title" . Chr(34) . ": " . Chr(34) . "string" . Chr(34) . ",`.
- Troubleshooting: if you see "missing ending percent sign" or "leftmost character illegal," scan for un-doubled quotes or leading `#` in continuation blocks. If you see "missing space or operator before this" near quoted sections, replace triple-quote patterns with `Chr(34)` concatenations.

### AHK v2 Pre-emptive Debugging Patterns (CRITICAL)

To prevent the syntax errors we just encountered, use these systematic validation patterns:

#### 1. Hotstring Validation (HIGHEST PRIORITY)
**Issue**: Missing required options prefix causes runtime errors
**Pattern to check**: `Hotstring\("([^:*][^"]*)"`
**Fix**: Add `:*:` for immediate expansion or proper options
**Example**: `Hotstring("trigger", ...)` → `Hotstring(":*:trigger", ...)`

#### 2. Deprecated Function Detection (HIGH PRIORITY)
**Functions to replace**:
- `SoundSet` → `SoundSetVolume` (volume control)
- `SendRaw` → `SendText` (raw text output)
- `EnvGet, var, VARNAME` → `var := EnvGet("VARNAME")` (environment variables)

#### 3. Quote Escaping Issues (CRITICAL)
**Pattern**: Unescaped double quotes within string concatenation
**Fix**: Use `Chr(34) . "text" . Chr(34)` pattern instead of nested quotes
**Example**: `"text "more text"` → `"text " . Chr(34) . "more text" . Chr(34)`

#### 4. Function Structure Validation
**Check for**: Missing closing braces `}`, proper AHK v2 parameter syntax (`&param` for ByRef)
**Pattern**: Functions without proper termination

#### Systematic Validation Commands
Use these grep patterns to scan for issues:
```bash
# Hotstring validation
rg 'Hotstring\("([^:*][^"]*)"'

# Deprecated functions
rg '\b(SoundSet|SendRaw)\b'

# Quote issues in strings
rg '"[^"]*"[^,)]*"'
```

**Execute this validation when**:
- New AHK files are added
- Major syntax changes are made
- Before script deployment
- After runtime errors occur

**Priority**: Fix Critical/High issues immediately as they prevent script loading.

### Development Preferences
- Use environment variables for configuration (`.env` file)
- Keep secrets out of source code
- Maintain backups of core scripts in `BACKUPS/` subdirectory when making changes
- Test changes incrementally after each phase

### Claude Code Settings Format (CRITICAL)
**WARNING**: Claude Code's `settings.json` requires strict formatting:
- **Must NOT have UTF-8 BOM** (Byte Order Mark) - Claude Code will reject the file as "Invalid or malformed JSON"
- Use UTF-8 encoding without BOM
- Standard JSON formatting with 2-space indentation
- When writing settings.json from PowerShell, use the `Write-CleanJson` function from `.claude/switch-claude-endpoint.ps1` which ensures proper formatting
- Verify settings with: `Get-Content 'C:\Users\[USER]\.claude\settings.json' -Raw | ConvertFrom-Json`
- Check for BOM: First 3 bytes should be `{`, newline, space (123, 10, 32) NOT `0xEF, 0xBB, 0xBF`
- After modifying settings.json or environment variables, **restart Claude Code completely** for changes to take effect

## Operating Procedures / Runbooks

### Architecture Overview

The codebase follows a strict pipeline design:

```
User Input (hotkey) 
  → core/Template.ahk (entry point)
    → promptopt/promptopt.ahk (AHK v2 orchestrator)
      → promptopt/promptopt.ps1 (PowerShell bridge)
        → promptopt/promptopt.py (Python API client)
          → OpenAI/OpenRouter API
            → Optimized prompt → Clipboard
```

### Key Components

1. **core/Template.ahk**
   - Main hotkey entry point (DO NOT MODIFY without approval)
   - Loads environment variables from `.env`
   - Provides hotkey triggers for PromptOpt system
   - Includes other modules (hotstrings, hotkeys, tools)

2. **promptopt/promptopt.ahk**
   - AHK v2 orchestrator
   - Copies selection, shows tooltips, spawns PowerShell
   - Handles profile/model selection via GUI pickers
   - Shows custom instructions dialog when "custom" profile is selected

3. **promptopt/promptopt.ps1**
   - Bridge and control plane
   - Loads meta prompts from `meta-prompts/Meta_Prompt*.md`
   - Accepts `-CustomPromptFile` parameter for custom profile (user-defined instructions)
   - Honors environment variable overrides
   - Locates Python, calls `promptopt.py`
   - Writes logs to `%TEMP%\promptopt_*.log`

4. **promptopt/promptopt.py**
   - API client supporting OpenAI-compatible Chat Completions
   - Supports non-stream and SSE streaming modes
   - Writes output incrementally to temp file for live preview
   - Detects OpenRouter vs OpenAI by base URL or `sk-or-` key prefix

5. **meta-prompts/Meta_Prompt*.md**
   - Contain `META_PROMPT = """ ... """` anchors for meta-prompt content
   - Base: `Meta_Prompt.md` (default), `Meta_Prompt_Edits.md` (edit mode)
   - Profile variants: `Meta_Prompt.{browser,coding,rag,general,writing,custom}.md`
   - **Custom profile**: When "custom" is selected, user enters instructions via dialog; saved to temp file and passed directly to Python (no fallback to base meta-prompt)

### Environment Variables

**API Keys:**
- `OPENAI_API_KEY` - OpenAI key (preferred default)
- `OPENROUTER_API_KEY` - Preferred when `OPENAI_BASE_URL` points to OpenRouter

**Core Settings:**
- `PROMPTOPT_MODE` - `meta` (default) or `edit`
- `OPENAI_MODEL` - Model preference (default: `gpt-5`)
- `OPENAI_BASE_URL` - Override base URL (e.g., `https://openrouter.ai/api/v1`)
- `PROMPTOPT_PROFILE` - Domain profile: `browser`, `coding`, `rag`, `general`, `writing`, `custom`
  - **Custom profile**: Opens dialog for user-defined instructions (no meta-prompt file fallback)
- `PROMPTOPT_STREAM` - Set to `1` to enable live streaming output (recommended)
- `PROMPTOPT_TIMEOUT` - Request timeout in seconds (default: 20)

**Development/Debug:**
- `PROMPTOPT_DRYRUN` - Set to `1` for offline mode (no network calls)
- `PROMPTOPT_DRYRUN_STREAM` - Set to `1` to simulate streaming in dry-run

### Meta-Prompt Tuning Rules

- Output must contain **only the final prompt** (no preamble/postscript)
- Begin with a **single-line Prompt Title**, then the optimized body
- Do not add labels like "Title:" or "Final Prompt:"
- JSON-only tasks: specify exact schema and forbid code fences and extra prose
- Cookbook-aligned rules: resolve contradictions; define constraints, priorities, and refusal policies
- Tune agentic eagerness only when appropriate; include minimal examples only when essential
- Never reveal chain-of-thought
- Edit mode (`Meta_Prompt_Edits.md`): requires `<reasoning>…</reasoning>` analysis first; immediately after, start the title line and then the optimized prompt body

### Testing Procedures

**Live Testing:**
1. Launch `core/Template.ahk`
2. Select text in any app
3. Press `Ctrl+Alt+P`
4. Tail logs: `Get-Content -Tail 80 $env:TEMP\promptopt_*.log`

**Offline Testing:**
- Set `PROMPTOPT_DRYRUN=1` (and optionally `PROMPTOPT_DRYRUN_STREAM=1`) to validate UI and clipboard without network

**Direct PowerShell Bridge Test:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\promptopt\promptopt.ps1 -SelectionFile "$env:TEMP\sel.txt" -OutputFile "$env:TEMP\out.txt" -MetaPromptDir .\meta-prompts -LogFile "$env:TEMP\promptopt_test.log" -Model "gpt-4o-mini" -Mode meta -CopyToClipboard
```

## File Map of Agent-Facing Notes

This workflow depends on the following agent-facing files:

### Core Documentation
- **AGENTS.md** (this file) - System prompt and agent conventions
- **CLAUDE.md** - Provider-specific mirror (Anthropic-focused) aligned with AGENTS.md
- **PLAN.md** - Full plan (North Star, strategy, roadmap) + Immediate Next Steps
- **TODO.md** - Active, short-horizon tasks only (next 5-20 tasks in execution order)

### User-Facing Documentation
- **docs/README.md** - Project overview and entry point for users
- **docs/CONTRIBUTING.md** - Development guidelines and contribution instructions
- **docs/INDEX.md** - Documentation index and discoverability

### Code Components
- **core/Template.ahk** - Entry point (DO NOT MODIFY without approval)
- **promptopt/** - Prompt optimization system (AHK, PowerShell, Python)
- **hotstrings/** - Text expansion hotstrings
- **hotkeys/** - Hotkey-only scripts
- **tools/** - Standalone utility scripts
- **meta-prompts/** - Meta prompt templates (`Meta_Prompt*.md`)

### Configuration
- **.env** - Environment variables (API keys, settings) - keep secrets here

## File Organization: Modular Structure

```
Scripts/
├── core/                          # Essential system files
│   ├── Template.ahk               # Main hotkey entry point (DO NOT MODIFY without approval)
│   └── environment.ahk            # [TBD] Centralized .env loading and helpers
│
├── promptopt/                     # Prompt optimization system
│   ├── promptopt.ahk              # AHK v2 orchestrator
│   ├── promptopt.ps1              # PowerShell bridge & control plane
│   ├── promptopt.py               # Python API client
│   ├── gui.ahk                    # [TBD] Extract GUI components
│   └── config.ahk                 # [TBD] Profile/model management
│
├── hotstrings/                    # Text expansion hotstrings
│   ├── api-keys.ahk               # API key hotstrings (security-focused)
│   ├── general.ahk                # General text expansions
│   ├── templates.ahk              # Large multiline templates (sdframework, task-triage, etc.)
│   └── solar.ahk                  # [TBD] Solar/business specific hotstrings
│
├── hotkeys/                       # Hotkey-only scripts
│   ├── media.ahk                  # [TBD] Media control keys
│   ├── windows.ahk                # [TBD] Window management
│   └── mouse.ahk                  # [TBD] Mouse button remapping
│
├── tools/                         # Standalone utility scripts
│   ├── directorymapper.ahk        # Directory mapping tool
│   ├── prompter.ahk               # Prompt helper tool
│   ├── tabfiller.ahk              # Tab-filling utility
│   ├── xml_tag_autoclose.ahk      # XML tag auto-closer
│   └── ahk-v2-debugging-patterns.md # Comprehensive debugging validation guide
│
├── meta-prompts/                  # Meta prompt documentation
│   ├── Meta_Prompt.md             # Base meta prompt
│   ├── Meta_Prompt_Edits.md       # Edit mode meta prompt
│   ├── Meta_Prompt.*.md           # Profile variants (browser, coding, rag, general, writing)
│   └── Meta_Prompt_Edits.*.md     # Profile-specific edit modes
│
└── docs/                          # Documentation
    ├── AGENTS.md                  # This file (agent-facing)
    ├── CLAUDE.md                  # Provider-specific mirror (agent-facing)
    ├── CONTRIBUTING.md            # Development guidelines (user-facing)
    └── README.md                  # Project overview (user-facing)
```

**[TBD]** = To be completed in MED/HIGH priority phases.

## Interfaces (Inputs/Outputs)

### Input
- User-selected text (via clipboard)
- Hotkey trigger (`Ctrl+Alt+P` or mouse button)
- Environment variables (API keys, mode, model, profile)
- Meta-prompt templates (from `meta-prompts/` directory)

### Output
- Optimized prompt (written to clipboard)
- Logs (written to `%TEMP%\promptopt_*.log`)
- Tooltips (live preview during streaming)

### JSON Contracts
None currently - the system uses text-based prompts and responses.

## Links to Related Documentation

- **PLAN.md** - [See Immediate Next Steps](./PLAN.md#immediate-next-steps) for current priorities
- **TODO.md** - [See Next 5-20 Tasks](./TODO.md) for execution order
- **CLAUDE.md** - [Provider-specific summary](./CLAUDE.md) aligned with this document
- **docs/README.md** - [User-facing overview](./docs/README.md) for setup and usage
- **AHK Hotstring Safety** - See the safety rules above; mirrored guidance in [CLAUDE.md](./CLAUDE.md#tools--guardrails-condensed)

## Notes

- Keep secrets out of source where possible; prefer environment variables
- The pipeline is resilient across OS components by using files for handoff and Python for network/JSON
- All existing hotkeys and hotstrings must continue working after modularization (backwards compatibility)
- Do not remove files; only delete helper or temporary text artifacts that were created as part of a process (e.g., scratch TODO notes you just generated)
