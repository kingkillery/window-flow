# Context Scout (DESIGN)

## Purpose
Context Scout is an optional PromptOpt feature that gathers relevant code context from a folder (typically a repo) and injects it into the PromptOpt request so the LLM can produce grounded, accurate edits.

## Goals
- Provide high-signal code context automatically.
- Respect ignore rules (do not pull in `node_modules`, `.git`, binaries, etc.).
- Keep the system **read-only** (no writes, no edits).
- Avoid secrets leakage (never include `.env` or API keys in output).

## Architecture
- **AHK UI** (`promptopt/promptopt.ahk`)
  - Adds an "Add Context" action.
  - Captures:
    - `ContextDir`: folder to scan
    - `ContextQuery`: natural language query (what to retrieve)
  - Passes these to PowerShell.

- **PowerShell bridge** (`promptopt/promptopt.ps1`)
  - Runs Context Scout tool prior to invoking `promptopt.py`.
  - Produces a `ContextBundleFile` containing `<file path="..."> ... </file>` blocks.
  - Appends the context bundle to the selection input sent to the LLM.

- **Context Scout engine** (`tools/context_grepper.py`)
  - Primary: Morph WarpGrep direct API (`model=morph-warp-grep`) using `MORPH_API_KEY`.
  - Executes the tool calls locally (`rg`, file reads, directory listing).
  - Fallback: local heuristic scan if WarpGrep isn’t available.

## Inputs
- `repo_root` (folder): directory to scan.
- `query` (string): what the user wants to find.

## Output
A UTF-8 text bundle of one or more blocks:

```
<file path="relative/path/to/file">
1|...
2|...
</file>
```

## Configuration
- `MORPH_API_KEY` (required for WarpGrep mode)
- `MORPH_API_URL` (optional override; default `https://api.morphllm.com/v1/chat/completions`)

## Safety
- Never include `.env` contents in context.
- Skip binary files.
- Enforce size/line limits to prevent runaway context.

## Notes
This is designed to be backwards compatible: if no context is requested, PromptOpt behavior remains unchanged.
