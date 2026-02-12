@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

:: Logging disabled

title Blackwell 5000 Installer (Linear Mode)
echo Installer is running from:
echo %~f0
echo.
echo.
echo.
echo.

:: --- STEP 1: TOOLS CHECK ---
echo.
echo [1/5] Checking Git...
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] Git is not installed!
    echo Download: https://git-scm.com/download/win
    pause
    exit
)

echo [2/5] Checking Python 3.11...
py -3.11 --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Installing Python 3.11...
    curl -L -o py311.exe https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    py311.exe /quiet PrependPath=1 Include_test=0
    del py311.exe
)

:: --- STEP 2: ENVIRONMENT ---
echo.
echo [3/5] Setting up Venv...
if not exist "venv" (
    py -3.11 -m venv venv
)
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo [ERROR] Venv failed.
    pause
    exit
)

:: --- STEP 3: INSTALLING CORE ---
echo.
echo [4/5] Cloning ComfyUI ^& Installing Requirements...
if not exist "comfy-ui" (
    echo Cloning ComfyUI into comfy-ui folder...
    git clone https://github.com/Comfy-Org/ComfyUI.git comfy-ui
    if !errorlevel! neq 0 (
        echo [CRITICAL ERROR] Git clone failed! Check internet connection.
        pause
        exit
    )
)

echo Installing ComfyUI Requirements...
if not exist "comfy-ui\requirements.txt" (
    echo [CRITICAL ERROR] requirements.txt not found in comfy-ui!
    pause
    exit
)

cd comfy-ui
pip install -r requirements.txt
cd ..

echo.
echo [4.2/5] Upgrading to PyTorch Nightly (Blackwell Optimized)...
:: Forced upgrade to prevent downgrade by requirements.txt
pip install --pre --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128

echo.
echo [4.3/5] Installing Triton (Windows)...
pip install triton-windows
echo.
echo [4.4/5] Installing SageAttention (Local Backup)...
if not exist "utils" mkdir "utils"
set "SAGE_WHEEL=utils\sageattention-2.2.0+cu128.torch2.11-cp311-cp311-win_amd64.whl"

:: Check for corrupt file (less than 1KB)
if exist "%SAGE_WHEEL%" (
    for %%I in ("%SAGE_WHEEL%") do if %%~zI LSS 1024 (
        echo [WARNING] Detected corrupt wheel file. Deleting...
        del "%SAGE_WHEEL%"
    )
)

if not exist "%SAGE_WHEEL%" (
    echo Downloading SageAttention wheel...
    curl -L -o "%SAGE_WHEEL%" "https://github.com/mobcat40/sageattention-blackwell/raw/main/sageattention-2.2.0+cu128.torch2.11-cp311-cp311-win_amd64.whl"
    if !errorlevel! neq 0 (
        echo [CRITICAL ERROR] Download failed!
        if exist "%SAGE_WHEEL%" del "%SAGE_WHEEL%"
        pause
        exit
    )
)

if exist "%SAGE_WHEEL%" (
    echo Installing from local wheel...
    pip install "%SAGE_WHEEL%"
) else (
    echo [CRITICAL ERROR] Wheel file missing!
    pause
    exit
)

echo.
echo [4.5/5] Installing ComfyUI-Manager...
if not exist "comfy-ui\custom_nodes\ComfyUI-Manager" (
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git comfy-ui\custom_nodes\ComfyUI-Manager
)

:: --- STEP 4: GENERATING LAUNCHER ---
echo.
echo [5/5] Creating Matrix Launcher (prove overwrite)...

if not exist "utils" mkdir "utils"
echo Generating utils\banner.py...
> utils\banner.py echo import os
>> utils\banner.py echo import sys
>> utils\banner.py echo if os.name == 'nt': os.system('color')
>> utils\banner.py echo def print_rainbow(text):
>> utils\banner.py echo     colors = [
>> utils\banner.py echo         "\033[91m", "\033[93m", "\033[92m", "\033[96m", "\033[94m", "\033[95m"
>> utils\banner.py echo     ]
>> utils\banner.py echo     reset = "\033[0m"
>> utils\banner.py echo     lines = text.split("\n")
>> utils\banner.py echo     for i, line in enumerate(lines):
>> utils\banner.py echo         if line.strip():
>> utils\banner.py echo             color = colors[i %% len(colors)]
>> utils\banner.py echo             print(f"{color}{line}{reset}")
>> utils\banner.py echo         else:
>> utils\banner.py echo             print(line)
>> utils\banner.py echo art = r"""
>> utils\banner.py echo   ___  _____  __  __  ____  _  _    __  __  ____ 
>> utils\banner.py echo  / __)(  _  )(  \/  )( ___)( \/ )  (  )(  )(_  _)
>> utils\banner.py echo ( (__  )(_)(  )    (  )__)  \  /    )(__)(  _)(_ 
>> utils\banner.py echo  \___)(_____)(_/\/\_)(__)   (__)   (______)(____)
>> utils\banner.py echo """
>> utils\banner.py echo print_rainbow(art)

echo Generating launcher maker...
> maker.py echo from pathlib import Path
>> maker.py echo root = Path(__file__).resolve().parent
>> maker.py echo out = root / "START_COMFY.bat"
>> maker.py echo content = r"""@echo off
>> maker.py echo setlocal EnableExtensions EnableDelayedExpansion
>> maker.py echo cd /d "%%~dp0"
>> maker.py echo title ComfyUI Launcher
>> maker.py echo color 0A
>> maker.py echo cls
>> maker.py echo python utils\banner.py
>> maker.py echo echo.
>> maker.py echo echo Blackwell 5000 (Linear Mode)
>> maker.py echo echo.
>> maker.py echo echo.
>> maker.py echo set "VENV=%%~dp0venv\Scripts\activate.bat"
>> maker.py echo if exist "%%VENV%%" (
>> maker.py echo     echo Activating venv...
>> maker.py echo     call "%%VENV%%"
>> maker.py echo ) else (
>> maker.py echo     echo [ERROR] Venv not found at %%VENV%%
>> maker.py echo     echo Please run setup.bat first.
>> maker.py echo     pause
>> maker.py echo     exit /b
>> maker.py echo )
>> maker.py echo.
>> maker.py echo if exist "%%~dp0comfy-ui\main.py" (
>> maker.py echo     cd /d "%%~dp0comfy-ui"
>> maker.py echo     echo Launching ComfyUI...
>> maker.py echo     python main.py --auto-launch
>> maker.py echo ) else (
>> maker.py echo     echo [ERROR] ComfyUI not found at %%~dp0comfy-ui
>> maker.py echo     pause
>> maker.py echo     exit /b
>> maker.py echo )
>> maker.py echo pause
>> maker.py echo """
>> maker.py echo out.write_text(content.replace("\n", "\r\n"), encoding="utf-8")
>> maker.py echo print("WROTE:", out)

python maker.py
del maker.py

timeout /t 2 >nul
cls
echo.
echo ========================================================
echo                 SETUP COMPLETE!
echo ========================================================
echo.
echo  1. ComfyUI is installed in "comfy-ui".
echo  2. SageAttention is patched and ready.
echo  3. Triton (Windows) is installed.
echo  4. Manager is installed.
echo.
echo  [ACTION] Run "START_COMFY.bat" to launch!
echo.
echo ========================================================
echo.
pause
