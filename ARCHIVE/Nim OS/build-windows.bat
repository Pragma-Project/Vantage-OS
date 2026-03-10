@echo off
REM build-windows.bat - Build nimos kernel using WSL
REM This script helps Windows users build the kernel via WSL

setlocal

echo ========================================
echo nimos Kernel Build Script (Windows)
echo ========================================
echo.

REM Check if WSL is available
where wsl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] WSL not found!
    echo.
    echo Please install WSL first:
    echo   1. Open PowerShell as Administrator
    echo   2. Run: wsl --install
    echo   3. Restart your computer
    echo   4. Run this script again
    echo.
    pause
    exit /b 1
)

echo [OK] WSL detected
echo.

REM Convert Windows path to WSL path
set "WSL_PATH=/mnt/c/Users/azt12/OneDrive/Documents/Code/Nim OS"

echo Build options:
echo   1. Target A (Terminal display)
echo   2. Target B (Logo display)
echo   3. Clean build
echo   4. Convert logo only
echo   5. Setup WSL environment (first-time setup)
echo   6. Open WSL shell in project directory
echo.

set /p CHOICE="Enter choice (1-6): "

if "%CHOICE%"=="1" goto BUILD_A
if "%CHOICE%"=="2" goto BUILD_B
if "%CHOICE%"=="3" goto CLEAN
if "%CHOICE%"=="4" goto LOGO
if "%CHOICE%"=="5" goto SETUP
if "%CHOICE%"=="6" goto SHELL
echo [ERROR] Invalid choice
pause
exit /b 1

:BUILD_A
echo.
echo ========================================
echo Building Target A (Terminal)
echo ========================================
echo.
wsl cd "%WSL_PATH%" ^&^& make target-a
goto DONE

:BUILD_B
echo.
echo ========================================
echo Building Target B (Logo)
echo ========================================
echo.
echo IMPORTANT: Ensure kernel.nim has USE_TARGET_A = false
echo.
pause
wsl cd "%WSL_PATH%" ^&^& make target-b
goto DONE

:CLEAN
echo.
echo ========================================
echo Cleaning build artifacts
echo ========================================
echo.
wsl cd "%WSL_PATH%" ^&^& make clean
goto DONE

:LOGO
echo.
echo ========================================
echo Converting logo.png to logo.bin
echo ========================================
echo.
wsl cd "%WSL_PATH%" ^&^& python3 convert_logo.py
goto DONE

:SETUP
echo.
echo ========================================
echo Setting up WSL build environment
echo ========================================
echo.
echo This will install required packages in WSL...
echo.
pause

wsl sudo apt update
wsl sudo apt install -y build-essential xorriso git python3-pip

echo.
echo Installing Python Pillow...
wsl pip3 install --user Pillow

echo.
echo Installing Nim compiler...
wsl curl https://nim-lang.org/choosenim/init.sh -sSf ^| sh
wsl echo 'export PATH=$HOME/.nimble/bin:$PATH' ^>^> ~/.bashrc

echo.
echo ========================================
echo Setup complete!
echo ========================================
echo.
echo Next steps:
echo   1. Close and reopen WSL (or run: source ~/.bashrc in WSL)
echo   2. Run this script again and choose option 1 or 2
echo.
pause
exit /b 0

:SHELL
echo.
echo ========================================
echo Opening WSL shell
echo ========================================
echo.
echo You will be placed in the project directory.
echo Run 'make target-a' or 'make target-b' to build.
echo Type 'exit' to return to Windows.
echo.
pause
wsl cd "%WSL_PATH%" ^&^& bash
exit /b 0

:DONE
echo.
echo ========================================
echo Build complete!
echo ========================================
echo.
echo Output: build\nimos.iso
echo.
echo Next steps:
echo   1. Create VMware VM (see README.md)
echo   2. Attach build\nimos.iso to VM CD/DVD
echo   3. Power on VM
echo.
pause
