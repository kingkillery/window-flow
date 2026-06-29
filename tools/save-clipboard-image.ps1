# save-clipboard-image.ps1
# Saves the image currently on the Windows clipboard to a PNG file and
# prints the full file path to stdout. Exits non-zero with a message on
# stderr if the clipboard holds no image.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File save-clipboard-image.ps1 [-OutDir <dir>]

param(
    [string]$OutDir = "$env:USERPROFILE\Pictures\clipboard-save"
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

# Emit the path (no trailing newline noise beyond Write-Output's).
Write-Output $path
