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
from ctypes import windll
import psutil
import threading

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

def force_click(x, y):
    x, y = int(x), int(y)
    windll.user32.SetCursorPos(x, y)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, 0, 0)
    time.sleep(0.01)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, 0, 0)

class ImageDetector:
    def __init__(self, template_path, region=None):
        # Load and resize template to a reasonable size if it's too large
        self.template = cv2.imread(template_path)
        if self.template is None:
            raise ValueError(f"Could not load template image: {template_path}")
        
        # Resize template if it's too large (helps with performance)
        max_template_size = 100
        h, w = self.template.shape[:2]
        if h > max_template_size or w > max_template_size:
            scale = max_template_size / max(h, w)
            self.template = cv2.resize(self.template, None, fx=scale, fy=scale)
        
        self.region = region
        self.click_count = 0
        self.last_screenshot = None
        self.last_screenshot_time = 0
        self.screenshot_interval = 0.05  # 50ms minimum between screenshots
        
    def capture_screen(self):
        current_time = time.time()
        
        # Only capture new screenshot if enough time has passed
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
            
        # Use TM_CCOEFF_NORMED method which is generally faster
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
    # Initialize resource monitor
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
                
                # Update status every second
                current_time = time.time()
                if current_time - last_status_update >= 1:
                    print('\r' + ' ' * 100, end='\r')  # Clear the line
                    print(f"\rScans: {scan_count}, Clicks: {detector.click_count}, "
                          f"CPU: {monitor.cpu_usage:.1f}%, "
                          f"Memory: {monitor.memory_usage:.1f}MB", end='')
                    last_status_update = current_time
                    scan_count = 0  # Reset scan count every second
                
                if result:
                    x, y, confidence = result
                    detector.click_count += 1
                    print('\n', end='')  # Move to new line
                    log_message(f"Image found! Clicking at ({x}, {y}) with confidence: {confidence:.3f}")
                    force_click(x, y)
                
                # Small sleep to prevent excessive CPU usage
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