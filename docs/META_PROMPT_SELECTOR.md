# Meta-Prompt Selector Documentation

## Overview

The Meta-Prompt Selector is an intelligent feature that automatically detects the best meta-prompt template based on the content of your input text. It uses Python-based analysis to score different meta-prompt combinations and select the most appropriate one.

## Default Behavior

**The meta-prompt selector is DISABLED by default** for safety and reliability. This ensures that PromptOpt works even if:
- Python is not installed
- The selector script is missing
- The meta-prompt directory is not found

## Enabling the Meta-Prompt Selector

To enable the intelligent meta-prompt selector:

1. **Via Menu (Recommended)**:
   - Press `Ctrl+Alt+P` to launch PromptOpt
   - When the meta-prompt selection menu appears (or press `Alt` to force it)
   - Check the "Auto-detect in future (analyze text content)" checkbox
   - Click OK

2. **Via Configuration File**:
   - Edit `%APPDATA%\PromptOpt\config.ini`
   - Add or modify the `[metaprompt]` section:
     ```ini
     [metaprompt]
     autodetect=1
     ```

## Prerequisites

The meta-prompt selector requires:

1. **Python 3.x** installed and accessible:
   - **Windows**: Python launcher (`py.exe`) or `python3`/`python` in PATH
   - **macOS/Linux**: `python3` or `python` in PATH
   - The script will automatically detect Python in common installation locations

2. **Selector Script**: `promptopt/meta_prompt_selector.py` must exist

3. **Meta-Prompt Directory**: `meta-prompts/` directory must exist in the parent directory

## How It Works

1. **Text Analysis**: The selector analyzes your input text using:
   - Keyword matching (50% weight)
   - Pattern detection (30% weight)
   - Structural analysis (20% weight)

2. **Scoring**: Each meta-prompt template is scored based on relevance

3. **Auto-Selection**: If confidence ≥ 0.65 and the top choice is at least 15% better than the second, it auto-selects

4. **Menu Display**: If confidence is low or scores are close, a menu is shown with the top choice pre-selected

## Fallback Behavior

If the meta-prompt selector is unavailable (Python missing, script not found, etc.), PromptOpt will:
- Log a WARNING message (not an ERROR)
- Continue operating normally
- Use the traditional profile selection method (last used profile or profile picker)

## Logging

All selector operations are logged with appropriate levels:

- **INFO**: Normal operations (Python detected, script validated, successful selection)
- **WARNING**: Recoverable issues (Python not found, script missing, prerequisites not met)
- **ERROR**: Critical failures (script execution failed, parsing errors)

Logs are written to: `%TEMP%\promptopt_error_YYYYMMDD.log`

## Troubleshooting

### Python Not Found

**Symptom**: Selector unavailable, WARNING logged

**Solutions**:
1. Install Python 3.x from [python.org](https://www.python.org/downloads/)
2. Ensure Python is in your system PATH
3. On Windows, use the Python launcher (`py.exe`) from the Microsoft Store

### Script Not Found

**Symptom**: WARNING: "Meta-prompt selector script not found"

**Solutions**:
1. Verify `promptopt/meta_prompt_selector.py` exists
2. Check file permissions (must be readable)
3. Ensure the script is not empty or corrupted

### Meta-Prompt Directory Missing

**Symptom**: WARNING: "Meta-prompt directory not found"

**Solutions**:
1. Verify `meta-prompts/` directory exists in the parent directory
2. Check directory permissions
3. Ensure the directory contains meta-prompt template files

### Selector Fails at Runtime

**Symptom**: ERROR logged, fallback to traditional selection

**Solutions**:
1. Check the log file for detailed error messages
2. Verify Python can execute the selector script: `python promptopt/meta_prompt_selector.py --help`
3. Ensure all Python dependencies are installed (the script uses only standard library)

## Manual Override

You can always manually select a meta-prompt:

- **Force Menu**: Hold `Alt` key when pressing `Ctrl+Alt+P` to always show the selection menu
- **Menu Selection**: Choose from 11 available meta-prompt combinations:
  - General, Coding, Writing, Browser, RAG, ReAct (Meta mode)
  - General, Coding, Writing, Browser, RAG (Edit mode)

## Configuration

### Environment Variables

None required. The selector uses the same configuration as the main PromptOpt system.

### Configuration File

Location: `%APPDATA%\PromptOpt\config.ini`

```ini
[metaprompt]
autodetect=0          ; 0 = disabled (default), 1 = enabled
last_mode=meta        ; Last selected mode (meta or edit)
```

## Platform Support

The selector is designed to work on:
- **Windows**: Full support (checks Windows Store Python launcher and common installation paths)
- **macOS**: Full support (checks `python3` and `python` in PATH)
- **Linux**: Full support (checks `python3` and `python` in PATH)

## Performance

- **Detection Time**: < 100ms (Python detection and validation)
- **Analysis Time**: < 500ms (text analysis and scoring)
- **Total Overhead**: < 1 second (when prerequisites are met)

If prerequisites are not met, the check fails fast (< 50ms) and falls back immediately.

## Security

- The selector only reads your input text (never sends it externally)
- All processing is local (Python script runs on your machine)
- No network calls are made by the selector
- Temporary files are automatically cleaned up

## Examples

### Example 1: Coding Task
**Input**: "Write a Python function to calculate fibonacci numbers"
**Detected**: `coding-meta` (score: 0.66, auto-selected)

### Example 2: Writing Task
**Input**: "Write a blog post about AI trends"
**Detected**: `writing-meta` (score: 0.61, menu shown)

### Example 3: Edit Task
**Input**: "Rewrite this email to be more professional"
**Detected**: `general-edit` (score: 0.69, auto-selected)

### Example 4: Browser Task
**Input**: "Extract the main points from https://example.com/article"
**Detected**: `browser-meta` (score: 0.81, auto-selected)

## See Also

- [Main README](../README.md) - General PromptOpt documentation
- [AGENTS.md](../AGENTS.md) - System architecture and development guidelines
- [Meta-Prompt Templates](../meta-prompts/) - Available meta-prompt templates

