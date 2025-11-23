# Agent Guidelines & AHK v2 Pitfalls

This document tracks specific syntax patterns and common errors encountered during development. Refer to this when writing AutoHotkey v2 code to avoid regressions.

## Critical AHK v2 Patterns

### 1. GUI Font Styling
**Problem**: Passing font options (size, bold, color) directly to `Gui.Add` throws "Invalid Option".
**Wrong (v1 style)**:
```ahk
MyGui.Add("Text", "s12 cRed", "Hello")
```
**Right (v2 style)**:
```ahk
MyGui.SetFont("s12 cRed")
MyGui.Add("Text", , "Hello")
```
*Rule*: Always use `SetFont` before adding a control if you need to change text appearance.

### 2. MonitorGet Usage
**Problem**: `MonitorGet` does not return an object. Accessing properties like `.Left` fails.
**Wrong**:
```ahk
m := MonitorGet(1)
x := m.Left
```
**Right**:
```ahk
MonitorGet(1, &Left, &Top, &Right, &Bottom)
width := Right - Left
```
*Rule*: Use ByRef (`&Var`) parameters to extract monitor dimensions.

### 3. TrayTip Parameter Order
**Problem**: Notification text appears as title or vice-versa.
**Wrong (v1)**: `TrayTip, Title, Text`
**Right (v2)**: `TrayTip("Text", "Title")`
*Rule*: Text comes FIRST, then Title.

### 4. Global Variable Scope
**Problem**: "Variable not assigned" errors inside functions.
**Rule**: AHK v2 functions assume local scope. You **must** declare `global g_VarName` at the top of any function that reads or writes a global variable, or use the `global` keyword for the specific variable.

### 5. Loop Closures in Events
**Problem**: Buttons in a loop all trigger the action for the last index.
**Right**:
```ahk
Loop 6 {
    index := A_Index
    btn.OnEvent("Click", ((i, *) => MyFunc(i)).Bind(index))
}
```
*Rule*: Always `.Bind(index)` when assigning event handlers inside a loop.

## Git Workflow
- **Clean State**: Keep only `Window-Flow-Dynamic.ahk`, `settings.ini`, and docs in the root.
- **Commits**: Verify AHK syntax before committing.
