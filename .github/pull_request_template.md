## Summary

- What does this change do? Why is it needed now?

## Type of change

- [ ] Bug fix
- [ ] Feature/refactor (prompt pipeline)
- [ ] Meta‑prompt tuning only
- [ ] Docs/infra

## Approvals and constraints

- [ ] I did NOT modify `Template.ahk` (required). 
  - If you intend to change it, stop and request explicit maintainer approval first.
- [ ] Secrets are not printed or written to disk/logs.

## Environment and flags used

- Provider: [ ] OpenAI  [ ] OpenRouter  [ ] Both
- `OPENAI_MODEL` (if set): `__________`
- `PROMPTOPT_MODE`: [ ] meta  [ ] edit
- `PROMPTOPT_STREAM`: [ ] 1 (enabled)  [ ] 0 (disabled)
- `OPENAI_BASE_URL`: `__________` (unset for OpenAI default)

## Test plan

- Offline simulation
  - [ ] `PROMPTOPT_DRYRUN=1` (+ `PROMPTOPT_DRYRUN_STREAM=1` to simulate streaming)
  - [ ] Bridge exits with code 0
  - [ ] Output file is produced; tooltip/result window behavior OK

- Live (OpenAI)
  - [ ] `OPENAI_API_KEY` set; `OPENAI_BASE_URL` unset (defaults to `https://api.openai.com/v1`)
  - [ ] `PROMPTOPT_STREAM=1` (recommended)
  - [ ] Bridge exits with code 0
  - [ ] Output respects “no pre/post commentary”; JSON‑only prompts have no code fences
  - [ ] Log tail free of errors

- Live (OpenRouter) — if applicable
  - [ ] `OPENAI_BASE_URL=https://openrouter.ai/api/v1`; `OPENROUTER_API_KEY` set
  - [ ] Bridge exits with code 0; output and logs OK

Paste log tail(s) proving success (sanitized):

```
(e.g., %TEMP%\promptopt_*.log tail with exit=0 and output length)
```

## Meta‑prompt changes (if any)

- Files touched: [ ] Meta_Prompt.md  [ ] Meta_Prompt_Edits.md
- Confirm:
  - [ ] No preamble/postscript; Title → optimized prompt body only (no labels like “Title:”)
  - [ ] JSON‑only tasks specify exact schema and forbid code fences and extra prose
  - [ ] Cookbook‑aligned rules applied: resolve contradictions, define constraints/priorities, tune agentic eagerness only when appropriate, never reveal chain‑of‑thought
  - [ ] Edit mode outputs `<reasoning>…</reasoning>` first, then immediately the title line and optimized body

## Docs

- [ ] AGENTS.md/CONTRIBUTING.md updated if behavior or flags changed

## Risk & rollback

- Potential impacts and how to revert quickly if needed:

