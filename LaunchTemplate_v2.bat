@echo off
REM ####################################################################
REM # LAUNCHER FOR TEMPLATE.AHK - Ensures AutoHotkey v2 is used      #
REM ####################################################################

REM Check for AutoHotkey v2 in common locations
SET AHK_V2_PATH=

REM Check Program Files location
IF EXIST "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" (
    SET AHK_V2_PATH=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
    GOTO FOUND
)

REM Check AppData location
IF EXIST "%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" (
    SET AHK_V2_PATH=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe
    GOTO FOUND
)

REM Check for AutoHotkey.exe in v2 folder (32-bit fallback)
IF EXIST "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" (
    SET AHK_V2_PATH=C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
    GOTO FOUND
)

REM Check Program Files (x86) for 32-bit version
IF EXIST "C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe" (
    SET AHK_V2_PATH=C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe
    GOTO FOUND
)

REM If not found, show error
ECHO AutoHotkey v2 not found!
ECHO.
ECHO Please install AutoHotkey v2 from: https://www.autohotkey.com/download/ahk-v2.exe
ECHO.
ECHO Checked locations:
ECHO   - C:\Program Files\AutoHotkey\v2\
ECHO   - %LOCALAPPDATA%\Programs\AutoHotkey\v2\
ECHO   - C:\Program Files (x86)\AutoHotkey\v2\
ECHO.
PAUSE
EXIT /B 1

:FOUND
ECHO Launching Template.ahk with AutoHotkey v2...
ECHO Using: %AHK_V2_PATH%
ECHO.

REM Launch the script with AHK v2
"%AHK_V2_PATH%" "%~dp0Template.ahk"

IF ERRORLEVEL 1 (
    ECHO.
    ECHO Error launching script!
    PAUSE
)
