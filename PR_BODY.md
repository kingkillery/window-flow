# Docs cleanup: consolidate agent notes, normalize AGENTS/PLAN/TODO, and add CLAUDE.md

## Summary

Consolidated agent-facing documentation into AGENTS.md (single source of truth), created synchronized CLAUDE.md provider mirror, normalized PLAN.md with North Star and Immediate Next Steps, created TODO.md with next 5-20 tasks, moved user-facing docs to docs/ directory with INDEX.md, created archive/ directory for deprecated files, and updated all cross-references. Removed Codex-specific content from AGENTS.md that was not relevant to this repository.

## Changes

- **AGENTS.md**: single source of truth; updated system prompt, tools, runbooks, file map; cross-linked to PLAN/TODO. Removed Codex-specific tracing/MCP sections that were not relevant.
- **CLAUDE.md**: provider-ready summary aligned to AGENTS.md; links back to detailed sections.
- **PLAN.md**: FULL plan + immediate next steps (7 items). Added North Star section and Immediate Next Steps section.
- **TODO.md**: created with active WIP; ordered list of next 5-20 tasks.
- **User docs**: moved README.md and CONTRIBUTING.md to docs/ directory; created docs/INDEX.md for discoverability.
- **Archive**: created archive/ directory; moved Template.ahk.backup, Template.ahk.old, and GPT-5-Prompt-Guide.md with reasons documented in archive/INDEX.md.

## Validation

- [x] All links pass
- [x] All agent-facing files referenced in **AGENTS.md** exist and are correct
- [x] **CLAUDE.md** is aligned with **AGENTS.md** (no drift)
- [x] README/docs provide a clear onboarding path (setup → run → test)
- [x] No linting errors in documentation files

## Follow-ups

None - all open questions resolved.

## File Changes Summary

### Created
- `TODO.md` - Next 5-20 tasks in execution order
- `docs/INDEX.md` - Documentation index
- `archive/INDEX.md` - Archive audit trail

### Moved
- `plan.md` → `PLAN.md` (renamed for consistency)
- `README.md` → `docs/README.md`
- `CONTRIBUTING.md` → `docs/CONTRIBUTING.md`
- `Template.ahk.backup` → `archive/`
- `Template.ahk.old` → `archive/`
- `GPT-5-Prompt-Guide.md` → `archive/`

### Updated
- `AGENTS.md` - Complete rewrite as system prompt/brain
- `CLAUDE.md` - Updated to align with AGENTS.md
- `PLAN.md` - Added North Star and Immediate Next Steps sections
- `docs/README.md` - Fixed cross-references to CLAUDE.md

