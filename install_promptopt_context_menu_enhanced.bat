@echo off
setlocal enabledelayedexpansion

echo Enhanced PromptOpt Context Menu Installation
echo ==========================================
echo This installs support for:
echo - General files (all types)
echo - Markdown files (.md)
echo - Python files (.py)
echo - JavaScript files (.js)
echo - TypeScript files (.ts)
echo - CSS files (.css)
echo - HTML files (.html, .htm)
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo ERROR: This script must be run as Administrator.
    echo Right-click the script and select "Run as administrator".
    pause
    exit /b 1
)

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo Installing Enhanced PromptOpt context menu...
echo Script directory: %SCRIPT_DIR%

:: Create a temporary registry file with the correct paths
set "TEMP_REG=%TEMP%\promptopt_context_enhanced_install.reg"

echo Windows Registry Editor Version 5.00 > "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo ; Enhanced PromptOpt Context Menu Integration - Auto-generated >> "%TEMP_REG%"
echo ; Includes support for Markdown and code files with Copy Raw Text options >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add for all files (general)
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt] >> "%TEMP_REG%"
echo @="PromptOpt" >> "%TEMP_REG%"
echo "Position"="Top" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\browser] >> "%TEMP_REG%"
echo @="Optimize with Browser Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\browser\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"browser\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\coding] >> "%TEMP_REG%"
echo @="Optimize with Coding Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\coding\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"coding\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\writing] >> "%TEMP_REG%"
echo @="Optimize with Writing Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\writing\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"writing\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\rag] >> "%TEMP_REG%"
echo @="Optimize with RAG Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\rag\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"rag\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\general] >> "%TEMP_REG%"
echo @="Optimize with General Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\general\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"general\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\sep1] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\copyraw] >> "%TEMP_REG%"
echo @="Copy Raw Text" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\copyraw\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"copyraw\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\sep2] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\settings] >> "%TEMP_REG%"
echo @="Configure PromptOpt..." >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\settings\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"settings\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\about] >> "%TEMP_REG%"
echo @="About PromptOpt" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^\*\shell\PromptOpt\shell\about\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"about\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add Markdown files support
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^.md] >> "%TEMP_REG%"
echo @="markdownfile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt] >> "%TEMP_REG%"
echo @="PromptOpt" >> "%TEMP_REG%"
echo "Position"="Top" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\copyraw] >> "%TEMP_REG%"
echo @="Copy Raw Markdown" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\copyraw\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"copyraw\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\writing] >> "%TEMP_REG%"
echo @="Optimize for Writing" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\writing\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"writing\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\general] >> "%TEMP_REG%"
echo @="Optimize for General" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\markdownfile\shell\general\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"general\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\sep1] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\settings] >> "%TEMP_REG%"
echo @="Configure..." >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\markdownfile\shell\PromptOpt\shell\settings\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"settings\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add Python files support
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^.py] >> "%TEMP_REG%"
echo @="pythonfile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt] >> "%TEMP_REG%"
echo @="PromptOpt" >> "%TEMP_REG%"
echo "Position"="Top" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\copyraw] >> "%TEMP_REG%"
echo @="Copy Raw Python Code" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\copyraw\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"copyraw\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\coding] >> "%TEMP_REG%"
echo @="Optimize for Coding" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\coding\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"coding\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\general] >> "%TEMP_REG%"
echo @="Optimize for General" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\pythonfile\shell\general\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"general\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\sep1] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\settings] >> "%TEMP_REG%"
echo @="Configure..." >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\pythonfile\shell\PromptOpt\shell\settings\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"settings\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add JavaScript files support
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\^.js] >> "%TEMP_REG%"
echo @="javascriptfile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt] >> "%TEMP_REG%"
echo @="PromptOpt" >> "%TEMP_REG%"
echo "Position"="Top" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\copyraw] >> "%TEMP_REG%"
echo @="Copy Raw JavaScript" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\copyraw\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"copyraw\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\coding] >> "%TEMP_REG%"
echo @="Optimize for Coding" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\coding\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"coding\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\general] >> "%TEMP_REG%"
echo @="Optimize for General" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\javascriptfile\shell\general\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"%%1\" \"general\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\sep1] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\settings] >> "%TEMP_REG%"
echo @="Configure..." >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\javascriptfile\shell\PromptOpt\shell\settings\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"settings\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add Directory background support
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt] >> "%TEMP_REG%"
echo @="PromptOpt" >> "%TEMP_REG%"
echo "Position"="Top" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\browser] >> "%TEMP_REG%"
echo @="Optimize with Browser Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\browser\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"clipboard\" \"browser\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\coding] >> "%TEMP_REG%"
echo @="Optimize with Coding Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\coding\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"clipboard\" \"coding\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\writing] >> "%TEMP_REG%"
echo @="Optimize with Writing Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\writing\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"clipboard\" \"writing\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\rag] >> "%TEMP_REG%"
echo @="Optimize with RAG Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\rag\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"clipboard\" \"rag\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\general] >> "%TEMP_REG%"
echo @="Optimize with General Profile" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\general\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"clipboard\" \"general\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\sep1] >> "%TEMP_REG%"
echo @="-" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\settings] >> "%TEMP_REG%"
echo @="Configure PromptOpt..." >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\settings\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"settings\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\about] >> "%TEMP_REG%"
echo @="About PromptOpt" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt\shell\about\command] >> "%TEMP_REG%"
echo @="\"%SCRIPT_DIR%\\promptopt\\promptopt_context.ahk\" \"about\"" >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Import the registry file
echo Importing enhanced registry settings...
regedit.exe /s "%TEMP_REG%"

if %errorLevel% == 0 (
    echo.
    echo SUCCESS: Enhanced PromptOpt context menu installed!
    echo.
    echo Features installed:
    echo - General files: All optimization profiles + Copy Raw Text
    echo - Markdown files (.md): Writing/General optimization + Copy Raw Markdown
    echo - Python files (.py): Coding/General optimization + Copy Raw Python Code
    echo - JavaScript files (.js): Coding/General optimization + Copy Raw JavaScript
    echo - TypeScript files (.ts): Coding/General optimization + Copy Raw TypeScript
    echo - CSS files (.css): Coding/General optimization + Copy Raw CSS
    echo - HTML files (.html/.htm): Coding/General optimization + Copy Raw HTML
    echo - Directory background: All profiles for clipboard content
    echo.
    echo Usage Examples:
    echo - Right-click a .py file and choose "Copy Raw Python Code" to copy it to clipboard
    echo - Right-click a .md file and choose "Optimize for Writing" to improve documentation
    echo - Right-click a .js file and choose "Optimize for Coding" to improve code quality
    echo - Use "Configure..." to set up API keys and defaults
    echo.
    pause
) else (
    echo.
    echo ERROR: Failed to install enhanced context menu.
    echo Please check if you have administrator privileges.
    echo.
    pause
)

:: Clean up temp file
if exist "%TEMP_REG%" del "%TEMP_REG%"

endlocal