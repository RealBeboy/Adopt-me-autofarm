@echo off
echo Installing required Python libraries...

python -m pip install --upgrade pip

echo Installing OpenCV...
pip install opencv-python

echo Installing NumPy...
pip install numpy

echo Installing keyboard...
pip install keyboard

echo Installing Pillow...
pip install Pillow

echo Installing pywin32...
pip install pywin32

echo Installing psutil...
pip install psutil

echo Checking installations...
python -c "import cv2; import numpy as np; import keyboard; from PIL import ImageGrab; import win32gui; import win32con; import win32api; import psutil" 

if %ERRORLEVEL% EQU 0 (
    echo All libraries installed successfully!
) else (
    echo Some installations may have failed. Please check the error messages above.
)

pause
