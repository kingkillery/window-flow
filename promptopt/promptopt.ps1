param(
  [string]$Mode = "meta",
  [Parameter(Mandatory = $true)][string]$SelectionFile,
  [Parameter(Mandatory = $true)][string]$OutputFile,
  [Parameter(Mandatory = $true)][string]$MetaPromptDir,
  [string]$ApiKey,
  [string]$Model = "openai/gpt-oss-120b",
  [string]$BaseUrl = "https://openrouter.ai/api/v1",
  [string]$Profile,
  [string]$LogFile,
  [string]$CustomPromptFile,
  [string]$ContextFilePath,
  [switch]$CopyToClipboard = $false
)

$ErrorActionPreference = 'Stop'

# ------- Minimal logging setup -------
if (-not $LogFile -or [string]::IsNullOrWhiteSpace($LogFile)) {
  $LogFile = Join-Path $env:TEMP ("promptopt_{0:yyyyMMdd}.log" -f (Get-Date))
}
function Write-Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  try {
    Add-Content -LiteralPath $LogFile -Encoding UTF8 -Value ("[$ts] " + $msg)
  } catch {}
}
Write-Log "--- PromptOpt start (Mode=$Mode, Model=$Model) ---"
Write-Log "Args: SelectionFile='$SelectionFile' OutputFile='$OutputFile' MetaPromptDir='$MetaPromptDir' BaseUrl='$BaseUrl'"

# Env-based overrides for Mode/Model when caller uses defaults
if ((-not $PSBoundParameters.ContainsKey('Mode')) -and $env:PROMPTOPT_MODE -and -not [string]::IsNullOrWhiteSpace($env:PROMPTOPT_MODE)) {
  $Mode = $env:PROMPTOPT_MODE
  Write-Log "Mode overridden from PROMPTOPT_MODE: $Mode"
}
if ((-not $PSBoundParameters.ContainsKey('Model')) -and $env:OPENAI_MODEL -and -not [string]::IsNullOrWhiteSpace($env:OPENAI_MODEL)) {
  $Model = $env:OPENAI_MODEL
  Write-Log "Model overridden from OPENAI_MODEL: $Model"
}

# Profile (domain) selection: prefer explicit param, then env, default to 'browser'
if ((-not $PSBoundParameters.ContainsKey('Profile')) -and $env:PROMPTOPT_PROFILE -and -not [string]::IsNullOrWhiteSpace($env:PROMPTOPT_PROFILE)) {
  $Profile = $env:PROMPTOPT_PROFILE
  Write-Log "Profile overridden from PROMPTOPT_PROFILE: $Profile"
}
if ([string]::IsNullOrWhiteSpace($Profile)) { $Profile = 'browser' }
Write-Log "Profile=$Profile"

# ------- Load .env into the process environment -------
function Import-DotEnv([string]$path) {
  try {
    if (-not (Test-Path -LiteralPath $path)) { return }
    Write-Log "Loading .env: $path"
    Get-Content -LiteralPath $path | ForEach-Object {
      $line = $_.Trim()
      if ([string]::IsNullOrWhiteSpace($line)) { return }
      if ($line.StartsWith('#')) { return }
      $kv = $line -split '=', 2
      if ($kv.Count -lt 2) { return }
      $k = $kv[0].Trim()
      $v = $kv[1].Trim()
      if ($v -match '^\s*"(.*)"\s*$') { $v = $Matches[1] }  # strip double quotes
      elseif ($v -match "^\s*'(.*)'\s*$") { $v = $Matches[1] } # strip single quotes
      # Additional trim to remove any remaining whitespace (important for API keys)
      $v = $v.Trim()
      if (-not [string]::IsNullOrWhiteSpace($k)) {
        [System.Environment]::SetEnvironmentVariable($k, $v, 'Process')
      }
    }
  } catch { Write-Log ("WARN: .env load failed: " + $_) }
}

$dotenv1 = Join-Path $MetaPromptDir '.env'
Import-DotEnv $dotenv1
if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.env'))) {
  Import-DotEnv (Join-Path $PSScriptRoot '.env')
}

# Allow OPENAI_BASE_URL env to override BaseUrl.
# Template.ahk always passes the default 'https://openrouter.ai/api/v1', which prevents
# env overrides from taking effect. To be user-friendly, if BaseUrl equals the default
# and OPENAI_BASE_URL is set, prefer the env value.
$defaultBase = 'https://openrouter.ai/api/v1'
if ($env:OPENAI_BASE_URL -and -not [string]::IsNullOrWhiteSpace($env:OPENAI_BASE_URL)) {
  if ((-not $PSBoundParameters.ContainsKey('BaseUrl')) -or ($BaseUrl -eq $defaultBase)) {
    $BaseUrl = $env:OPENAI_BASE_URL
    Write-Log "BaseUrl overridden from OPENAI_BASE_URL: $BaseUrl"
  }
}

if (-not (Test-Path -LiteralPath $SelectionFile)) {
  Write-Log "ERROR: Selection file not found: $SelectionFile"
  throw "Selection file not found: $SelectionFile"
}

$userText = Get-Content -LiteralPath $SelectionFile -Raw -Encoding UTF8
if ($ContextFilePath -and -not [string]::IsNullOrWhiteSpace($ContextFilePath)) {
    Write-Log "Appending context file path: $ContextFilePath"
    $userText = "Target File: $ContextFilePath`n`n" + $userText
}
Write-Log ("Selection length=" + ($userText.Length))

function Get-MetaPrompt([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return "" }
  $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  $m = [regex]::Match($raw, 'META_PROMPT\s*=\s*"""(.*?)"""', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($m.Success) { return ($m.Groups[1].Value.Trim()) }
  return ""
}

# Resolve meta prompt file based on Mode and Profile, with fallback
# If CustomPromptFile is provided, use it directly (for custom profile)
$sysPrompt = ""
if ($CustomPromptFile -and -not [string]::IsNullOrWhiteSpace($CustomPromptFile) -and (Test-Path -LiteralPath $CustomPromptFile)) {
  Write-Log "Using custom prompt file: $CustomPromptFile"
  $sysPrompt = Get-Content -LiteralPath $CustomPromptFile -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($sysPrompt)) {
    Write-Log "WARN: Custom prompt file is empty, falling back to default"
    $sysPrompt = ""
  }
}

# If no custom prompt was provided or it was empty, resolve from meta-prompt files
if ([string]::IsNullOrWhiteSpace($sysPrompt)) {
  $baseName = if ($Mode -eq 'edit') { 'Meta_Prompt_Edits' } else { 'Meta_Prompt' }
  $profileNorm = $Profile
  if ($null -eq $profileNorm) { $profileNorm = '' }
  $profileNorm = $profileNorm.Trim().ToLowerInvariant()
  $candidates = @()
  if ($profileNorm) {
    $candidates += (Join-Path $MetaPromptDir ("$baseName.$profileNorm.md"))
  }
  $candidates += (Join-Path $MetaPromptDir ("$baseName.md"))
  $metaFile = $null
  foreach ($cand in $candidates) {
    if (Test-Path -LiteralPath $cand) { $metaFile = $cand; break }
  }
  if (-not $metaFile) { $metaFile = (Join-Path $MetaPromptDir ("$baseName.md")) }
  Write-Log "Meta prompt file: $metaFile"
  $sysPrompt = Get-MetaPrompt $metaFile
  if ([string]::IsNullOrWhiteSpace($sysPrompt)) {
    if ($Mode -eq 'edit') {
      $sysPrompt = 'Given a current prompt and change description, output a corrected, improved system prompt optimized for accurate results. Start with a <reasoning> section, then output the final prompt only.'
    } else {
      $sysPrompt = 'Given a task or existing prompt, output a clear, effective system prompt to guide the model. Output only the final prompt text.'
    }
  }
}
Write-Log ("System prompt length=" + ($sysPrompt.Length))

$sysFile = Join-Path $env:TEMP ("promptopt_sys_{0}.txt" -f ([DateTime]::UtcNow.Ticks))
Set-Content -LiteralPath $sysFile -Encoding UTF8 -NoNewline -Value $sysPrompt

# ------- Optional dry-run (offline) path -------
# If PROMPTOPT_DRYRUN is set (e.g., to "1"), bypass network and write
# a locally synthesized prompt so the end-to-end flow remains usable.
if ($env:PROMPTOPT_DRYRUN -and $env:PROMPTOPT_DRYRUN.Trim()) {
  Write-Log "PROMPTOPT_DRYRUN is set; generating offline output."
  $offline = @()
  if ($Mode -eq 'edit') {
    $offline += '<reasoning>offline mode: producing best-effort edit without network</reasoning>'
  }
  $offline += 'You are an expert prompt engineer. Improve and structure the following task.'
  $offline += ''
  $offline += '# Task'
  $offline += $userText.Trim()
  $offline += ''
  $offline += '# Output Format'
  $offline += '- Return only the final prompt text.'
  try {
    $txt = ($offline -join "`r`n")
    if ($env:PROMPTOPT_DRYRUN_STREAM -and $env:PROMPTOPT_DRYRUN_STREAM.Trim()) {
      Write-Log 'Dry-run streaming enabled.'
      if (Test-Path -LiteralPath $OutputFile) { Remove-Item -LiteralPath $OutputFile -Force }
      $step = 24
      for ($i = 0; $i -lt $txt.Length; $i += $step) {
        $piece = if ($i + $step -le $txt.Length) { $txt.Substring($i, $step) } else { $txt.Substring($i) }
        Add-Content -LiteralPath $OutputFile -Encoding UTF8 -NoNewline -Value $piece
        Start-Sleep -Milliseconds 80
      }
    } else {
      Set-Content -LiteralPath $OutputFile -Encoding UTF8 -NoNewline -Value $txt
    }
    if ($CopyToClipboard) { $txt | Set-Clipboard }
    Write-Log "Offline output written via dry-run."
    try { Remove-Item -LiteralPath $sysFile -Force } catch {}
    Write-Log "--- PromptOpt done (dry-run) ---"
    exit 0
  } catch {
    Write-Log ("ERROR: Dry-run write failed: " + $_)
    throw
  }
}

function Get-Python() {
  $candidates = @('py','python','python3')
  foreach ($c in $candidates) {
    try {
      $ver = & $c -c "import sys; print(sys.version_info[0])" 2>$null
      if ($LASTEXITCODE -eq 0 -and $ver) { return $c }
    } catch {}
  }
  throw 'Python not found. Install Python 3 and ensure it is in PATH.'
}

$python = Get-Python
Write-Log "Python exe: $python"
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { $MetaPromptDir }
$pyPath = Join-Path $scriptDir 'promptopt.py'
if (-not (Test-Path -LiteralPath $pyPath)) { Write-Log "ERROR: Missing Python script: $pyPath"; throw "Missing Python script: $pyPath" }

if (Test-Path -LiteralPath $OutputFile) { Remove-Item -LiteralPath $OutputFile -Force }

if (-not $ApiKey -or [string]::IsNullOrWhiteSpace($ApiKey)) {
  $ApiKey = $env:PROMPTOPT_API_KEY
}
if (-not $ApiKey -or [string]::IsNullOrWhiteSpace($ApiKey)) {
  # Prefer OPENAI_API_KEY by default
  $ApiKey = $env:OPENAI_API_KEY
}
# If targeting OpenRouter and an OPENROUTER_API_KEY exists, prefer it
if (($BaseUrl -like '*openrouter.ai*') -and $env:OPENROUTER_API_KEY -and -not [string]::IsNullOrWhiteSpace($env:OPENROUTER_API_KEY)) {
  $ApiKey = $env:OPENROUTER_API_KEY
  Write-Log 'Using OPENROUTER_API_KEY due to BaseUrl openrouter.ai'
  # Log key prefix for debugging (without exposing full key)
  if ($ApiKey -and $ApiKey.Length -gt 4) {
    Write-Log ("API key prefix: " + $ApiKey.Substring(0, [Math]::Min(7, $ApiKey.Length)) + "... (length: " + $ApiKey.Length + ")")
  } else {
    Write-Log "WARN: OPENROUTER_API_KEY appears to be empty or invalid"
  }
}

# Auto-align provider to key style if mismatched
try {
  $isOpenRouterBase = ($BaseUrl -like '*openrouter.ai*')
  $keyLooksOpenRouter = ($ApiKey -and ($ApiKey -like 'sk-or-*'))
  if ($isOpenRouterBase -and -not $keyLooksOpenRouter) {
    if ($env:OPENROUTER_API_KEY -and -not [string]::IsNullOrWhiteSpace($env:OPENROUTER_API_KEY)) {
      $ApiKey = $env:OPENROUTER_API_KEY
      Write-Log 'Switched ApiKey to OPENROUTER_API_KEY because BaseUrl targets openrouter.ai'
    } else {
      $BaseUrl = 'https://api.openai.com/v1'
      Write-Log 'BaseUrl switched to https://api.openai.com/v1 because provided key is not OpenRouter-style.'
    }
  }
  if (($BaseUrl -like '*api.openai.com*') -and $keyLooksOpenRouter) {
    $BaseUrl = 'https://openrouter.ai/api/v1'
    Write-Log 'BaseUrl switched to https://openrouter.ai/api/v1 because key looks like OpenRouter.'
  }
} catch { Write-Log ("WARN: Provider/key alignment check failed: " + $_) }
if (-not $ApiKey -or [string]::IsNullOrWhiteSpace($ApiKey)) {
  Write-Log 'ERROR: API key not provided.'
  throw 'API key not provided. Set PROMPTOPT_API_KEY or OPENAI_API_KEY.'
}

# Validate API key format
if ($ApiKey.Length -lt 10) {
  Write-Log "WARN: API key appears too short (length: $($ApiKey.Length))"
}

$argsList = @(
  $pyPath,
  '--system-prompt-file', $sysFile,
  '--user-input-file', $SelectionFile,
  '--output-file', $OutputFile,
  '--model', $Model,
  '--base-url', $BaseUrl
)

# Pass key via environment to avoid command-line exposure
$env:PROMPTOPT_API_KEY = $ApiKey
# Verify it was set correctly
if (-not $env:PROMPTOPT_API_KEY -or [string]::IsNullOrWhiteSpace($env:PROMPTOPT_API_KEY)) {
  Write-Log 'ERROR: Failed to set PROMPTOPT_API_KEY environment variable'
  throw 'Failed to set PROMPTOPT_API_KEY environment variable'
}

# Enable Python streaming when requested via env flag
if ($env:PROMPTOPT_STREAM -and $env:PROMPTOPT_STREAM.Trim()) {
  $argsList += @('--stream')
  Write-Log 'Streaming enabled via PROMPTOPT_STREAM.'
}

Write-Log "Invoking Python backend..."
$cmdline = ($argsList | ForEach-Object { '"' + ($_ -replace '"','\"') + '"' }) -join ' '
Write-Log ("Python cmd: " + $python + ' ' + $cmdline)
# Avoid terminating errors from native stderr by lowering EAP during call
$env:PYTHONUTF8 = "1"
$env:PYTHONUNBUFFERED = "1"
$oldEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$pyOutput = & $python $argsList 2>&1
$eapTmp = $Error
$ErrorActionPreference = $oldEap
if ($pyOutput) { $pyOutput | ForEach-Object { Write-Log ("py: " + $_) } }
Write-Log ("Python exit code=" + $LASTEXITCODE)
if ($LASTEXITCODE -ne 0) { Write-Log "ERROR: Python call failed."; throw "Python call failed with exit code $LASTEXITCODE" }

if (-not (Test-Path -LiteralPath $OutputFile)) { Write-Log 'ERROR: No output produced.'; throw 'No output produced.' }

try {
  $out = Get-Content -LiteralPath $OutputFile -Raw -Encoding UTF8
  Write-Log ("Output length=" + ($out.Length))
  if ($CopyToClipboard) {
    try { $out | Set-Clipboard; Write-Log "Clipboard updated." } catch { Write-Log ("WARN: Failed to set clipboard: " + $_) }
  } else {
    Write-Log "Clipboard not updated (CopyToClipboard=false)."
  }
} catch { Write-Log ("WARN: Failed to read output file: " + $_) }

try { Remove-Item -LiteralPath $sysFile -Force } catch {}
Write-Log "--- PromptOpt done ---"
