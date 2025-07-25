@echo off
REM Security Event Log Manager - Batch Wrapper
REM This batch file runs the PowerShell script to manage Security event logs

echo Security Event Log Manager for Windows 10 IoT Core
echo ================================================

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with Administrator privileges...
) else (
    echo ERROR: This script must be run as Administrator
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Set PowerShell execution policy temporarily if needed
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force"

REM Run the PowerShell script
echo Starting Security Event Log management...
powershell -File "%~dp0manage-security-eventlogs.ps1"

REM Capture the exit code
set SCRIPT_EXIT_CODE=%ERRORLEVEL%

echo.
if %SCRIPT_EXIT_CODE% == 0 (
    echo Script completed successfully.
) else (
    echo Script completed with errors. Exit code: %SCRIPT_EXIT_CODE%
)

echo.
pause