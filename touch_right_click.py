#!/usr/bin/env python3
"""
Universal Touchscreen Long-Press to Right Click Daemon
Raspberry Pi Touch Display 2 / Goodix Capacitive TouchScreen
"""

import evdev
from evdev import InputDevice, ecodes
import time
import threading
from pynput.mouse import Button, Controller

mouse = Controller()

def find_touchscreen_device():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for dev in devices:
        dev_name = dev.name.lower()
        if "goodix" in dev_name or "touchscreen" in dev_name or "raspberrypi-ts" in dev_name:
            return dev
    return None

device = find_touchscreen_device()
if not device:
    print("[HATA] Uyumlu dokunmatik ekran aygiti bulunamadi!")
    exit(1)

print(f"[BILGI] Dinlenen aygit: {device.name} ({device.path})")

touch_down = False
right_click_triggered = False
timer_thread = None

# Basılı tutma süresi (Saniye)
HOLD_TIME = 0.55

def trigger_right_click():
    global right_click_triggered
    if touch_down:
        right_click_triggered = True
        mouse.press(Button.right)
        mouse.release(Button.right)

try:
    for event in device.read_loop():
        # Ekrana dokunma veya parmağı kaldırma olayı (BTN_TOUCH)
        if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
            if event.value == 1:  # Dokunuldu
                touch_down = True
                right_click_triggered = False
                timer_thread = threading.Timer(HOLD_TIME, trigger_right_click)
                timer_thread.start()
            elif event.value == 0:  # Parmak kaldırıldı
                touch_down = False
                if timer_thread and timer_thread.is_alive():
                    timer_thread.cancel()
except KeyboardInterrupt:
    print("\nServis durduruldu.")
