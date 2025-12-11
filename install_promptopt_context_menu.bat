@echo off
setlocal enabledelayedexpansion

echo PromptOpt Context Menu Installation
echo ====================================
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

echo Installing PromptOpt context menu...
echo Script directory: %SCRIPT_DIR%

:: Create a temporary registry file with the correct paths
set "TEMP_REG=%TEMP%\promptopt_context_install.reg"

echo Windows Registry Editor Version 5.00 > "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo ; PromptOpt Context Menu Integration - Auto-generated >> "%TEMP_REG%"
echo ; This file adds PromptOpt to the Windows right-click context menu >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"

:: Add for all files
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

:: Add for directory background
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
echo Importing registry settings...
regedit.exe /s "%TEMP_REG%"

if %errorLevel% == 0 (
    echo.
    echo SUCCESS: PromptOpt context menu installed!
    echo.
    echo You can now right-click on files or in empty space to access PromptOpt.
    echo.
    echo Usage:
    echo - Right-click a text file and choose "Optimize with [Profile] Profile"
    echo - Copy text to clipboard, right-click empty space, and choose profile
    echo - Use "Configure PromptOpt..." to set up API keys and defaults
    echo.
    pause
) else (
    echo.
    echo ERROR: Failed to install context menu.
    echo Please check if you have administrator privileges.
    echo.
    pause
)

:: Clean up temp file
if exist "%TEMP_REG%" del "%TEMP_REG%"

endlocal