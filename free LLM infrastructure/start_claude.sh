#!/bin/bash
#
# SYNOPSIS
#     Launches Claude Code with model selection via OmniRoute proxy.
#
# DESCRIPTION
#     This script sets up the environment for Claude Code, starts the OmniRoute
#     proxy if needed, and launches Claude with the selected model.
#
# USAGE
#     ./start_claude.sh
#     ./start_claude.sh -c "claude" -m 1
#
# OPTIONS
#     -c, --command    The Claude command to run (default: prompt interactively)
#     -m, --model      The model number to use, 1-9 (default: prompt interactively)
#     -h, --help       Show this help message
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
COMMAND=""
MODEL=0

# Model definitions
declare -A MODELS
MODELS[1]="kr/claude-sonnet-4.5"
MODELS[2]="kr/glm-5"
MODELS[3]="agentrouter/claude-opus-5"
MODELS[4]="agentrouter/claude-opus-4.8"
MODELS[5]="agentrouter/deepseek-v4-flash"
MODELS[6]="agentrouter/gpt-5.6-sol"
MODELS[7]="agentrouter/glm-5.3"
MODELS[8]="nvidia/nvidia/nemotron-3-super-120b-a12b"
MODELS[9]="nvidia/nvidia/nemotron-3-ultra-550b-a55b"

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Launches Claude Code with model selection via OmniRoute proxy.

Options:
    -c, --command    The Claude command to run (default: prompt interactively)
    -m, --model      The model number to use, 1-9 (default: prompt interactively)
    -h, --help       Show this help message

Models:
 1. kr/claude-sonnet-4.5
 2. kr/glm-5
 3. agentrouter/claude-opus-5
 4. agentrouter/claude-opus-4.8
 5. agentrouter/deepseek-v4-flash
 6. agentrouter/gpt-5.6-sol
 7. agentrouter/glm-5.3
 8. nvidia/nvidia/nemotron-3-super-120b-a12b
 9. nvidia/nvidia/nemotron-3-ultra-550b-a55b

Examples:
    $(basename "$0")
    $(basename "$0") -c "claude" -m 1
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--command)
            COMMAND="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}ERROR: Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Color output function
color_print() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to test if OmniRoute is healthy
test_omniroute_health() {
    local url="http://localhost:20128"
    if command -v curl &> /dev/null; then
        curl -sf --max-time 3 "$url" > /dev/null 2>&1
    elif command -v wget &> /dev/null; then
        wget -q --timeout=3 --spider "$url" 2>/dev/null
    else
        echo -e "${RED}ERROR: Neither curl nor wget is available${NC}"
        exit 1
    fi
}

# ============================================
# Step 1: Get Claude Command
# ============================================
if [[ -z "$COMMAND" ]]; then
    read -p "Enter Claude command (e.g., 'claude' or 'claude make team work'): " COMMAND
fi

# ============================================
# Step 2: Get Auth Token
# ============================================
color_print $CYAN "\nChecking authentication token..."

AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"

if [[ -z "$AUTH_TOKEN" ]]; then
    color_print $YELLOW "ANTHROPIC_AUTH_TOKEN environment variable not set."
    color_print $YELLOW "Please enter your auth token (input will be hidden):"
    read -s AUTH_TOKEN
    echo ""
fi

# ============================================
# Step 3: Select Model
# ============================================
color_print $CYAN "\nSelect Claude model:"
echo " 1. kr/claude-sonnet-4.5"
echo " 2. kr/glm-5"
echo " 3. agentrouter/claude-opus-5"
echo " 4. agentrouter/claude-opus-4.8"
echo " 5. agentrouter/deepseek-v4-flash"
echo " 6. agentrouter/gpt-5.6-sol"
echo " 7. agentrouter/glm-5.3"
echo " 8. nvidia/nvidia/nemotron-3-super-120b-a12b"
echo " 9. nvidia/nvidia/nemotron-3-ultra-550b-a55b"
echo ""

if [[ $MODEL -lt 1 || $MODEL -gt 9 ]]; then
    read -p "Enter model number (1-9): " MODEL

    if ! [[ "$MODEL" =~ ^[1-9]$ ]]; then
        color_print $RED "ERROR: Invalid model choice. Please enter a number from 1 to 9."
        exit 1
    fi
fi

SELECTED_MODEL="${MODELS[$MODEL]}"
color_print $GREEN "Selected model: $SELECTED_MODEL"

# ============================================
# Step 4: Check and Start Omniroute
# ============================================
color_print $CYAN "\nChecking OmniRoute status..."

OMNIROUTE_URL="http://localhost:20128"
OMNIROUTE_PORT=20128

if test_omniroute_health; then
    color_print $GREEN "OmniRoute is already running and healthy."
else
    color_print $YELLOW "OmniRoute is not running. Starting it..."

    # Start OmniRoute in a new terminal window
    # Try different terminal emulators
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "echo -e '\033[0;36mOmniRoute Server\033[0m'; echo 'Press Ctrl+C to stop'; echo ''; omniroute; exec bash"
    elif command -v xterm &> /dev/null; then
        xterm -e "echo -e '\033[0;36mOmniRoute Server\033[0m'; echo 'Press Ctrl+C to stop'; echo ''; omniroute; bash" &
    elif command -v konsole &> /dev/null; then
        konsole -e bash -c "echo -e '\033[0;36mOmniRoute Server\033[0m'; echo 'Press Ctrl+C to stop'; echo ''; omniroute; exec bash"
    elif command -v terminator &> /dev/null; then
        terminator -e "bash -c 'echo -e \"\\033[0;36mOmniRoute Server\\033[0m\"; echo \"Press Ctrl+C to stop\"; echo \"\"; omniroute; exec bash'"
    elif command -v osascript &> /dev/null; then
        # macOS
        osascript -e "tell application \"Terminal\" to do script \"echo '\\033[0;36mOmniRoute Server\\033[0m'; echo 'Press Ctrl+C to stop'; echo ''; omniroute\""
    else
        color_print $YELLOW "No suitable terminal emulator found. Starting in background..."
        omniroute &
        OMNIROUTE_PID=$!
        echo "OmniRoute started with PID: $OMNIROUTE_PID"
    fi

    color_print $GREEN "OmniRoute started in separate window."

    # Wait for OmniRoute to become healthy
    MAX_ATTEMPTS=30
    ATTEMPT=0

    color_print $CYAN "Waiting for OmniRoute to become healthy..."

    while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
        ((ATTEMPT++))
        sleep 1

        if test_omniroute_health; then
            color_print $GREEN "OmniRoute is now healthy (attempt $ATTEMPT/$MAX_ATTEMPTS)"
            break
        else
            echo "Waiting... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        fi
    done

    # Final check
    if ! test_omniroute_health; then
        color_print $RED "ERROR: OmniRoute failed to start after $MAX_ATTEMPTS seconds."
        color_print $YELLOW "Check the OmniRoute window for error messages."
        exit 1
    fi
fi

# ============================================
# Step 5: Set Environment Variables
# ============================================
color_print $CYAN "\nSetting up environment..."

export ANTHROPIC_AUTH_TOKEN="$AUTH_TOKEN"
export ANTHROPIC_BASE_URL="http://localhost:$OMNIROUTE_PORT/v1"
export ANTHROPIC_MODEL="$SELECTED_MODEL"
export ANTHROPIC_deepseek_MODEL="deepseek-v4-flash"
export ENABLE_CC_COMPATIBLE_PROVIDER="true"
export CLAUDE_CODE_SKIP_UPDATE_CHECK="1"
export CLAUDE_CODE_DISABLE_ARTIFACT="1"

color_print $GREEN "Environment configured:"
echo "  ANTHROPIC_MODEL = $SELECTED_MODEL"
echo "  ANTHROPIC_BASE_URL = $ANTHROPIC_BASE_URL"

# ============================================
# Step 6: Launch Claude
# ============================================
color_print $CYAN "\nStarting Claude Code via OmniRoute..."
echo "Command: $COMMAND"
color_print $NC "\n========================================"
echo ""

# Execute the Claude command
eval "$COMMAND"
EXIT_CODE=$?

# ============================================
# Cleanup Instructions
# ============================================
color_print $NC "\n========================================"
color_print $CYAN "Session ended."
color_print $YELLOW "Omniroute is still running in the separate window."
color_print $YELLOW "Close that window when you're done, or leave it for next time."

exit $EXIT_CODE
