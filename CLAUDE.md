# Provider-Ready Summary (Anthropic)

This file provides a concise, provider-ready summary for Claude Code (claude.ai/code) when working with this repository. For detailed context, see **[AGENTS.md](./AGENTS.md)**.

## System Rules & Behaviors (Condensed)

You are working on **PromptOpt**, a Windows automation tool that optimizes prompts using AI via a multi-layer pipeline: **AHK → PowerShell → Python**.

### Core Workflow
1. User selects text → presses `Ctrl+Alt+P` → system optimizes → returns to clipboard
2. System uses meta-prompts from `meta-prompts/Meta_Prompt*.md` to guide optimization
3. Supports OpenAI and OpenRouter APIs with streaming support

### Critical Constraints
1. **DO NOT modify `core/Template.ahk`** without explicit approval
2. **Prefer environment variables and meta-prompt edits** over code changes
3. **Never log or expose API keys** - use environment variables only
4. **Maintain backwards compatibility** - all hotkeys/hotstrings must continue working
5. **Keep changes minimal and focused** - avoid unrelated refactors

## Tools & Guardrails (Condensed)

See also: the AHK hotstring safety rules in [AGENTS.md](./AGENTS.md#ahk-hotstring-safety-mandatory).

### Claude Code Settings (CRITICAL WARNING)
**settings.json formatting requirements**:
- Must be UTF-8 **without BOM** (Byte Order Mark) or Claude Code rejects as invalid
- Use `Write-CleanJson` function from `.claude/switch-claude-endpoint.ps1` when writing from PowerShell
- After modifying settings or environment variables, **fully restart Claude Code** to pick up changes

### Search Tools
- **Prefer ripgrep** (`grep` tool) for code search
- Use `codebase_search` for semantic queries
- Use `glob_file_search` for file pattern matching

### Architecture Components
- **core/Template.ahk** - Entry point (DO NOT MODIFY without approval)
- **promptopt/promptopt.ahk** - AHK v2 orchestrator
- **promptopt/promptopt.ps1** - PowerShell bridge (loads meta-prompts, calls Python)
- **promptopt/promptopt.py** - Python API client (OpenAI-compatible, streaming support)
- **meta-prompts/Meta_Prompt*.md** - Meta-prompt templates with `META_PROMPT = """ ... """` anchors

### Environment Variables
- `OPENAI_API_KEY` / `OPENROUTER_API_KEY` - API keys
- `PROMPTOPT_MODE` - `meta` (default) or `edit`
- `OPENAI_MODEL` - Model preference (default: `gpt-5`)
- `PROMPTOPT_STREAM` - Set to `1` for live streaming (recommended)
- `PROMPTOPT_DRYRUN` - Set to `1` for offline testing

### Meta-Prompt Rules
- Output must contain **only the final prompt** (no preamble/postscript)
- Begin with **single-line Prompt Title**, then optimized body
- JSON-only tasks: specify exact schema, forbid code fences
- Edit mode: start with `<reasoning>…</reasoning>`, then title and body
- Never reveal chain-of-thought

## Cross-Refs to AGENTS.md Sections

For detailed information, see:
- **[Purpose & Scope](./AGENTS.md#purpose--scope)** - Full workflow description
- **[Operating Procedures](./AGENTS.md#operating-procedures--runbooks)** - Architecture details and testing
- **[File Map](./AGENTS.md#file-map-of-agent-facing-notes)** - Complete file reference
- **[File Organization](./AGENTS.md#file-organization-modular-structure)** - Directory structure

## Development Commands

### Testing
```bash
# Live test (normal user flow)
# 1. Launch core/Template.ahk
# 2. Select text in any app
# 3. Press Ctrl+Alt+P

# Direct PowerShell bridge test
powershell -NoProfile -ExecutionPolicy Bypass -File .\promptopt\promptopt.ps1 -SelectionFile "$env:TEMP\sel.txt" -OutputFile "$env:TEMP\out.txt" -MetaPromptDir .\meta-prompts -LogFile "$env:TEMP\promptopt_test.log" -Model "gpt-4o-mini" -Mode meta -CopyToClipboard

# View logs
Get-Content -Tail 80 "$env:TEMP\promptopt_*.log"

# Offline testing
$env:PROMPTOPT_DRYRUN="1"
$env:PROMPTOPT_DRYRUN_STREAM="1"  # optional: simulate streaming
```

## File Organization

```
├── core/Template.ahk           # Entry point hotkey (DO NOT MODIFY)
├── promptopt/                   # Prompt optimization system
│   ├── promptopt.ahk           # AHK v2 orchestrator
│   ├── promptopt.ps1           # PowerShell bridge
│   └── promptopt.py            # Python API client
├── meta-prompts/                # Meta prompt templates
│   ├── Meta_Prompt.md          # Base meta prompt
│   ├── Meta_Prompt_Edits.md    # Edit mode meta prompt
│   └── Meta_Prompt.*.md        # Profile-specific variants
├── hotstrings/                  # Text expansion hotstrings
├── hotkeys/                     # Hotkey-only scripts
├── tools/                       # Standalone utility scripts
├── docs/                        # Documentation
│   ├── AGENTS.md               # Full system prompt (this file's source)
│   ├── CLAUDE.md               # This file
│   ├── CONTRIBUTING.md         # Development guidelines
│   └── README.md               # Project overview
└── .env                         # Environment variables (API keys, settings)
```

## Provider-Specific Notes

- This repository uses **AutoHotkey (AHK)** v2 for Windows automation
- Python 3.x required for API client
- PowerShell 5.1+ required for bridge script
- Supports OpenAI and OpenRouter APIs (OpenAI-compatible Chat Completions)
- Streaming mode provides live preview via tooltips

See **[AGENTS.md](./AGENTS.md)** for complete system context and runbooks.
