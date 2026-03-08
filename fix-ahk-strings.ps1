# fix-ahk-strings.ps1 - Detects and fixes AHK v2 string literal parsing errors
# Usage: .\fix-ahk-strings.ps1 [-Fix] [-ReportOnly]
# Scans hotstrings/*.ahk for problematic patterns in text .= expressions

param(
    [switch]$Fix = $false,
    [switch]$ReportOnly = $false
)

$hotstringsDir = "hotstrings"
$files = Get-ChildItem -Path $hotstringsDir -Filter "*.ahk" -Recurse

$problematicPatterns = @{
    '≤' = '<='
    'â‰¤' = '<='  # mangled ≤
    '→' = '->'
    '∈' = 'in'
    '×' = 'x'
    '-&gt;' = '-->'
}

$report = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $lines = Get-Content $file.FullName -Encoding UTF8

    Write-Host "Scanning $($file.Name):" -ForegroundColor Yellow

    $issues = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match 'text \.\=') {
            foreach ($pat in $problematicPatterns.Keys) {
                if ($line -match [regex]::Escape($pat)) {
                    $issues += [PSCustomObject]@{
                        LineNum = $i + 1
                        Line = $line.Trim()
                        Pattern = $pat
                        Replacement = $problematicPatterns[$pat]
                        File = $file.Name
                    }
                }
            }
            # Nested double quotes
            if ($line -match 'text \.\=.*""[^"]*""') {
                $issues += [PSCustomObject]@{
                    LineNum = $i + 1
                    Line = $line.Trim()
                    Pattern = 'Nested ""'
                    Replacement = 'Use single quotes `'' for inner'
                    File = $file.Name
                }
            }
        }
    }

    if ($issues.Count -gt 0) {
        $report += $issues
        Write-Host "  Found $($issues.Count) issues" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "    Line $($_.LineNum): $($_.Line.Substring(0, [Math]::Min(80, $_.Line.Length)))... -> $($_.Replacement)" }
    } else {
        Write-Host "  Clean" -ForegroundColor Green
    }
}

if ($report.Count -gt 0) {
    Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
    $report | Group-Object File | ForEach-Object {
        Write-Host "$($_.Name): $($_.Count) issues" -ForegroundColor Yellow
    }

    if ($Fix -and -not $ReportOnly) {
        Write-Host "`nApplying fixes..." -ForegroundColor Green
        foreach ($issue in $report | Sort-Object File, LineNum) {
            $content = (Get-Content $issue.File -Raw -Encoding UTF8) -replace [regex]::Escape($issue.Pattern), $issue.Replacement
            Set-Content -Path $issue.File -Value $content -Encoding UTF8
            Write-Host "Fixed $($issue.File):L$($issue.LineNum)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "`nAll files clean! No issues found." -ForegroundColor Green
}

if ($ReportOnly) {
    $report | Export-Csv -Path "ahk-string-issues.csv" -NoTypeInformation
    Write-Host "`nReport saved to ahk-string-issues.csv" -ForegroundColor Cyan
}