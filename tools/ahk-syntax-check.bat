@echo off
setlocal enabledelayedexpansion

echo AutoHotkey Syntax Validator
echo ============================
echo.

REM Get all AHK files recursively
set count=0
set errors=0

for /r "." %%f in (*.ahk) do (
    set /a count+=1
    echo Checking: %%f

    REM Try to compile the script in debug mode
    "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" /ErrorStdOut /force "%%f" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [OK]
    ) else (
        echo   [ERROR] Syntax issues detected
        set /a errors+=1
        echo.
        echo   Running syntax check...
        "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" /ErrorStdOut "%%f"
        echo.
    )
)

echo ============================
echo Scanned: %count% files
echo Errors: %errors% files
echo.

if %errors% gtr 0 (
    echo Some files have syntax errors. Review the output above.
) else (
    echo All files have valid AHK v2 syntax.
)

pause