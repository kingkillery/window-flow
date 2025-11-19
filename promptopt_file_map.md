# PromptOpt System Map

## Core Components
- **`core/Template.ahk`**: Main entry point. Defines global hotkeys (like `Ctrl+Alt+P`) and loads environment variables.
- **`promptopt/promptopt.ahk`**: The main orchestrator script. Handles UI (tooltips, result window), clipboard management, and calls PowerShell.
- **`promptopt/promptopt.ps1`**: PowerShell bridge. Receives commands from AHK, manages arguments, and executes the Python script.
- **`promptopt/promptopt.py`**: Python API client. Interacts with OpenAI/OpenRouter APIs, handles streaming, and meta-prompt application.
- **`promptopt/promptopt_context.ahk`**: Context menu handler. Receives arguments from Windows Registry context menu actions and launches `promptopt.ahk`.

## Configuration & Data
- **`.env`**: Stores API keys (`OPENAI_API_KEY`, `OPENROUTER_API_KEY`) and global settings.
- **`meta-prompts/`**: Directory containing the meta-prompt templates (Markdown files).
  - `Meta_Prompt.md`: Base meta-prompt.
  - `Meta_Prompt_*.md`: Profile-specific meta-prompts (browser, coding, etc.).
- **`meta_prompt_selector.py`**: Utility to intelligently select the best meta-prompt based on input.

## Installation & Context Menu
- **`install_promptopt_custom_menu.reg`**: **(NEW)** Adds "Custom Fill" and "Copy All Text Content" options. Removes old "Meta" and "ReAct" options.
- **`install_promptopt_context_menu.reg`**: Original context menu installer.
- **`install_promptopt_context_menu_enhanced.reg`**: Enhanced context menu installer (file-type specific).
- **`uninstall_*.reg`**: Scripts to remove registry keys.

## Data Flow
1. **Trigger**: User Context Menu -> `promptopt_context.ahk` OR Hotkey -> `Template.ahk`.
2. **Orchestration**: `promptopt.ahk` saves selection to temp file.
3. **Bridge**: Calls `promptopt.ps1` with parameters (profile, model, etc.).
4. **Execution**: `promptopt.ps1` calls `promptopt.py`.
5. **API**: `promptopt.py` sends request to LLM.
6. **Output**: Result saved to temp file -> `promptopt.ahk` reads it -> Show Result Window -> Clipboard.

## Recent Changes
- **Directory Support**: `promptopt_context.ahk` now detects if the input is a directory.
  - **Custom Fill**: Concatenates all text-based files in the directory and opens the custom prompt dialog.
  - **Copy All Text**: Concatenates all text-based files and copies directly to clipboard.
