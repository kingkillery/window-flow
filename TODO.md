# Current Cycle: Next 5-20 Tasks (in order)

This file contains the active, short-horizon tasks for the current development cycle. Tasks are listed in execution order.

## Current Focus: Template.ahk Modularization

1. **Verify hotstring extraction completeness** - Review Template.ahk to ensure all hotstrings are properly extracted to `hotstrings/` modules
2. **Extract media hotkeys** - Create `hotkeys/media.ahk` with all media control hotkeys (`^!MButton`, `^!RButton`, etc.)
3. **Extract window management hotkeys** - Create `hotkeys/windows.ahk` with window management (`^WheelUp`, `^WheelDown`, etc.)
4. **Extract mouse button remapping** - Create `hotkeys/mouse.ahk` with mouse button remapping (`XButton1::`, `XButton2::`, etc.)
5. **Extract environment helpers** - Create `core/environment.ahk` with `LoadDotEnv()` and related environment loading functions
6. **Extract GUI helpers** - Create helper module for GUI utility functions (`SendHotstringText`, etc.) - determine if separate file or part of environment.ahk
7. **Update promptopt.ps1 paths** - Verify and update meta-prompt directory paths in `promptopt/promptopt.ps1`
8. **Update Template.ahk includes** - Modify Template.ahk to include all extracted modules instead of inline code
9. **Test hotstrings** - Verify all hotstrings (api-keys, general, templates) expand correctly
10. **Test hotkeys** - Verify all hotkeys (media, windows, mouse) work correctly
11. **Test promptopt system** - Verify PromptOpt workflow (Ctrl+Alt+P) functions end-to-end
12. **Test standalone tools** - Verify directorymapper, prompter, tabfiller, xml_tag_autoclose still work
13. **Move README.md** - Move `README.md` to `docs/README.md` and update references
14. **Move CONTRIBUTING.md** - Move `CONTRIBUTING.md` to `docs/CONTRIBUTING.md` and update references
15. **Create docs/INDEX.md** - Create documentation index for discoverability
16. **Update documentation links** - Fix all internal links in AGENTS.md, CLAUDE.md, README.md after moves
17. **Create archive directory** - Create `archive/` directory for deprecated files
18. **Archive old backups** - Move Template.ahk.backup, Template.ahk.old to archive/ if they exist
19. **Create archive/INDEX.md** - Document what was archived and why
20. **Final validation** - Run link check, verify all functionality, create summary report

## Notes

- Tasks should be completed in order to maintain dependencies
- After each task, test affected functionality
- Keep backups of Template.ahk at each major step
- Update this file as tasks are completed or priorities change

