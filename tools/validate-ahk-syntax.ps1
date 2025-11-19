#!/usr/bin/env pwsh
# Comprehensive AHK Syntax Validator
# Scans all AHK files in the codebase for syntax issues

param(
    [string]$Path = ".",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Get all AHK files
$ahkFiles = Get-ChildItem -Path $Path -Filter "*.ahk" -Recurse
$totalFiles = $ahkFiles.Count
$filesWithErrors = 0

Write-Host "AHK Syntax Validator - Scanning $totalFiles files..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($file in $ahkFiles) {
    Write-Host "Checking: $($file.FullName)" -ForegroundColor White

    try {
        # Read file content and check for common AHK syntax issues
        $content = Get-Content -Path $file.FullName -Raw
        $lines = $content -split "`r`n|`n|`r"
        $hasErrors = $false

        # Common AHK syntax patterns to check
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineNum = $i + 1
            $line = $lines[$i]

            # Check for problematic quote patterns
            if ($line -match '[^``][""][^""]*[""][^``]') {
                Write-Host "  Line $lineNum`: Possible quote nesting issue:" -ForegroundColor Yellow
                Write-Host "    $line" -ForegroundColor Gray
                $hasErrors = $true
            }

            # Check for missing escaping in continuation sections
            if ($line -match 'text \.=.*".*".*"`' -and $line -notmatch '````') {
                Write-Host "  Line $lineNum`: Possible string concatenation issue:" -ForegroundColor Yellow
                Write-Host "    $line" -ForegroundColor Gray
                $hasErrors = $true
            }

            # Check for hotstring syntax issues
            if ($line -match '^:[^:]*:[^:]+::' -and $line -notmatch '^:\w*:\w*::') {
                Write-Host "  Line $lineNum`: Possible hotstring syntax issue:" -ForegroundColor Yellow
                Write-Host "    $line" -ForegroundColor Gray
                $hasErrors = $true
            }

            # Check for missing braces in blocks
            if ($line -match '\{' -and ($lines[$i..($i+10)] -notmatch '\}')) {
                # Only flag if it's clearly a code block, not object literal
                if ($line -match '(if|while|for|function|class)\s*\{' -or
                    ($lines[0..($i-1)] -join "`n" -match '(if|while|for|function|class)\s*$')) {
                    Write-Host "  Line $lineNum`: Possible missing closing brace:" -ForegroundColor Yellow
                    Write-Host "    $line" -ForegroundColor Gray
                    $hasErrors = $true
                }
            }
        }

        if ($hasErrors) {
            $filesWithErrors++
            Write-Host "  ❌ Issues found" -ForegroundColor Red
        } else {
            Write-Host "  ✅ Syntax looks good" -ForegroundColor Green
        }

    } catch {
        Write-Host "  ❌ Error reading file: $_" -ForegroundColor Red
        $filesWithErrors++
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scan Complete!" -ForegroundColor Cyan
Write-Host "Files scanned: $totalFiles" -ForegroundColor White
Write-Host "Files with issues: $filesWithErrors" -ForegroundColor $(if ($filesWithErrors -gt 0) { "Red" } else { "Green" })

if ($filesWithErrors -gt 0) {
    Write-Host ""
    Write-Host "Common AHK v2 Syntax Rules:" -ForegroundColor Yellow
    Write-Host "1. Use `` (grave accent) to escape quotes in strings: ``""''" -ForegroundColor Gray
    Write-Host "2. Hotstrings: :*:trigger::replacement" -ForegroundColor Gray
    Write-Host "3. Function calls require parentheses: myFunc(args)" -ForegroundColor Gray
    Write-Host "4. Variable declaration: myVar := ""value""" -ForegroundColor Gray
    Write-Host "5. String concatenation: result := part1 . part2" -ForegroundColor Gray
}

exit $filesWithErrors