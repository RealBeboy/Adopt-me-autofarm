import cv2
import numpy as np
import keyboard
import time
from PIL import ImageGrab
from datetime import datetime
import ctypes
import win32gui
import win32con
import os
import win32api
from ctypes import windll, Structure, c_long, byref
import psutil
import threading
import random

class MouseInput(ctypes.Structure):
    _fields_ = [
        ("dx", ctypes.c_long),
        ("dy", ctypes.c_long),
        ("mouseData", ctypes.c_ulong),
        ("dwFlags", ctypes.c_ulong),
        ("time", ctypes.c_ulong),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong))
    ]

class Input_I(ctypes.Union):
    _fields_ = [("mi", MouseInput)]

class Input(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_ulong),
        ("ii", Input_I)
    ]

class POINT(Structure):
    _fields_ = [("x", c_long), ("y", c_long)]

def get_cursor_position():
    pt = POINT()
    windll.user32.GetCursorPos(byref(pt))
    return (pt.x, pt.y)

def set_cursor_position(x, y):
    win32api.SetCursorPos((x, y))

def smooth_move(x_dest, y_dest, duration=0.3):
    """Move mouse smoothly to destination"""
    start_x, start_y = get_cursor_position()
    steps = 20
    
    sleep_time = duration / steps
    x_step = (x_dest - start_x) / steps
    y_step = (y_dest - start_y) / steps
    
    for i in range(steps):
        random_offset = random.uniform(-2, 2)
        new_x = int(start_x + (x_step * i) + random_offset)
        new_y = int(start_y + (y_step * i) + random_offset)
        set_cursor_position(new_x, new_y)
        time.sleep(sleep_time)
    
    set_cursor_position(x_dest, y_dest)

def send_input_click(x, y):
    """Send mouse click using SendInput at specific coordinates"""
    extra = ctypes.c_ulong(0)
    ii_ = Input_I()
    
    # Mouse down
    ii_.mi = MouseInput(0, 0, 0, 0x0002, 0, ctypes.pointer(extra))  # MOUSEEVENTF_LEFTDOWN
    x_down = Input(0, ii_)
    ctypes.windll.user32.SendInput(1, ctypes.pointer(x_down), ctypes.sizeof(x_down))
    
    time.sleep(random.uniform(0.05, 0.1))
    
    # Mouse up
    ii_.mi = MouseInput(0, 0, 0, 0x0004, 0, ctypes.pointer(extra))  # MOUSEEVENTF_LEFTUP
    x_up = Input(0, ii_)
    ctypes.windll.user32.SendInput(1, ctypes.pointer(x_up), ctypes.sizeof(x_up))

def direct_click(x, y):
    """Perform direct mouse click at specific coordinates"""
    # Convert coordinates to screen coordinates
    x = int(x)
    y = int(y)
    
    # Calculate absolute position
    normalized_x = int(x * 65535 / win32api.GetSystemMetrics(0))
    normalized_y = int(y * 65535 / win32api.GetSystemMetrics(1))
    
    # Move and click
    win32api.mouse_event(win32con.MOUSEEVENTF_ABSOLUTE | win32con.MOUSEEVENTF_MOVE, normalized_x, normalized_y, 0, 0)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, normalized_x, normalized_y, 0, 0)
    time.sleep(random.uniform(0.05, 0.1))
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, normalized_x, normalized_y, 0, 0)

def natural_click(x, y):
    """Perform a more natural and reliable click with multiple click methods"""
    # Move to position with slight randomness
    target_x = x + random.randint(-2, 2)
    target_y = y + random.randint(-2, 2)
    
    # Smooth movement to position
    smooth_move(target_x, target_y)
    
    # Small random delay before clicking
    time.sleep(random.uniform(0.05, 0.1))
    
    # Try multiple click methods for reliability
    try:
        # Method 1: SendInput click
        send_input_click(target_x, target_y)
        
        # Small delay between methods
        time.sleep(random.uniform(0.02, 0.05))
        
        # Method 2: Direct click as backup
        direct_click(target_x, target_y)
        
    except Exception as e:
        print(f"Click error: {e}")
        # Fallback to direct click if SendInput fails
        direct_click(target_x, target_y)
    
    # Small movement after click
    post_x = target_x + random.randint(-3, 3)
    post_y = target_y + random.randint(-3, 3)
    smooth_move(post_x, post_y, duration=0.1)

class ResourceMonitor:
    def __init__(self):
        self.process = psutil.Process()
        self.monitoring = False
        self.cpu_usage = 0
        self.memory_usage = 0
    
    def start_monitoring(self):
        self.monitoring = True
        threading.Thread(target=self._monitor_resources, daemon=True).start()
    
    def _monitor_resources(self):
        while self.monitoring:
            self.cpu_usage = self.process.cpu_percent()
            self.memory_usage = self.process.memory_info().rss / 1024 / 1024  # MB
            time.sleep(1)
    
    def stop_monitoring(self):
        self.monitoring = False

def make_console_always_on_top():
    hwnd = win32gui.GetForegroundWindow()
    win32gui.SetWindowPos(hwnd, win32con.HWND_TOPMOST, 0, 0, 0, 0, 
                         win32con.SWP_NOMOVE | win32con.SWP_NOSIZE)

class ImageDetector:
    def __init__(self, template_path, region=None):
        self.template = cv2.imread(template_path)
        if self.template is None:
            raise ValueError(f"Could not load template image: {template_path}")
        
        max_template_size = 100
        h, w = self.template.shape[:2]
        if h > max_template_size or w > max_template_size:
            scale = max_template_size / max(h, w)
            self.template = cv2.resize(self.template, None, fx=scale, fy=scale)
        
        self.region = region
        self.click_count = 0
        self.last_screenshot = None
        self.last_screenshot_time = 0
        self.screenshot_interval = 0.05
        
    def capture_screen(self):
        current_time = time.time()
        
        if (current_time - self.last_screenshot_time) >= self.screenshot_interval:
            if self.region:
                screenshot = ImageGrab.grab(bbox=self.region)
            else:
                screenshot = ImageGrab.grab()
            self.last_screenshot = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)
            self.last_screenshot_time = current_time
            
        return self.last_screenshot
    
    def find_image(self, confidence=0.7):
        screen = self.capture_screen()
        if screen is None:
            return None
            
        result = cv2.matchTemplate(screen, self.template, cv2.TM_CCOEFF_NORMED)
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
        
        if max_val >= confidence:
            w, h = self.template.shape[1], self.template.shape[0]
            x = max_loc[0] + w//2
            y = max_loc[1] + h//2
            
            if self.region:
                x += self.region[0]
                y += self.region[1]
                
            return (x, y, max_val)
        return None

def select_region():
    print("Press SPACE to start region selection...")
    keyboard.wait('space')
    print("Move your mouse to the top-left corner and press SPACE...")
    keyboard.wait('space')
    start_x, start_y = win32api.GetCursorPos()
    print("Move your mouse to the bottom-right corner and press SPACE...")
    keyboard.wait('space')
    end_x, end_y = win32api.GetCursorPos()
    
    return (
        min(start_x, end_x),
        min(start_y, end_y),
        max(start_x, end_x),
        max(start_y, end_y)
    )

def log_message(message):
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[{timestamp}] {message}")

def clear_console():
    os.system('cls' if os.name == 'nt' else 'clear')

def main():
    monitor = ResourceMonitor()
    monitor.start_monitoring()
    
    make_console_always_on_top()
    clear_console()
    
    print("\n=== Image Detector Console Version ===")
    print("Instructions:")
    print("1. Press SPACE when prompted to select the region to monitor")
    print("2. Press F8 to stop the script")
    print("3. Make sure 'no_button.png' is in the same folder")
    print("\nStarting in 3 seconds...")
    time.sleep(3)
    
    try:
        log_message("Select the region to monitor...")
        region = select_region()
        
        if not region:
            log_message("Error: No region selected!")
            return
        
        clear_console()
        log_message(f"Region selected: {region}")
        detector = ImageDetector('no_button.png', region)
        
        log_message("Monitoring started. Press F8 to stop.")
        
        scan_count = 0
        last_status_update = time.time()
        
        while not keyboard.is_pressed('f8'):
            try:
                scan_count += 1
                result = detector.find_image()
                
                current_time = time.time()
                if current_time - last_status_update >= 1:
                    print('\r' + ' ' * 100, end='\r')
                    print(f"\rScans: {scan_count}, Clicks: {detector.click_count}, "
                          f"CPU: {monitor.cpu_usage:.1f}%, "
                          f"Memory: {monitor.memory_usage:.1f}MB", end='')
                    last_status_update = current_time
                    scan_count = 0
                
                if result:
                    x, y, confidence = result
                    detector.click_count += 1
                    print('\n', end='')
                    log_message(f"Image found! Clicking at ({x}, {y}) with confidence: {confidence:.3f}")
                    natural_click(x, y)
                
                time.sleep(0.01)
                
            except Exception as e:
                log_message(f"Error: {e}")
                break
                
    except KeyboardInterrupt:
        log_message("Script stopped by user")
    except Exception as e:
        log_message(f"Error: {str(e)}")
    
    monitor.stop_monitoring()
    log_message("Script ended")
    print("\nPress Enter to exit...")
    input()

if __name__ == "__main__":
    main()