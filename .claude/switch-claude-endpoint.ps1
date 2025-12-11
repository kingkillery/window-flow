# Claude Code Endpoint Switcher
# Switch between ZAI API endpoint and Claude Account Login modes

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("zai", "claude", "status", "interactive")]
    [string]$Mode = "interactive"
)

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"

function Get-BackupFilePath {
    return "$CLAUDE_DIR\settings.json.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
}

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ConsoleColor]$ForegroundColor,
        
        [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Message
    )
    
    $originalColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output ($Message -join ' ')
    $host.UI.RawUI.ForegroundColor = $originalColor
}

function Write-CleanJson {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Object,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    # Convert to JSON with standard formatting
    $json = $Object | ConvertTo-Json -Depth 10
    
    # Fix PowerShell's excessive whitespace to standard 2-space indentation
    $lines = $json -split "`r?`n"
    $cleanLines = @()
    
    foreach ($line in $lines) {
        # Count leading spaces and convert groups of 4+ spaces to 2-space indent
        if ($line -match '^(\s+)(.*)$') {
            $spaces = $matches[1]
            $content = $matches[2]
            $indentLevel = [math]::Floor($spaces.Length / 4)
            $newIndent = "  " * $indentLevel
            $cleanLines += "$newIndent$content"
        } else {
            $cleanLines += $line
        }
    }
    
    $cleanJson = $cleanLines -join "`n"
    
    # Write with UTF8 encoding (no BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($FilePath, $cleanJson, $utf8NoBom)
}

function Show-Status {
    $baseUrl = $null
    $token = $null
    $isAccountMode = $false
    $configSource = ""

    # Check environment variables first (User level)
    $envToken = [System.Environment]::GetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', 'User')
    $envBaseUrl = [System.Environment]::GetEnvironmentVariable('ANTHROPIC_BASE_URL', 'User')
    
    if ($envToken -or $envBaseUrl) {
        $token = $envToken
        $baseUrl = $envBaseUrl
        $configSource = "Environment Variables (User level)"
    } else {
        # Fall back to settings.json if no environment variables
        if (Test-Path $SETTINGS_FILE) {
            try {
                $settings = Get-Content $SETTINGS_FILE | ConvertFrom-Json
                if ($settings.env) {
                    $baseUrl = $settings.env.ANTHROPIC_BASE_URL
                    $token = $settings.env.ANTHROPIC_AUTH_TOKEN
                    $configSource = "Settings File ($SETTINGS_FILE)"
                }
            } catch {
                Write-ColorOutput Red "Error reading settings file: $_"
            }
        }
    }

    # Check if in account mode (no custom base URL and no token)
    if (-not $baseUrl -and -not $token) {
        $isAccountMode = $true
    }

    Write-ColorOutput Cyan "================================================"
    Write-ColorOutput Cyan "   Current Claude Code Configuration"
    Write-ColorOutput Cyan "================================================"
    Write-Output ""

    if ($configSource) {
        Write-ColorOutput Cyan "  Configuration Source: $configSource"
        Write-Output ""
    }

    if ($isAccountMode) {
        Write-ColorOutput Green "  Current Mode: Claude Account Login"
        Write-Output "  Authentication: Account-based (no API token)"
    } elseif ($baseUrl -and $baseUrl -eq "https://api.z.ai/api/anthropic") {
        Write-ColorOutput Yellow "  Current Mode: ZAI API"
        Write-Output "  Base URL: $baseUrl"
        if ($token) {
            $tokenPreview = $token.Substring(0, [Math]::Min(8, $token.Length))
            Write-Output "  Token: ${tokenPreview}..."
        } else {
            Write-ColorOutput Red "  Token: Not configured (ERROR: ZAI requires token)"
        }
    } else {
        Write-ColorOutput Cyan "  Current Mode: Custom API Configuration"
        if ($baseUrl) {
            Write-Output "  Base URL: $baseUrl"
        } else {
            Write-Output "  Base URL: https://api.anthropic.com (default)"
        }
        if ($token) {
            $tokenPreview = $token.Substring(0, [Math]::Min(8, $token.Length))
            Write-Output "  Token: ${tokenPreview}..."
        } else {
            Write-ColorOutput Yellow "  Token: Not configured"
        }
    }

    Write-Output ""
    Write-ColorOutput Cyan "================================================"
}

function Switch-ToZai {
    Write-ColorOutput Cyan "================================================"
    Write-ColorOutput Cyan "   Switching to ZAI Endpoint"
    Write-ColorOutput Cyan "================================================"
    Write-Output ""
    
    try {
        # Prompt for ZAI API token
        Write-ColorOutput Cyan "Please enter your ZAI API token:"
        Write-ColorOutput Yellow "(You can find this at: https://console.z.ai/)"
        $zaiToken = Read-Host "ZAI API Token"
        
        if ([string]::IsNullOrWhiteSpace($zaiToken)) {
            Write-ColorOutput Red "Error: API token cannot be empty."
            exit 1
        }
        
        if ($zaiToken.Length -lt 10) {
            Write-ColorOutput Red "Error: API token appears to be too short. Please verify your token."
            exit 1
        }
        
        # Set environment variables at User level (persistent)
        Write-ColorOutput Yellow "Setting environment variables..."
        
        $apiUrl = "https://api.z.ai/api/anthropic"
        $tokenVarName = "ANTHROPIC_AUTH_TOKEN"
        $urlVarName = "ANTHROPIC_BASE_URL"
        $scope = "User"
        
        [System.Environment]::SetEnvironmentVariable($tokenVarName, $zaiToken, $scope)
        [System.Environment]::SetEnvironmentVariable($urlVarName, $apiUrl, $scope)
        
        Write-Output ""
        Write-ColorOutput Green "✓ Successfully switched to ZAI endpoint!"
        Write-Output ""
        Write-ColorOutput Cyan "Configuration details:"
        Write-Output "  • API Endpoint: ZAI ($apiUrl)"
        Write-Output "  • Token: $($zaiToken.Substring(0, [Math]::Min(8, $zaiToken.Length)))..."
        Write-Output "  • Environment variables set at User level (persistent)"
        Write-Output ""
        Write-ColorOutput Yellow "Note: You may need to restart your terminal/PowerShell session"
        Write-ColorOutput Yellow "      for the environment variables to take effect."
        Write-Output ""
        Write-ColorOutput Green "You can now use Claude Code with ZAI endpoint:"
        Write-ColorOutput Cyan "  claude"
        Write-Output ""
    }
    catch {
        Write-ColorOutput Red "Error: Failed to set environment variables: $_"
        Write-ColorOutput Red "Exception details: $($_.Exception.Message)"
        exit 1
    }
}

function Switch-ToClaude {
    Write-ColorOutput Cyan "================================================"
    Write-ColorOutput Cyan "   Switching to Claude Account Login"
    Write-ColorOutput Cyan "================================================"
    Write-Output ""

    $BACKUP_FILE = Get-BackupFilePath

    try {
        # Backup existing settings
        if (Test-Path $SETTINGS_FILE) {
            Write-ColorOutput Yellow "Creating backup of current settings..."
            Copy-Item $SETTINGS_FILE $BACKUP_FILE -Force -ErrorAction Stop
            Write-ColorOutput Green "Backup created: $BACKUP_FILE"
            Write-Output ""

            # Read existing settings to preserve other config
            $settings = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json -ErrorAction Stop
        } else {
            Write-ColorOutput Yellow "No existing settings file found. Creating new configuration."
            Write-Output ""
            $settings = [PSCustomObject]@{
                enabledPlugins = @{}
                alwaysThinkingEnabled = $true
            }
        }

        # Remove the env object entirely for account login mode
        # This forces Claude Code to use account-based authentication
        if ($settings.PSObject.Properties.Name -contains "env") {
            $settings.PSObject.Properties.Remove("env")
            Write-ColorOutput Yellow "Removed API configuration for account login mode"
        }

        # Ensure .claude directory exists
        if (-not (Test-Path $CLAUDE_DIR)) {
            New-Item -ItemType Directory -Path $CLAUDE_DIR -Force -ErrorAction Stop | Out-Null
        }

        # Write updated settings with clean JSON formatting
        Write-CleanJson -Object $settings -FilePath $SETTINGS_FILE

        Write-Output ""
        Write-ColorOutput Green "✓ Successfully switched to Claude Account Login mode!"
        Write-Output ""
        Write-ColorOutput Cyan "Configuration details:"
        Write-Output "  • Authentication: Account-based login"
        Write-Output "  • No API token required"
        Write-Output "  • Will prompt for Claude account login"
        Write-Output ""
        Write-ColorOutput Cyan "Important:"
        Write-Output "  • Make sure you're logged in with 'claude auth login'"
        Write-Output "  • Or use 'claude' command and follow account login prompts"
        Write-Output ""
        Write-ColorOutput Green "You can now use Claude Code with your Claude account:"
        Write-ColorOutput Cyan "  claude"
        Write-Output ""
    }
    catch {
        Write-ColorOutput Red "Error: Failed to update settings: $_"
        if (Test-Path $BACKUP_FILE) {
            Write-ColorOutput Yellow "Attempting to restore from backup..."
            try {
                Copy-Item $BACKUP_FILE $SETTINGS_FILE -Force -ErrorAction Stop
                Write-ColorOutput Green "Settings restored from backup."
            }
            catch {
                Write-ColorOutput Red "Failed to restore backup: $_"
            }
        }
        exit 1
    }
}

# Main execution
Write-Output ""

# Helper function to invoke script functions reliably with -File execution
function Invoke-ScriptFunction {
    param([string]$FunctionName)
    $cmd = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue
    if ($cmd) {
        & $cmd
    } else {
        Write-Error "Function '$FunctionName' not found. This may indicate a scoping issue."
        exit 1
    }
}

# Handle parameter modes - using Get-Command for -File compatibility
# Get-Command ensures functions are accessible when using -File execution
if ($Mode -eq "status") {
    Invoke-ScriptFunction -FunctionName "Show-Status"
    exit 0
}
elseif ($Mode -eq "zai") {
    Invoke-ScriptFunction -FunctionName "Switch-ToZai"
    exit 0
}
elseif ($Mode -eq "claude") {
    Invoke-ScriptFunction -FunctionName "Switch-ToClaude"
    exit 0
}
elseif ($Mode -eq "interactive") {
    # Fall through to interactive mode below
}
else {
    Write-ColorOutput Red "Invalid mode: $Mode"
    exit 1
}

# Interactive mode
Invoke-ScriptFunction -FunctionName "Show-Status"
Write-Output ""
Write-ColorOutput Cyan "What would you like to do?"
Write-Output ""
Write-Output "  1) Switch to ZAI API endpoint (requires API token)"
Write-Output "  2) Switch to Claude Account Login (no API token)"
Write-Output "  3) Show current status only"
Write-Output "  4) Exit"
Write-Output ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        Invoke-ScriptFunction -FunctionName "Switch-ToZai"
    }
    "2" {
        Invoke-ScriptFunction -FunctionName "Switch-ToClaude"
    }
    "3" {
        Invoke-ScriptFunction -FunctionName "Show-Status"
    }
    "4" {
        Write-Output "Exiting..."
        exit 0
    }
    default {
        Write-ColorOutput Red "Invalid choice. Exiting..."
        exit 1
    }
}

