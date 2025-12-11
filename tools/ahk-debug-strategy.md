# AHK Debugging Strategy for PromptOpt Codebase

## Overview
This strategy provides a systematic approach to debugging AHK syntax errors in the PromptOpt codebase.

## Key Principles
1. **Understand AHK v2 String Escaping**: Use grave accent (```) to escape quotes in strings
2. **Context-Aware Validation**: Different rules apply to different contexts (code vs strings vs hotstrings)
3. **Incremental Testing**: Test syntax changes incrementally

## Common AHK v2 Syntax Issues

### 1. String Escaping
```ahk
; WRONG - causes syntax errors
text .= "sections[""IMPLEMENT v1""]"  ; Nested quotes

; CORRECT
text .= "sections[`"IMPLEMENT v1`"]"  ; Use escaped single quotes
text .= "sections[``"IMPLEMENT v1``"]" ; Or escaped double quotes
```

### 2. JavaScript/Code in Strings
When embedding code in AHK strings:
```ahk
; WRONG
text .= "let sec="""";"  ; Triple quotes break AHK parsing

; CORRECT
text .= "let sec=`"`";"  ; Use escaped quotes
```

### 3. Hotstring Syntax
```ahk
; Correct format
:*:trigger::replacement
:R:trigger::replacement

; Wrong format
:*R:trigger::replacement  ; Mixes options incorrectly
```

## Debugging Tools

### 1. Quick Syntax Test
```bash
# Test single file
autohotkey.exe /ErrorStdOut "path\to\file.ahk"

# Test and show errors
autohotkey.exe /force /ErrorStdOut "path\to\file.ahk"
```

### 2. Batch Validation Script
Use the provided `ahk-syntax-check.bat` to validate all AHK files:
```bash
.\tools\ahk-syntax-check.bat
```

### 3. Manual Checklist
- [ ] All nested quotes properly escaped
- [ ] JavaScript code in strings uses escaped quotes
- [ ] Hotstrings follow correct syntax
- [ ] No missing operators or spaces
- [ ] All braces properly matched

## Current Known Issues & Solutions

### Issue: Quote Nesting in Templates
**Location**: `hotstrings/templates.ahk` line 266
**Problem**: JavaScript code with triple quotes `""""`
**Solution**: Replace with escaped quotes ``"`"

### Issue: String Concatenation
**Location**: Multiple files
**Problem**: Missing space operator in string building
**Solution**: Use `text .= "more" . "concatenated"` instead of missing operators

## Step-by-Step Debugging Process

1. **Identify Error Location**
   - Note the file and line number from AHK error
   - Look at the context (string building vs actual code)

2. **Check Quote Escaping**
   - Count opening and closing quotes
   - Ensure nested quotes are escaped with ` or different quote types

3. **Test Incrementally**
   - Fix one issue at a time
   - Test syntax after each fix
   - Use `/ErrorStdOut` flag for detailed error messages

4. **Validate Entire Codebase**
   - Run the batch validation script
   - Focus on files with actual errors, not false positives

## Prevention Strategies

1. **Use Single Quotes in JavaScript When Possible**
   ```ahk
   text .= "sections['IMPLEMENT v1']"  ; Safer than double quotes
   ```

2. **Avoid Complex String Building**
   - Break complex strings into multiple lines
   - Use variables for problematic content

3. **Regular Testing**
   - Test syntax after major changes
   - Use the validation script before commits

## Emergency Fixes

If AHK won't load and you need a quick fix:
1. Comment out the problematic line with `;`
2. Reload AHK to confirm it works
3. Fix the line incrementally
4. Test again before uncommenting

## File-Specific Notes

### `hotstrings/templates.ahk`
- Contains embedded JavaScript code
- Requires careful quote escaping
- Line 266: JavaScript strings need `"` instead of `""`

### `promptopt/promptopt.ahk`
- Core orchestration logic
- Uses complex string operations
- Pay attention to clipboard operations

### `core/Template.ahk`
- Entry point (modify with caution)
- Contains hotkey definitions
- Test hotkey functionality after changes