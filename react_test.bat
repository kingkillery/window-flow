@echo off
echo Testing ReAct mode directly...
echo.

set PROMPTOPT_MODE=react
set "SELECTION_FILE=test_selection.txt"
echo yeah go for it > "%SELECTION_FILE%"

echo Starting ReAct optimization...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\promptopt\promptopt.ps1" -Mode "react" -SelectionFile "%SELECTION_FILE%" -OutputFile "test_output.txt" -MetaPromptDir ".\meta-prompts" -Model "openai/gpt-oss-120b" -Profile "general" -LogFile "test_log.txt"

echo.
echo Done! Check test_output.txt for results
pause