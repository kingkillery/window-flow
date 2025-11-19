# PromptOpt Context Menu Integration

This adds PromptOpt directly to your Windows right-click context menu for easy access to AI-powered prompt optimization.

## Installation

### Standard Installation
1. **Run as Administrator:**
   - Right-click `install_promptopt_context_menu.bat`
   - Select "Run as administrator"
   - Follow the prompts

2. **Alternative (Manual Registry Import):**
   - Double-click `install_promptopt_context_menu.reg`
   - Accept the registry modification warnings

### Enhanced Installation (Recommended)
For full support of Markdown and code files with specialized menus:

1. **Run Enhanced Installer as Administrator:**
   - Right-click `install_promptopt_context_menu_enhanced.bat`
   - Select "Run as administrator"
   - Follow the prompts

2. **Alternative (Manual Registry Import):**
   - Double-click `install_promptopt_context_menu_enhanced.reg`
   - Accept the registry modification warnings

### Enhanced vs Standard Installation

| Feature | Standard | Enhanced |
|---------|----------|----------|
| General files support | ✅ | ✅ |
| "Copy Raw Text" option | ✅ | ✅ |
| Markdown files (.md) | ❌ | ✅ |
| Python files (.py) | ❌ | ✅ |
| JavaScript files (.js) | ❌ | ✅ |
| TypeScript files (.ts) | ❌ | ✅ |
| CSS files (.css) | ❌ | ✅ |
| HTML files (.html/.htm) | ❌ | ✅ |
| File-specific copy options | ❌ | ✅ |
| Specialized optimization options | ❌ | ✅ |

## Usage

### Right-Click on General Files
- Right-click any file
- Select "PromptOpt" → Choose option:
  - **Copy Raw Text**: Copy entire file content to clipboard
  - **Optimize with [Profile]**: Optimize file content with chosen profile
  - **Configure PromptOpt...**: Open settings
  - **About PromptOpt**: Show information

### Right-Click on Specialized Files

#### Markdown Files (.md)
- **Copy Raw Markdown**: Copy entire markdown content to clipboard
- **Optimize for Writing**: Improve documentation, structure, clarity
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

#### Python Files (.py)
- **Copy Raw Python Code**: Copy entire Python code to clipboard
- **Optimize for Coding**: Improve code quality, add comments, optimize structure
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

#### JavaScript Files (.js)
- **Copy Raw JavaScript**: Copy entire JavaScript code to clipboard
- **Optimize for Coding**: Improve code quality, structure, performance
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

#### TypeScript Files (.ts)
- **Copy Raw TypeScript**: Copy entire TypeScript code to clipboard
- **Optimize for Coding**: Improve code quality, types, structure
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

#### CSS Files (.css)
- **Copy Raw CSS**: Copy entire CSS code to clipboard
- **Optimize for Coding**: Improve styling, organization, best practices
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

#### HTML Files (.html, .htm)
- **Copy Raw HTML**: Copy entire HTML code to clipboard
- **Optimize for Coding**: Improve structure, accessibility, SEO
- **Optimize for General**: General purpose optimization
- **Configure...**: Settings

### Right-Click in Empty Space
- Copy text to clipboard (Ctrl+C)
- Right-click in empty space in any folder
- Select "PromptOpt" → Choose optimization profile:
  - **Browser/Computer**: General web/computer tasks
  - **Coding**: Programming and development
  - **Writing**: Text composition and editing
  - **RAG**: Retrieval-augmented generation tasks
  - **General**: General purpose optimization
- The clipboard text will be optimized and copied back

### Configuration
- Right-click and choose "Configure PromptOpt..."
- Set your API keys (OpenRouter or OpenAI)
- Choose default profile
- Enable auto-selection to skip profile picker

## Files Created

### Standard Installation
- `promptopt/promptopt_context.ahk` - Context menu launcher script
- `install_promptopt_context_menu.reg` - Registry file for manual installation
- `install_promptopt_context_menu.bat` - Automated installer
- `uninstall_promptopt_context_menu.reg` - Registry file for manual removal
- `uninstall_promptopt_context_menu.bat` - Automated uninstaller

### Enhanced Installation
- `install_promptopt_context_menu_enhanced.reg` - Enhanced registry file
- `install_promptopt_context_menu_enhanced.bat` - Enhanced automated installer (recommended)
- `uninstall_promptopt_context_menu_enhanced.reg` - Enhanced registry removal file

### Documentation and Testing
- `README_PROMPTOPT_CONTEXT_MENU.md` - This documentation file
- `test_clipboard.ahk` - Test script for clipboard functionality

## Uninstallation

1. **Run as Administrator:**
   - Right-click `uninstall_promptopt_context_menu.bat`
   - Select "Run as administrator"

2. **Alternative (Manual Registry Import):**
   - Double-click `uninstall_promptopt_context_menu.reg`
   - Accept the registry modification warnings

## Requirements

- Windows 10/11
- AutoHotkey v2.0+ installed
- PromptOpt main system already configured
- API keys configured (OpenRouter or OpenAI)

## Troubleshooting

### Context menu doesn't appear
- Ensure you ran the installer as Administrator
- Restart Windows Explorer after installation
- Check that AutoHotkey v2 is properly installed

### "File not found" errors
- Verify `promptopt_context.ahk` exists in the `promptopt/` directory
- Ensure all PromptOpt files are in their correct locations

### API key errors
- Right-click and choose "Configure PromptOpt..."
- Enter valid OpenRouter or OpenAI API keys
- Save the settings

### Performance issues
- Check your internet connection
- Verify API key has sufficient credits
- Try different models from the model picker

### Copy-paste not working properly
The context menu integration is designed to not interfere with normal clipboard operations. If you experience issues:

1. **Restart Template.ahk**: Close and restart the main Template.ahk script
2. **Check for stuck guards**: The system has safety mechanisms to clear clipboard guards
3. **Test with test_clipboard.ahk**: Run the test script to verify basic clipboard functionality
4. **Avoid multiple rapid operations**: Don't trigger context menu operations while copying/pasting normally

**PK_PROMPT Feature**: The PK_PROMPT feature is available but **disabled by default** to prevent interference with normal copy-paste operations. Use `Ctrl+Alt+Shift+C` to toggle PK_PROMPT monitoring on/off when needed.

### Context menu operations fail
- Check that the context menu script has proper permissions
- Verify your antivirus isn't blocking the AHK script
- Try running the context menu script directly to test

## Enhanced Result Window Features

PromptOpt now displays results in an enhanced window with the following features:

### 📊 **Text Statistics**
- Character count, line count, and word count displayed in title bar
- Info panel showing prompt metrics

### 🎨 **Improved UI**
- Clean, modern interface with better visual styling
- Consolas font for better code readability
- Color-coded buttons with emoji icons
- Always-on-top window for easy access while working

### 📋 **Enhanced Copy Options**
- **Auto-select**: Text is automatically selected for easy copying
- **Copy All Button**: One-click copy with visual feedback
- **Sound Feedback**: Confirmation beeps when copy succeeds
- **Keyboard Shortcuts**: Ctrl+A to select all, Ctrl+C to copy

### 💾 **Additional Features**
- **Save Button**: Save optimized prompt to file
- **Open in Notepad**: View in external editor
- **Helpful Tooltips**: Tips appear for 5 seconds showing keyboard shortcuts
- **Error Handling**: Clear feedback for failed operations

## Integration with Existing PromptOpt

The context menu integration works alongside your existing Ctrl+Alt+P hotkey:
- **Context Menu**: Quick access for specific files/clipboard content with enhanced result window
- **Hotkey (Ctrl+Alt+P)**: Text selection with profile/model picker and enhanced result window
- **PK_REACT**: ReAct mode with enhanced result window
- All methods use the same configuration and meta-prompts
- Enhanced result window is used across all PromptOpt methods

## 🔐 PK_PROMPT Safety Features

The PK_PROMPT feature (automatic optimization when copying text with "PK_PROMPT " prefix) is designed with safety measures to prevent interference with normal copy-paste operations:

### ✅ **Safe by Default**
- **DISABLED BY DEFAULT**: PK_PROMPT monitoring is turned off when Template.ahk starts
- **Normal copy-paste works**: Your Ctrl+C and Ctrl+V operations work perfectly
- **No interference**: Clipboard monitoring only activates when explicitly enabled

### 🔄 **Manual Control**
- **Toggle Hotkey**: `Ctrl+Alt+Shift+C` to enable/disable PK_PROMPT monitoring
- **Visual Feedback**: Tooltip shows current status when toggled
- **Safe switching**: Monitoring can be turned on/off without restarting

### 📋 **How to Use PK_PROMPT**
1. **Enable**: Press `Ctrl+Alt+Shift+C` (tooltip shows "PK_PROMPT monitoring ENABLED")
2. **Copy**: Copy text starting with "PK_PROMPT " to clipboard
3. **Automatic**: Text is automatically optimized and copied back
4. **Disable**: Press `Ctrl+Alt+Shift+C` again (tooltip shows "PK_PROMPT monitoring DISABLED")

### 🧪 **Testing Safety**
Run the clipboard safety test to verify everything works correctly:
```bash
"C:\Program Files\AutoHotkey\AutoHotkey.exe" test_clipboard_safety.ahk
```

## 🧪 Enhanced Window Testing

Run `test_enhanced_result_window.ahk` to preview the enhanced result window features:
```bash
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" test_enhanced_result_window.ahk
```

## Advanced Usage

### Custom Profiles
You can modify the context menu to include custom profiles by editing the registry entries or installation scripts.

### Additional Menu Items
To add more menu options, edit the `.reg` files or `.bat` scripts before installation.

### Multiple API Keys
The settings GUI supports multiple API keys - you can configure both OpenRouter and OpenAI for fallback options.