# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

Windows automation toolkit centered on an AHK → PowerShell → Python pipeline for AI-driven prompt optimization (“PromptOpt”), plus hotkeys, hotstrings, and utility tools. Core usage is launching `Template.ahk`, selecting text, and pressing Ctrl+Alt+P to stream an optimized prompt back to the clipboard.

Key tech:
- AutoHotkey v2 (user entry, hotkeys/hotstrings, UX/tooltips)
- PowerShell 5.1+ (bridge, env/config, logging, Python orchestration)
- Python 3.x (OpenAI-compatible Chat Completions client with streaming)

Primary dirs: `core/`, `promptopt/`, `meta-prompts/`, `hotkeys/`, `hotstrings/`, `tools/`, `docs/`.


## Commands (build, run, test, and common dev loops)

Prereqs
- Install AutoHotkey v2 (AHK v2). Default path checked by `LaunchTemplate.ps1` is `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`.
- Ensure Python 3 is on PATH (the bridge auto-detects `py|python|python3`).
- Create `.env` in repo root with API keys/settings (see docs/README.md → Configuration & Environment).

Launch main system (AHK)
- PowerShell: `powershell -NoProfile -ExecutionPolicy Bypass -File .\LaunchTemplate.ps1`
  - Or double-click `LaunchTemplate.ps1`.

Direct bridge test (single “test case” via PowerShell)
- Create a selection file and run the bridge end-to-end:
  - `"hello world" | Set-Content "$env:TEMP\sel.txt" -Encoding UTF8`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\promptopt\promptopt.ps1 -SelectionFile "$env:TEMP\sel.txt" -OutputFile "$env:TEMP\out.txt" -MetaPromptDir .\meta-prompts -LogFile "$env:TEMP\promptopt_test.log" -Model "gpt-4o-mini" -Mode meta -CopyToClipboard`
  - Tail logs: `Get-Content -Tail 80 "$env:TEMP\promptopt_*.log"`

Offline/dry-run (no network, useful for CI or quick dev)
- `setx PROMPTOPT_DRYRUN 1` then start a new shell, or in-session: `$env:PROMPTOPT_DRYRUN="1"`
- Optional streaming simulation: `$env:PROMPTOPT_DRYRUN_STREAM="1"`
- Re-run the direct bridge test or press Ctrl+Alt+P in AHK.

Provider routing and model overrides (env-driven)
- Prefer OpenAI: set `OPENAI_API_KEY`; leave `OPENAI_BASE_URL` unset (defaults to OpenAI)
- Prefer OpenRouter: set `OPENAI_BASE_URL=https://openrouter.ai/api/v1` and `OPENROUTER_API_KEY`
- Model hint: `OPENAI_MODEL` (e.g., `openai/gpt-oss-120b`, `gpt-4o-mini`, etc.)

Inspect streaming output file (while running)
- `Get-Content -Wait "$env:TEMP\out.txt"`

Hotstrings quality scan/fix (AHK content-specific linter)
- Report only: `powershell -NoProfile -ExecutionPolicy Bypass -File .\fix-ahk-strings.ps1 -ReportOnly`
- Apply safe replacements: `powershell -NoProfile -ExecutionPolicy Bypass -File .\fix-ahk-strings.ps1 -Fix`


## High-level architecture and flow

End-to-end PromptOpt pipeline
1. User highlights text in any app → presses Ctrl+Alt+P (or invokes PK/menus) in `core/Template.ahk`.
2. `promptopt/promptopt.ahk` (AHK v2) copies selection to a temp file, manages pickers/UX, and launches PowerShell.
3. `promptopt/promptopt.ps1` (bridge) loads `.env`, resolves model/provider, selects meta-prompt from `meta-prompts/Meta_Prompt*.md`, and locates Python.
4. The bridge calls `promptopt/promptopt.py` with system prompt + user selection, optionally enabling streaming.
5. Python writes incremental output to the target file; AHK shows tooltip preview; final output is copied to the clipboard.

Core components
- `core/Template.ahk`: AHK entry point. Hotkeys, hotstrings, UX glue. Do not modify without explicit approval.
- `promptopt/`:
  - `promptopt.ahk`: AHK v2 orchestrator for selection/GUI/stream preview.
  - `promptopt.ps1`: bridge/config/logging/provider/model resolution; Python discovery; dry-run support.
  - `promptopt.py`: OpenAI-compatible client; streaming and non-stream modes.
- `meta-prompts/`: Domain profiles and edit-mode variants. The bridge selects `Meta_Prompt*.md` based on `Mode` and `Profile`.
- `hotkeys/`, `hotstrings/`: User automation modules. Hotstrings include API-key expansions from env; large templates live in `hotstrings/templates.ahk`.
- `tools/`: Standalone helpers (e.g., `directorymapper.ahk`, `prompter.ahk`, etc.).

Operational guardrails (from docs/CLAUDE.md and CONTRIBUTING)
- Do not modify `core/Template.ahk` without explicit approval.
- Prefer environment variables and meta-prompt edits over code changes.
- Never log or pass secrets on command lines; keys come from env only.
- Maintain backward compatibility: existing hotkeys/hotstrings must continue working.

Logging and troubleshooting
- Bridge logs to `%TEMP%\promptopt_*.log` (daily files). Tail with `Get-Content -Tail 80`.
- Dry-run mode (`PROMPTOPT_DRYRUN=1`) exercises the full pipeline without network/keys; `PROMPTOPT_DRYRUN_STREAM=1` simulates streaming.
- If output seems missing, confirm Python is on PATH and meta-prompt file exists; see log tail for exact failure.


## Notes for agents working in this repo

- Source of truth docs: `docs/README.md` (complete index), `docs/CONTRIBUTING.md` (dev commands/policies), `CLAUDE.md` (constraints & quick commands), and `AGENTS.md` (architecture and conventions).
- Configuration is .env-first; the bridge also honors `OPENAI_MODEL`, `OPENAI_BASE_URL`, `PROMPTOPT_MODE`, `PROMPTOPT_PROFILE`, `PROMPTOPT_STREAM`, `PROMPTOPT_DRYRUN*`.
- For AHK content health, prefer non-destructive scans first (`fix-ahk-strings.ps1 -ReportOnly`).
- When adjusting behavior, start with meta-prompts in `meta-prompts/` and env flags before altering code.
