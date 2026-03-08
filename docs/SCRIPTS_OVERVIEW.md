# Scripts Folder Visual Guide

> **Goal:** One glance understanding of everything under `Scripts/` 1 page (front + back). Keep this next to your keyboard when onboarding or debugging.

---

## 1. System at a Glance

```
 Selection / Trigger                      Processing Stack                           Output
 ─────────────────────────        ───────────────────────────────────────      ───────────────────────
 • Ctrl+Alt+P / PK_PROMPT  ──▶    Template.ahk (AHK v1 orchestrator)           • Clipboard (optimized prompt)
 • ????⎵ hotstring        ──▶    │  ↳ promptopt.ahk (AHK v2 UI+copy)           • Inline paste (PK workflows)
 • Ctrl+Alt+Apps key menu  ─▶    │      ↳ promptopt.ps1 (PowerShell bridge)    • Tooltip status + log files
 • Shift+Alt+RButton (Raw) ─▶    │          ↳ promptopt.py (Python API)        • Optional GUI preview
                                 │
                                 └── Tools/Hotstrings (api-keys, templates, etc.)
```

Color legend:
- **Blue** (Triggers) = hotkeys/hotstrings you press
- **Gray** (Stack) = files you edit to change behavior
- **Green** (Output) = what the user sees (clipboard, GUI, menus)

---

## 2. Top Workflows

| Workflow | Trigger(s) | What It Does | Key Files |
| --- | --- | --- | --- |
| **PromptOpt (main)** | `Ctrl+Alt+P`, `Ctrl+Alt+XBtn1`, PK hotstring, context menu | Copies selection → loads meta-prompt → hits OpenAI/OpenRouter → clipboard result + optional GUI | `Template.ahk`, `promptopt/promptopt.{ahk,ps1,py}`, `meta-prompts/*.md` |
| **PK Quick Optimize** | `PK_PROMPT …⎵` hotstring, `????⎵` smart trigger | Inline optimization without manual copy; PK handler writes temp files + pastes optimized text | `Template.ahk` (PK functions block) |
| **Raw-to-Prompt GUI** | `Shift+Alt+Right Click` | Sends selection to PySide6 app for multi-step brief building | `Template.ahk`, `raw-to-prompt/main.py` (outside repo path configured near top) |
| **Context Menu (PromptOpt)** | `Ctrl+Alt+Apps`, `Ctrl+Alt+Shift+P` | Right-click-style menu: optimize selection / field / clipboard | `Template.ahk` (PK_ShowPromptOptMenu + labels) |

---

## 3. Hotkeys Cheat Grid (Highlights)

| Category | Combo | Effect |
| --- | --- | --- |
| Prompting | `Ctrl+Alt+P` | PromptOpt orchestration (AHK v2 preferred) |
|  | `Shift+Alt+RButton` | Launch Raw-to-Prompt UI on current selection |
| Clipboard | `Alt+2` / `Alt+V` | Secondary clipboard save / restore |
|  | `Ctrl+Shift+XBtn2` | Flatten selection into single line |
| Window Mgmt | `Ctrl+XBtn1` / `Ctrl+XBtn2` | Virtual desktop left/right |
|  | `Ctrl+RButton` | Win+Tab switcher |
| Media | `Ctrl+Alt+MButton` | Play/Pause |
|  | `Ctrl+Alt+RButton / LButton` | Next / Previous track |
| Mouse Utils | `Alt+RButton` / `Alt+LButton` | Copy / Paste with mouse |
| Safety | `Home` | Reload/exit Template.ahk |

> **Tip:** All combos use 2+ modifiers or mouse buttons → zero accidental triggers while typing.

Full tables remain in `docs/README.md`, but this page keeps the “daily driver” set handy.

---

## 4. PK Automation Matrix

| Trigger | Scope | Result | Notes |
| --- | --- | --- | --- |
| `PK_PROMPT …⎵` | Inline sentence/paragraph | PromptOpt result pasted inline | Requires typing prefix (no colon) then space/enter |
| `????⎵` | Entire active field | Selects all, optimizes, pastes | Use when you want to upgrade huge prompts fast |
| Clipboard change w/ `PK_PROMPT` | Clipboard text | Clipboard replaced with optimized text | Runs when user copies PK-prefixed text |
| Context Menu → Optimize Selection | Current highlight | PromptOpt, keeps surrounding text | Access via `Ctrl+Alt+Apps` or `Ctrl+Alt+Shift+P` |

Guard rails:
- `PK_CLIPBOARD_GUARD` prevents recursion
- `PK_PROMPTOPT_BUSY` avoids double launches
- Temp files named `pk_promptopt_*` clean themselves after success/failure

---

## 5. Hotstring Highlights

| Module | Trigger Examples | Purpose |
| --- | --- | --- |
| `hotstrings/api-keys.ahk` | `Orouterkey`, `ClaudeKey`, `gittoken` | Paste env-stored secrets via secure SendHotstringText |
| `hotstrings/general.ahk` | `p1approval`, `custcom`, `textnote` | Frequently used solar/ops snippets |
| `hotstrings/templates.ahk` | `sdframework`, `task-triage`, `prioritization` | Multi-hundred-line prompt frameworks inserted safely |

Implementation rules (baked into `core/environment.ahk`):
- Expression-style assembly only (`text := ""` → `text .= …`)
- All output piped through `SendHotstringText` so clipboard restores automatically
- Escape quotes by doubling (`""`) and split XML tags to avoid parser confusion

---

## 6. Standalone Tools & Utilities

| Tool | File | Snapshot |
| --- | --- | --- |
| Directory Mapper | `tools/directorymapper.ahk` | Builds visual map of folders; useful for client deliverables |
| Prompter GUI | `tools/prompter.ahk` | Mini prompt optimizer (WinHTTP + OpenRouter) |
| Tab Filler | `tools/tabfiller.ahk` | Walks tab order + autofills forms |
| XML Tag Autoclose | `tools/xml_tag_autoclose.ahk` | Auto-completes tags when writing HTML/XML |

---

## 7. Meta-Prompt Capsules

| Profile | File | When to use |
| --- | --- | --- |
| `browser` | `Meta_Prompt.browser.md` | Research, SERP inspection |
| `coding` | `Meta_Prompt.coding.md` | Refactors, bug triage |
| `general` | `Meta_Prompt.general.md` | Default fallback |
| `rag` | `Meta_Prompt.rag.md` | Retrieval / knowledge-base prompts |
| `writing` | `Meta_Prompt.writing.md` | Blogs, emails, narrative |
| `*_Edits` | `Meta_Prompt_Edits.*.md` | Use when improving an existing system prompt |

**Philosophy:** Title line first, then optimized prompt body only; edit mode wraps reasoning in `<reasoning>…</reasoning>` before final content.

---

## 8. Setup & Safety Quick Reference

1. **Environment** – `.env` contains API keys + defaults (`OPENAI_MODEL`, `PROMPTOPT_MODE`, etc.). Loaded at runtime by `core/environment.ahk` and again inside `promptopt.ps1`.
2. **Secrets** – Never hardcode keys. Hotstrings pull from env; PromptOpt passes via files so they avoid command lines/logs.
3. **Testing** – Use `PROMPTOPT_DRYRUN=1` to simulate network calls (streams fake output to temp files).
4. **Logs** – PromptOpt PowerShell bridge writes `%TEMP%\promptopt_*.log`. Raw-to-Prompt UI errors show Qt dialog.
5. **Reload** – Tap `Home` key to reload Template.ahk after edits, or exit entirely.
6. **Backups** – Archive versions of Template.ahk live in `/archive` for quick diff/restore.

---

## 9. Quick Troubleshooting Grid

| Symptom | Likely Cause | Fix |
| --- | --- | --- |
| PromptOpt tooltip never appears | AHK v2 missing or script path wrong | Ensure `AHK_V2_PATH_A/B` exist; fallback will show toast |
| PK triggers loop endlessly | Missing guard variables | Verify `PK_CLIPBOARD_GUARD` resets (line ~25 + helper updates) |
| Raw-to-Prompt window opens blank | Selection not copied | Confirm highlight before `Shift+Alt+RButton`; review `RAW_TO_PROMPT_DIR` path |
| API errors | Missing env keys / model mismatch | Check `.env`, `promptopt/logs`, confirm provider base URL |

Keep this README alongside `docs/README.md`: use this for orientation, the other for exhaustive reference.
