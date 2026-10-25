<#
.SYNOPSIS
    Launches Claude Code with model selection via OmniRoute proxy.

.DESCRIPTION
    This script sets up the environment for Claude Code, starts the OmniRoute
    proxy if needed, and launches Claude with the selected model.

.PARAMETER Command
    The Claude command to run (e.g., "claude" or "claude make team work").
    If not provided, will prompt interactively.

.PARAMETER Model
    The model number to use (1-9). If not provided, will prompt interactively.

.EXAMPLE
    .\start_claude.ps1
    .\start_claude.ps1 -Command "claude" -Model 1
#>

param(
    [string]$Command = "",
    [int]$Model = 0
)

# Color output helper
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Model definitions
$MODELS = @{
    1 = "kr/claude-sonnet-4.5"
    2 = "kr/glm-5"
    3 = "agentrouter/claude-opus-5"
    4 = "agentrouter/claude-opus-4.8"
    5 = "agentrouter/deepseek-v4-flash"
    6 = "agentrouter/gpt-5.6-sol"
    7 = "agentrouter/glm-5.3"
    8 = "nvidia/nvidia/nemotron-3-super-120b-a12b"
    9 = "nvidia/nvidia/nemotron-3-ultra-550b-a55b"
}

# ============================================
# Step 1: Get Claude Command
# ============================================
if ([string]::IsNullOrEmpty($Command)) {
    $Command = Read-Host "Enter Claude command (e.g., 'claude' or 'claude make team work')"
}

# ============================================
# Step 2: Get Auth Token
# ============================================
Write-ColorOutput "`nChecking authentication token..." "Cyan"

$authToken = $env:ANTHROPIC_AUTH_TOKEN

if ([string]::IsNullOrEmpty($authToken)) {
    Write-ColorOutput "ANTHROPIC_AUTH_TOKEN environment variable not set." "Yellow"
    Write-ColorOutput "Please enter your auth token (input will be hidden):" "Yellow"

    $secureToken = Read-Host -AsSecureString
    $authToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    )
}

# ============================================
# Step 3: Select Model
# ============================================
Write-ColorOutput "`nSelect Claude model:" "Cyan"
Write-Host " 1. kr/claude-sonnet-4.5"
Write-Host " 2. kr/glm-5"
Write-Host " 3. agentrouter/claude-opus-5"
Write-Host " 4. agentrouter/claude-opus-4.8"
Write-Host " 5. agentrouter/deepseek-v4-flash"
Write-Host " 6. agentrouter/gpt-5.6-sol"
Write-Host " 7. agentrouter/glm-5.3"
Write-Host " 8. nvidia/nvidia/nemotron-3-super-120b-a12b"
Write-Host " 9. nvidia/nvidia/nemotron-3-ultra-550b-a55b"
Write-Host ""

if ($Model -lt 1 -or $Model -gt 9) {
    $ModelInput = Read-Host "Enter model number (1-9)"

    if ($ModelInput -notmatch '^[1-9]$') {
        Write-ColorOutput "ERROR: Invalid model choice. Please enter a number from 1 to 9." "Red"
        exit 1
    }

    $Model = [int]$ModelInput
}

$selectedModel = $MODELS[$Model]
Write-ColorOutput "Selected model: $selectedModel" "Green"

# ============================================
# Step 4: Check and Start Omniroute
# ============================================
Write-ColorOutput "`nChecking OmniRoute status..." "Cyan"

$omniroutePort = 20128
$omnirouteUrl = "http://localhost:$omniroutePort"

# Function to test if OmniRoute is healthy via HTTP GET
function Test-OmnirouteHealth {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check if OmniRoute is already healthy
if (Test-OmnirouteHealth -Url $omnirouteUrl) {
    Write-ColorOutput "OmniRoute is already running and healthy." "Green"
}
else {
    Write-ColorOutput "OmniRoute is not running. Starting it..." "Yellow"

    # Start OmniRoute in a new window
    $omnirouteProcess = Start-Process -FilePath "powershell" `
        -ArgumentList "-NoExit", "-Command", "Write-Host 'OmniRoute Server' -ForegroundColor Cyan; Write-Host 'Press Ctrl+C to stop'; Write-Host ''; omniroute" `
        -PassThru `
        -WindowStyle Normal

    Write-ColorOutput "OmniRoute started in separate window (PID: $($omnirouteProcess.Id))" "Green"

    # Wait for OmniRoute to become healthy
    $maxAttempts = 30
    $attempt = 0

    Write-ColorOutput "Waiting for OmniRoute to become healthy..." "Cyan"

    while ($attempt -lt $maxAttempts) {
        $attempt++
        Start-Sleep -Seconds 1

        if (Test-OmnirouteHealth -Url $omnirouteUrl) {
            Write-ColorOutput "OmniRoute is now healthy (attempt $attempt/$maxAttempts)" "Green"
            break
        }
        else {
            Write-Host "Waiting... (attempt $attempt/$maxAttempts)"
        }
    }

    # Final check
    if (-not (Test-OmnirouteHealth -Url $omnirouteUrl)) {
        Write-ColorOutput "ERROR: OmniRoute failed to start after $maxAttempts seconds." "Red"
        Write-ColorOutput "Check the OmniRoute window for error messages." "Yellow"
        exit 1
    }
}

# ============================================
# Step 5: Set Environment Variables
# ============================================
Write-ColorOutput "`nSetting up environment..." "Cyan"

$env:ANTHROPIC_AUTH_TOKEN = $authToken
$env:ANTHROPIC_BASE_URL = "http://localhost:$omniroutePort/v1"
$env:ANTHROPIC_MODEL = $selectedModel
$env:ANTHROPIC_deepseek_MODEL = "deepseek-v4-flash"
$env:ENABLE_CC_COMPATIBLE_PROVIDER = "true"
$env:CLAUDE_CODE_SKIP_UPDATE_CHECK = "1"
$env:CLAUDE_CODE_DISABLE_ARTIFACT = "1"

Write-ColorOutput "Environment configured:" "Green"
Write-Host "  ANTHROPIC_MODEL = $selectedModel"
Write-Host "  ANTHROPIC_BASE_URL = $env:ANTHROPIC_BASE_URL"

# ============================================
# Step 6: Launch Claude
# ============================================
Write-ColorOutput "`nStarting Claude Code via OmniRoute..." "Cyan"
Write-ColorOutput "Command: $Command" "White"
Write-ColorOutput "`n========================================" "DarkGray"
Write-Host ""

# Execute the Claude command
try {
    Invoke-Expression $Command
}
catch {
    Write-ColorOutput "`nERROR: Failed to execute command." "Red"
    Write-ColorOutput $_.Exception.Message "Red"
    exit 1
}

# ============================================
# Cleanup Instructions
# ============================================
Write-ColorOutput "`n========================================" "DarkGray"
Write-ColorOutput "Session ended." "Cyan"
Write-ColorOutput "Omniroute is still running in the separate window." "Yellow"
Write-ColorOutput "Close that window when you're done, or leave it for next time." "Yellow"
