#!/usr/bin/env python3
import evdev
from evdev import InputDevice, ecodes
import time
import threading
from pynput.mouse import Button, Controller

mouse = Controller()

def find_goodix_device():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for dev in devices:
        if "goodix" in dev.name.lower() or "touchscreen" in dev.name.lower():
            return dev
    return None

device = find_goodix_device()
if not device:
    print("Touchscreen aygiti bulunamadi!")
    exit(1)

print(f"Dinlenen aygit: {device.name} ({device.path})")

touch_down = False
touch_time = 0
right_click_triggered = False
timer_thread = None

HOLD_TIME = 0.55  # 0.55 saniye basılı tutunca sağ tık

def trigger_right_click():
    global right_click_triggered
    if touch_down:
        right_click_triggered = True
        mouse.press(Button.right)
        mouse.release(Button.right)

for event in device.read_loop():
    # Ekrana dokunma veya parmağı kaldırma (BTN_TOUCH)
    if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
        if event.value == 1:  # Dokunuldu
            touch_down = True
            right_click_triggered = False
            touch_time = time.time()
            timer_thread = threading.Timer(HOLD_TIME, trigger_right_click)
            timer_thread.start()
        elif event.value == 0:  # Parmak kaldırıldı
            touch_down = False
            if timer_thread and timer_thread.is_alive():
                timer_thread.cancel()
