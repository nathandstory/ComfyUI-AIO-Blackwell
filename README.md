# Blackwell 5000 Series ComfyUI Installer

This is a **one-click setup script** designed to get ComfyUI running perfectly on **NVIDIA Blackwell (RTX 5000 Series)** cards.

## Why use this?
Standard ComfyUI installers might not have the latest kernels or optimizations for the new RTX 5090/5080/etc cards. This script automatically handles everything for you:

1.  **Python 3.11**: Checks for and installs the correct Python version if missing.
2.  **Isolated Environment**: Creates a dedicated virtual environment (`venv`) so it doesn't mess with your system.
3.  **Blackwell Optimization**: Installs **PyTorch Nightly** and a specifically patched **SageAttention** wheel for maximum performance on 5000-series GPUs.
4.  **ComfyUI & Manager**: Downloads the latest ComfyUI and installs the ComfyUI Manager automatically.

## How to use
1.  Download this repository (or just the `setup.bat`).
2.  Double-click **`setup.bat`**.
3.  Wait for the **"SETUP COMPLETE!"** message.
4.  Run the generated **`START_COMFY.bat`** to launch!

## Note on SageAttention
To use the speed improvements, simply add the **"Patch Sage Attention"** node to your ComfyUI workflows. The library is already installed and ready to go.
