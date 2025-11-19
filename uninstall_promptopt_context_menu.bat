@echo off
setlocal

echo PromptOpt Context Menu Uninstallation
echo ======================================
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

echo Removing PromptOpt context menu...

:: Create a temporary registry file for removal
set "TEMP_REG=%TEMP%\promptopt_context_uninstall.reg"

echo Windows Registry Editor Version 5.00 > "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo ; PromptOpt Context Menu Removal >> "%TEMP_REG%"
echo ; This file removes PromptOpt from the Windows right-click context menu >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [-HKEY_CLASSES_ROOT\^\*\shell\PromptOpt] >> "%TEMP_REG%"
echo. >> "%TEMP_REG%"
echo [-HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOpt] >> "%TEMP_REG%"

:: Import the registry file
echo Removing registry entries...
regedit.exe /s "%TEMP_REG%"

if %errorLevel% == 0 (
    echo.
    echo SUCCESS: PromptOpt context menu removed!
    echo.
    echo The PromptOpt entries have been removed from the Windows context menu.
    echo.
    pause
) else (
    echo.
    echo ERROR: Failed to remove context menu.
    echo Please check if you have administrator privileges.
    echo.
    pause
)

:: Clean up temp file
if exist "%TEMP_REG%" del "%TEMP_REG%"

endlocal