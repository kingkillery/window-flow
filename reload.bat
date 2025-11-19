@echo off
REM ##################################################################
REM # AutoHotkey v2 Force-Reload Script                            #
REM # Purpose: Kills existing script processes to clear the cache  #
REM #          and relaunches the main script.                     #
REM ##################################################################

set "SCRIPT_NAME=Template.ahk"
set "SCRIPT_PATH=%~dp0%SCRIPT_NAME%"
set "AHK_EXE=AutoHotkey64.exe"

echo [1/3] Searching for running instances of %SCRIPT_NAME%...

REM Use tasklist to find the process. The findstr command filters for the script name.
tasklist /FI "IMAGENAME eq %AHK_EXE%" /FO CSV | findstr /I /C:"%SCRIPT_NAME%" > nul

REM Check the errorlevel. 0 means findstr found a match.
if %errorlevel% == 0 (
    echo [2/3] Found running process. Terminating to clear cache...
    REM Forcefully terminate the process(es) running the script.
    taskkill /F /FI "IMAGENAME eq %AHK_EXE%" /IM "%AHK_EXE%" > nul
    timeout /t 1 /nobreak > nul
    echo      Process terminated.
) else (
    echo [2/3] No running instances found. Skipping termination.
)

echo [3/3] Relaunching %SCRIPT_NAME%...
if exist "%SCRIPT_PATH%" (
    start "" "%SCRIPT_PATH%"
    echo      Script launched successfully.
) else (
    echo      ERROR: Script not found at %SCRIPT_PATH%
)

echo.
echo Reload complete.
pause