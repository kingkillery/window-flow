@echo off
setlocal

echo Installing PromptOpt Context Menu...
echo.

:: Remove old deprecated keys
reg delete "HKEY_CLASSES_ROOT\*\shell\PromptOptMeta" /f 2>nul
reg delete "HKEY_CLASSES_ROOT\*\shell\PromptOptReAct" /f 2>nul

:: ============================================================================
:: FILE CONTEXT MENU
:: ============================================================================

:: Custom Fill option for files
reg add "HKEY_CLASSES_ROOT\*\shell\PromptOptCustom" /ve /d "PromptOpt: Custom Fill..." /f
reg add "HKEY_CLASSES_ROOT\*\shell\PromptOptCustom" /v "Icon" /d "C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.ico,0" /f
reg add "HKEY_CLASSES_ROOT\*\shell\PromptOptCustom" /v "Position" /d "Top" /f
reg add "HKEY_CLASSES_ROOT\*\shell\PromptOptCustom\command" /ve /d "\"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe\" \"C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt_context.ahk\" \"%%1\" \"custom\"" /f

:: ============================================================================
:: DIRECTORY CONTEXT MENU (Right-click on a folder)
:: ============================================================================

:: Custom Fill option for directories
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCustom" /ve /d "PromptOpt: Custom Fill..." /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCustom" /v "Icon" /d "C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.ico,0" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCustom" /v "Position" /d "Top" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCustom\command" /ve /d "\"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe\" \"C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt_context.ahk\" \"%%1\" \"custom\"" /f

:: Copy Content option for directories
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCopy" /ve /d "PromptOpt: Copy All Text Content" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCopy" /v "Icon" /d "shell32.dll,260" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\PromptOptCopy\command" /ve /d "\"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe\" \"C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt_context.ahk\" \"%%1\" \"copyraw\"" /f

:: ============================================================================
:: DIRECTORY BACKGROUND CONTEXT MENU (Right-click inside a folder)
:: ============================================================================

:: Custom Fill option for clipboard content
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOptCustom" /ve /d "PromptOpt: Custom Fill (Clipboard)..." /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOptCustom" /v "Icon" /d "C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt.ico,0" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOptCustom" /v "Position" /d "Top" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\PromptOptCustom\command" /ve /d "\"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe\" \"C:\Users\prest\Desktop\Others\Scripts\promptopt\promptopt_context.ahk\" \"clipboard\" \"custom\"" /f

echo.
echo Installation Complete!
echo You may need to restart Explorer or sign out/in for changes to fully take effect.
