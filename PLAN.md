# Scripts Folder Reorganization Plan

## Status: IN PROGRESS (Phase 4 Complete ✅)

### Completed
- ✅ **Phase 4: Moved standalone scripts** (Oct 30, 2025 - 19:24)
  - `directorymapper.ahk`, `prompter.ahk`, `tabfiller.ahk`, `xml_tag_autoclose.ahk` → `tools/`
  - `promptopt.ahk`, `promptopt.ps1`, `promptopt.py` → `promptopt/`
  - All `Meta_Prompt*.md` and `Meta_Prompt_Edits*.md` files → `meta-prompts/`

## Current State Analysis

The `Scripts` folder is **partially reorganized**:
1. **Template.ahk is still 57KB** - Still contains hotkeys, hotstrings, helper functions, GUI code, and configuration
2. **Modular directories created** - core/, promptopt/, hotstrings/, tools/, hotkeys/, meta-prompts/, docs/
3. **Path references need updates** - Template.ahk and promptopt.ps1 must reference new file locations
4. **Hotstring/hotkey extraction pending** - api-keys.ahk, general.ahk created; templates.ahk, solar.ahk, media.ahk, windows.ahk, mouse.ahk still needed

## Proposed Modular Structure

```
Scripts/
├── core/                     # Essential system files
│   ├── Template.ahk          # Main hotkey entry point (minimal)
│   └── environment.ahk       # Centralized .env loading and helpers
│
├── promptopt/               # Prompt optimization system
│   ├── promptopt.ahk        # Existing AHK v2 orchestrator
│   ├── promptopt.ps1        # Existing PowerShell bridge
│   ├── promptopt.py         # Existing Python API client
│   ├── gui.ahk              # Extract GUI components from promptopt.ahk
│   └── config.ahk           # Profile/model management
│
├── hotstrings/             # Text expansion hotstrings
│   ├── general.ahk          # General text expansions
│   ├── api-keys.ahk         # API key hotstrings (security-focused)
│   ├── templates.ahk        # Large template hotstrings (sdframework, etc.)
│   └── solar.ahk            # Solar/business specific
│
├── tools/                   # Standalone utility scripts
│   ├── directorymapper.ahk  # Move existing file
│   ├── tabfiller.ahk        # Move existing file
│   ├── xml_tag_autoclose.ahk  # Move existing file
│   └── prompter.ahk         # Move existing file
│
├── hotkeys/                # Hotkey-only scripts  
│   ├── media.ahk           # Media control keys
│   ├── windows.ahk         # Window management
│   └── mouse.ahk           # Mouse button remapping
│
├── meta-prompts/            # Meta prompt files
│   └── *.md                # Move all Meta_Prompt*.md files
│
└── docs/                   # Documentation
    ├── AGENTS.md           # Updated with new structure
    ├── CLAUDE.md           # Existing (move)
    ├── README.md           # Existing (move)
    └── CONTRIBUTING.md     # Existing (move)
```

## Implementation Steps

### Phase 1: Extract Hotstrings from Template.ahk
1. **api-keys.ahk** - All `:*:key::` hotstrings that use `SendSecretFromEnv()`
2. **general.ahk** - Simple text expansions like `p1approval`, `textnote`
3. **templates.ahk** - Large multiline templates like `sdframework`, `task-triage`
4. **solar.ahk** - Solar/business specific hotstrings

### Phase 2: Extract Hotkeys from Template.ahk
1. **media.ahk** - Media control hotkeys (`^!MButton`, `^!RButton`, etc.)
2. **windows.ahk** - Window management (`^WheelUp`, `^WheelDown`)
3. **mouse.ahk** - Mouse button remapping (`XButton1::`, `XButton2::`)

### Phase 3: Extract Helper Functions
1. **environment.ahk** - Environment loading functions (`LoadDotEnv()`, etc.)
2. **gui_helpers.ahk** - GUI utility functions (`SendHotstringText`, etc.)

### Phase 4: Move Standalone Scripts
- Move existing `.ahk` files from root to appropriate categories
- Update any internal path references

### Phase 5: Create New Template.ahk
- Minimal entry point that includes other modules
- Preserve all existing hotkeys and hotstrings
- Maintain backwards compatibility

### Phase 6: Documentation Updates
- Update AGENTS.md with new structure
- Update CLAUDE.md with new file organization
- Update README.md if needed

## Key Constraints

1. **DO NOT break existing functionality** - All hotkeys/hotstrings must work exactly as before
2. **Template.ahk must remain the entry point** but can be simplified
3. **Security improvements** - Isolate API key handling in dedicated module
4. **Path independence** - Use relative paths or configure paths properly

## Testing Strategy

After each phase:
1. Test all hotkeys work (Ctrl+Alt+P, media controls, etc.)
2. Test hotstrings expand correctly
3. Test promptopt system still functions
4. Test standalone tools still work

## Benefits

1. **Maintainability** - Related functions grouped together
2. **Security** - API keys isolated in dedicated module  
3. **Readability** - Template.ahk becomes manageable size
4. **Extensibility** - Easy to add new hotstrings or tools
5. **Debugging** - Easier to isolate issues in specific modules

## Risk Mitigation

1. **Backwards compatibility** - All existing hotkeys preserved
2. **Incremental rollout** - Can test after each phase
3. **Rollback plan** - Keep original Template.ahk as backup
4. **Documentation** - Clear mapping of old vs new structure
