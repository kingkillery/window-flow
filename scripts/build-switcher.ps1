param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "src\WindowFlow.Switcher\Program.cs"
$binDir = Join-Path $root "bin"
$output = Join-Path $binDir "WindowFlow.Switcher.exe"
$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path $csc)) {
    throw "csc.exe not found at $csc"
}

New-Item -ItemType Directory -Force -Path $binDir | Out-Null

& $csc `
    /nologo `
    /target:exe `
    /optimize+ `
    /out:$output `
    /r:System.dll `
    /r:System.Drawing.dll `
    /r:System.Windows.Forms.dll `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}

Write-Host "Built $output"
