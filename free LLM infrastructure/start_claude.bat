@echo off
setlocal EnableDelayedExpansion

REM Prompt user for Claude arguments
set /p CLAUDE_ARGS="Enter Claude command (e.g., 'claude' or 'claude make team work'): "
set /p CLAUDE_MODEL="Enter Claude model to use from OmniRoute (e.g., 'nvidia/nvidia/nemotron-3-super-120b-a12b' or 'nvidia/nvidia/nemotron-3-ultra-550b-a55b'): "

REM Set environment variables
set "ANTHROPIC_AUTH_TOKEN=sk-1cb428cb6cc3464d-9d19ff-843f936b"
set "ANTHROPIC_BASE_URL=http://localhost:20128/v1"
set "ANTHROPIC_MODEL=%CLAUDE_MODEL%"
set "CLAUDE_CODE_SKIP_UPDATE_CHECK=1"

REM Check if omniroute is already running by checking the port
echo Checking omniroute status...
netstat -ano | findstr ":20128" | findstr "LISTENING" >nul 2>&1

if errorlevel 1 (
    echo Starting omniroute...
    start /B omniroute

    REM Wait for omniroute to start and verify it's healthy
    set MAX_ATTEMPTS=20
    set ATTEMPT=0

    :check_omniroute
    set /a ATTEMPT+=1
    if !ATTEMPT! GTR !MAX_ATTEMPTS! (
        echo ERROR: omniroute failed to start after !MAX_ATTEMPTS! attempts
        pause
        exit /b 1
    )

    timeout /t 1 /nobreak >nul

    REM Check if omniroute is listening on port 20128
    netstat -ano | findstr ":20128" | findstr "LISTENING" >nul 2>&1
    if errorlevel 1 (
        echo Waiting for omniroute to start... (attempt !ATTEMPT!/!MAX_ATTEMPTS!)
        goto check_omniroute
    )

    echo omniroute started successfully
) else (
    echo omniroute is already running
)

REM Start Claude with user-provided arguments
echo.
echo Starting Claude Code via OmniRoute...
echo Command: %CLAUDE_ARGS%
echo.

%CLAUDE_ARGS%

endlocal
