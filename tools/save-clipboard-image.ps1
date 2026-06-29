# save-clipboard-image.ps1
# Saves the image currently on the Windows clipboard to a PNG file.
# Prints the full file path to stdout AND, if -OutFile is given, writes
# the path there (more robust than stdout redirection when launched
# from AutoHotkey). Exits 1 if the clipboard holds no image.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File save-clipboard-image.ps1 `
#       [-OutDir <dir>] [-OutFile <path>]

param(
    [string]$OutDir = "$env:USERPROFILE\Pictures\clipboard-save",
    [string]$OutFile = ""
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$img = [System.Windows.Forms.Clipboard]::GetImage()
if ($null -eq $img) {
    [Console]::Error.WriteLine("No image on clipboard.")
    exit 1
}

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyy-MM-dd HHmmss'
$path = Join-Path $OutDir ("Clipboard {0}.png" -f $stamp)

# Avoid clobbering if two pastes land in the same second.
$n = 1
while (Test-Path -LiteralPath $path) {
    $path = Join-Path $OutDir ("Clipboard {0} ({1}).png" -f $stamp, $n)
    $n++
}

$img.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()

# Write the path to -OutFile (robust for AHK), and also to stdout.
if ($OutFile -ne "") {
    # UTF8 without BOM so AHK reads a clean path.
    [System.IO.File]::WriteAllText($OutFile, $path, (New-Object System.Text.UTF8Encoding($false)))
}
Write-Output $path
