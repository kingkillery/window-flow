@echo off
setlocal enabledelayedexpansion

set "input_file=%~1"
set "temp_file=%TEMP%\react_context_%RANDOM%.txt"
set "output_file=%TEMP%\react_output_%RANDOM%.txt"

echo Processing file: %input_file%
echo Using ReAct reasoning mode...
echo.

rem Copy selected file content to temp location
copy "%input_file%" "%temp_file%" >nul 2>&1

rem Set ReAct mode and run PromptOpt
set PROMPTOPT_MODE=react
cd /d "C:\Users\prest\Desktop\Others\Scripts"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\promptopt\promptopt.ps1" -Mode "react" -SelectionFile "%temp_file%" -OutputFile "%output_file%" -MetaPromptDir ".\meta-prompts" -Model "openai/gpt-oss-120b" -Profile "general" -LogFile "%TEMP%\react_log_%RANDOM%.txt" -CopyToClipboard

if exist "%output_file%" (
    echo ReAct optimization complete! Result copied to clipboard.
    echo Original file: %input_file%
    echo.
    echo The optimized text is now in your clipboard - paste it wherever needed.
) else (
    echo Error: ReAct optimization failed. Check API key configuration.
)

rem Cleanup
if exist "%temp_file%" del "%temp_file%" 2>nul
if exist "%output_file%" del "%output_file%" 2>nul

echo.
pause