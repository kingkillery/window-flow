# PowerShell script to launch Template.ahk with AutoHotkey v2
# Right-click and select "Run with PowerShell" to execute

$ahkV2Path = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$scriptPath = "$PSScriptRoot\Template.ahk"

# Check if AHK v2 exists
if (!(Test-Path $ahkV2Path)) {
    Write-Host "AutoHotkey v2 not found at: $ahkV2Path" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install AutoHotkey v2 from:" -ForegroundColor Yellow
    Write-Host "https://www.autohotkey.com/download/ahk-v2.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check if script exists
if (!(Test-Path $scriptPath)) {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Launch the script with AHK v2
Write-Host "Launching Template.ahk with AutoHotkey v2..." -ForegroundColor Green
Write-Host "Using: $ahkV2Path" -ForegroundColor Cyan
Write-Host ""

Start-Process -FilePath $ahkV2Path -ArgumentList "`"$scriptPath`""
