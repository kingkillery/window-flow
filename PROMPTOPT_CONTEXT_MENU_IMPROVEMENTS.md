# PromptOpt Context Menu Pipeline Improvements

## Current Issues Identified

Based on analysis of `CODE_MAP_VISUAL.md` and the codebase, the context menu path has several limitations compared to the main hotkey path:

### 1. **No Streaming Support**
- Context menu uses static `ShowProgress()` tooltip
- Main path uses `StartStreamTip()` with live preview via `UpdateStreamTip()`
- Users miss real-time feedback during API calls

### 2. **No Model Selection**
- Context menu always uses default model from profile
- Main path has `PickModel()` GUI with model picker
- No way to override model choice from context menu

### 3. **Code Duplication**
- `ShowResultWindow()` duplicated in both files
- Error handling code duplicated
- Profile/model helpers duplicated

### 4. **Bypasses Main Script Logic**
- Context menu calls PowerShell directly
- Missing all UI features from `promptopt.ahk`:
  - Streaming tooltip updates
  - Error logging system
  - Robust error handling with log file opening
  - Profile/model picker integration

### 5. **Limited Error Handling**
- Less robust error messages
- No automatic log file opening on errors
- Missing error logging infrastructure

## Proposed Improvements

### Improvement 1: Refactor promptopt.ahk to Accept Command-Line Arguments

**Goal**: Make `promptopt.ahk` reusable from context menu while preserving all features.

**Changes**:
- Add command-line argument parsing:
  - `--file <path>`: Process file content instead of clipboard
  - `--profile <name>`: Pre-select profile (still allow override)
  - `--model <name>`: Pre-select model (still allow override)
  - `--skip-pickers`: Use provided profile/model without GUI (for context menu)
- When `--skip-pickers` is set, use provided values without showing pickers
- When profile/model provided but `--skip-pickers` not set, show pickers with defaults pre-selected

### Improvement 2: Update promptopt_context.ahk to Use Main Script

**Goal**: Reuse all features from main script instead of duplicating logic.

**Changes**:
- Replace direct PowerShell call with call to `promptopt.ahk`
- Pass file path, profile, and `--skip-pickers` flag
- Remove duplicate code (ShowResultWindow, error handling, etc.)
- Keep only context-menu-specific logic (file reading, clipboard handling)

### Improvement 3: Add Streaming Support to Context Menu Path

**Goal**: Provide live preview during processing.

**Changes**:
- Streaming automatically works when using main script
- No additional changes needed once Improvement 1 & 2 are done

### Improvement 4: Optional Model Selection from Context Menu

**Goal**: Allow users to pick model even when using context menu.

**Changes**:
- Add "Optimize with Model Selection" option to context menu
- This option calls main script WITHOUT `--skip-pickers`
- Regular profile options use `--skip-pickers` for faster workflow

### Improvement 5: Unify Result Window Code

**Goal**: Single source of truth for result display.

**Changes**:
- Extract `ShowResultWindow()` to shared location or keep in main script
- Context menu script calls main script which handles result display

## Implementation Plan

### Phase 1: Refactor promptopt.ahk (High Priority)
1. Add command-line argument parsing
2. Support `--file` mode (read from file instead of clipboard)
3. Support `--profile` and `--model` pre-selection
4. Support `--skip-pickers` flag
5. Test with command-line arguments

### Phase 2: Update promptopt_context.ahk (High Priority)
1. Replace PowerShell call with `promptopt.ahk` call
2. Pass appropriate command-line arguments
3. Remove duplicate code
4. Test context menu flow

### Phase 3: Enhance Context Menu Options (Medium Priority)
1. Add "Optimize with Model Selection" option
2. Update registry installation scripts
3. Test new menu options

### Phase 4: Code Cleanup (Low Priority)
1. Remove unused duplicate functions
2. Consolidate shared utilities
3. Update documentation

## Benefits

1. **Consistent UX**: Context menu users get same experience as hotkey users
2. **Live Preview**: Real-time streaming feedback during processing
3. **Model Selection**: Option to choose model even from context menu
4. **Better Errors**: Robust error handling and logging
5. **Less Code**: Single source of truth, easier maintenance
6. **Feature Parity**: New features automatically work for both paths

## Backward Compatibility

- Existing context menu entries continue to work
- Default behavior unchanged (uses profile default model)
- New optional menu items added for enhanced features
- No breaking changes to existing workflows

