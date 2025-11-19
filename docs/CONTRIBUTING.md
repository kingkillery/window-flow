## Contributing to Prompt Optimizer

This repo implements an AHK → PowerShell → Python pipeline that turns selected text into a highly‑optimized prompt. Please read AGENTS.md first — it defines agent conventions and important constraints.

### Architecture
- `Template.ahk` — User hotkey entry (e.g., Ctrl+Alt+P). Triggers the optimizer. Do not change this file without explicit approval.
- `promptopt.ahk` — AHK v2 orchestrator: copies selection, shows tooltips, spawns PowerShell.
- `promptopt.ps1` — Bridge/control plane: loads meta prompts (`Meta_Prompt*.md`), honors env overrides, locates Python, calls `promptopt.py`, logs to `%TEMP%`.
- `promptopt.py` — API client (OpenAI‑compatible Chat Completions), supports non‑stream and SSE streaming; writes output file incrementally for live preview.
- `Meta_Prompt.md` / `Meta_Prompt_Edits.md` — Contain `META_PROMPT = """ ... """` anchors for the meta‑prompt content.

### Policies
- Do not modify `Template.ahk` unless explicitly approved by maintainers.
- Prefer tuning via environment variables and meta‑prompt edits over code changes.
- Never print or commit secrets. Keys are passed via environment variables, not command‑line args.
- Keep changes minimal and focused; avoid unrelated refactors.

### Environment Setup
- OpenAI default
  - Set `OPENAI_API_KEY`.
  - Leave `OPENAI_BASE_URL` unset (defaults to `https://api.openai.com/v1`).
- OpenRouter
  - Set `OPENAI_BASE_URL=https://openrouter.ai/api/v1` and `OPENROUTER_API_KEY`.
  - The bridge prefers `OPENROUTER_API_KEY` when targeting OpenRouter.
- Streaming / UX — `PROMPTOPT_STREAM=1` for live output streaming (recommended).
- Mode/Model — `PROMPTOPT_MODE=meta|edit` (default `meta`), `OPENAI_MODEL` to hint a preferred model.
- Offline / Demo — `PROMPTOPT_DRYRUN=1` (no network/keys) and `PROMPTOPT_DRYRUN_STREAM=1` (simulate streaming).

### Running Locally
- Normal (user): Launch `Template.ahk`, select text, press `Ctrl+Alt+P`.
- Direct bridge (PowerShell):
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\promptopt.ps1 -SelectionFile "$env:TEMP\sel.txt" -OutputFile "$env:TEMP\out.txt" -MetaPromptDir . -LogFile "$env:TEMP\promptopt_test.log" -Model "gpt-4o-mini" -Mode meta -CopyToClipboard`
- Logs: `Get-Content -Tail 80 "$env:TEMP\promptopt_*.log"`

### Meta‑Prompt Tuning
- Output must contain only the final prompt (no preamble/postscript). Begin with a single‑line Prompt Title, then the optimized body. No labels like "Title:" or "Final Prompt:".
- JSON‑only tasks: specify exact schema and forbid code fences or extra prose.
- Cookbook‑aligned guidance (already in Meta_Prompt*.md):
  - Resolve contradictions (MUST/SHOULD priorities); define constraints and deterministic tie‑breaks for coding tasks.
  - Tune agentic eagerness only when appropriate; define stop conditions and escalation.
  - Hidden reasoning only; never reveal chain‑of‑thought.
- Edit mode: start with `<reasoning>…</reasoning>`, then immediately the title line and optimized body.

### PR Checklist
- [ ] Do not touch `Template.ahk` unless explicitly approved.
- [ ] Prefer meta‑prompt edits or env flags over code changes.
- [ ] Offline check: `PROMPTOPT_DRYRUN=1` (and `_STREAM=1`) → run bridge → output streams; clipboard updates.
-. [ ] Live (OpenAI): set `OPENAI_API_KEY`, run with `PROMPTOPT_STREAM=1` and `-Model gpt-4o-mini`; exit code 0; output respects “no pre/post commentary”, JSON‑only prompts have no code fences.
- [ ] Inspect `%TEMP%\promptopt_*.log` for warnings/errors.
- [ ] No secrets in logs or code; no keys in CLI args.

### Coding Guidelines
- PowerShell: concise logs, never log secrets, honor env overrides (`PROMPTOPT_MODE`, `OPENAI_MODEL`, `OPENAI_BASE_URL`, `PROMPTOPT_STREAM`, etc.).
- Python: support streaming and non‑stream; flush incremental writes; detect OpenRouter vs OpenAI by base URL or `sk-or-` prefix; robust output parsing.
- AHK: keep UX responsive (tooltips, clipboard); avoid duplicating Template.ahk logic.

### Security
- Keys only from environment variables or AHK user prompt; never echo or write keys to disk/logs.
- Avoid adding telemetry; any diagnostics must be opt‑in via env flags.

### Questions
- See AGENTS.md for operational flags and architecture notes.
- Open an issue/PR with a minimal repro or log tail if you encounter problems.

