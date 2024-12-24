
@echo off
echo Installing required Python libraries...

python -m pip install --upgrade pip

pip install opencv-python
pip install numpy
pip install keyboard
pip install Pillow
pip install pywin32
pip install psutil

echo.
echo Installation complete! Press any key to exit...
pause >nul