#!/usr/bin/env python3
"""
Universal Touchscreen Helper (Auto-Landscape Aware):
- Ekranın en/boy oranını (Landscape / Portrait) otomatik algılar.
- İki parmak dikey sürükleme -> SADECE Dikey Kaydırma (Scroll Y)
- İki parmak yatay sürükleme -> SADECE Yatay Kaydırma (Scroll X)
- Sabit basılı tutma -> Sağ Tık (Button.right)
"""

import evdev
from evdev import InputDevice, ecodes
import math
import subprocess
import re
import threading
from pynput.mouse import Button, Controller

mouse = Controller()

def find_touchscreen_device():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for dev in devices:
        name = dev.name.lower()
        if "goodix" in name or "touchscreen" in name or "raspberrypi-ts" in name:
            return dev
    return None

device = find_touchscreen_device()
if not device:
    print("[HATA] Uyumlu dokunmatik ekran aygiti bulunamadi!")
    exit(1)

print(f"[BILGI] Dinlenen aygit: {device.name} ({device.path})")

def is_screen_landscape():
    """Ekranın yatay (Landscape: Genişlik > Yükseklik) olup olmadığını tespit eder."""
    try:
        out = subprocess.check_output(["xrandr", "--current"], text=True)
        # Örn: 'current 1280 x 720' veya 'DSI-1 connected primary 1280x720+0+0'
        match = re.search(r"current\s+(\d+)\s+x\s+(\d+)", out)
        if match:
            w, h = int(match.group(1)), int(match.group(2))
            return w >= h
        matches = re.findall(r"connected.*?(\d+)x(\d+)\+", out)
        if matches:
            w, h = int(matches[0][0]), int(matches[0][1])
            return w >= h
    except Exception:
        pass
    # Varsayılan olarak Touch Display 2 yatay kullanılıyor kabul edilir
    return True

IS_LANDSCAPE = is_screen_landscape()
print(f"[BILGI] Ekran Modu: {'Yatay (Landscape)' if IS_LANDSCAPE else 'Dikey (Portrait)'}")

slots = {}
current_slot = 0
touch_down = False
right_click_triggered = False
timer_thread = None

# Ayarlar
HOLD_TIME = 0.55          # Sağ tık bekleme süresi (sn)
MOVE_THRESHOLD = 25       # Sürüklemede sağ tıkı iptal etme mesafesi (piksel)
SCROLL_SENSITIVITY = 16   # Kaydırma hassasiyeti (düşük = daha akıcı)

initial_x = None
initial_y = None
last_scroll_x = None
last_scroll_y = None

def trigger_right_click():
    global right_click_triggered
    active_fingers = sum(1 for s in slots.values() if s.get('active', False))
    if touch_down and active_fingers == 1:
        right_click_triggered = True
        mouse.press(Button.right)
        mouse.release(Button.right)

def cancel_timer():
    global timer_thread
    if timer_thread and timer_thread.is_alive():
        timer_thread.cancel()

try:
    for event in device.read_loop():
        # Multitouch Takibi
        if event.type == ecodes.EV_ABS:
            if event.code == ecodes.ABS_MT_SLOT:
                current_slot = event.value
                if current_slot not in slots:
                    slots[current_slot] = {'x': 0, 'y': 0, 'active': False}

            elif event.code == ecodes.ABS_MT_TRACKING_ID:
                if current_slot not in slots:
                    slots[current_slot] = {'x': 0, 'y': 0, 'active': False}
                if event.value >= 0:
                    slots[current_slot]['active'] = True
                else:
                    slots[current_slot]['active'] = False
                    if current_slot == 0:
                        last_scroll_x = None
                        last_scroll_y = None

            elif event.code == ecodes.ABS_MT_POSITION_X:
                if current_slot not in slots:
                    slots[current_slot] = {'x': 0, 'y': 0, 'active': False}
                slots[current_slot]['x'] = event.value

            elif event.code == ecodes.ABS_MT_POSITION_Y:
                if current_slot not in slots:
                    slots[current_slot] = {'x': 0, 'y': 0, 'active': False}
                slots[current_slot]['y'] = event.value

        # Dokunma ve Bırakma Olayları
        elif event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
            if event.value == 1:
                touch_down = True
                right_click_triggered = False
                initial_x = None
                initial_y = None
                cancel_timer()
                timer_thread = threading.Timer(HOLD_TIME, trigger_right_click)
                timer_thread.start()
            elif event.value == 0:
                touch_down = False
                cancel_timer()
                initial_x = None
                initial_y = None
                last_scroll_x = None
                last_scroll_y = None
                slots.clear()

        # Eksen Hesaplama ve Kaydırma
        elif event.type == ecodes.EV_SYN and event.code == ecodes.SYN_REPORT:
            active_slots = [s for s in slots.values() if s.get('active', False)]
            num_fingers = len(active_slots)

            # 1. TEK PARMAK SEÇİM (Sürüklemede Sağ Tıkı İptal Et)
            if num_fingers == 1 and touch_down and not right_click_triggered:
                curr_x = active_slots[0]['x']
                curr_y = active_slots[0]['y']

                if initial_x is None:
                    initial_x = curr_x
                    initial_y = curr_y
                else:
                    distance = math.hypot(curr_x - initial_x, curr_y - initial_y)
                    if distance > MOVE_THRESHOLD:
                        cancel_timer()

            # 2. İKİ PARMAKLA KAYDIRMA
            elif num_fingers >= 2:
                cancel_timer()

                avg_raw_x = (active_slots[0]['x'] + active_slots[1]['x']) / 2
                avg_raw_y = (active_slots[0]['y'] + active_slots[1]['y']) / 2

                if last_scroll_x is not None and last_scroll_y is not None:
                    raw_dx = avg_raw_x - last_scroll_x
                    raw_dy = avg_raw_y - last_scroll_y

                    # Ekran yönü yatay (landscape) ise:
                    # Sensörün fiziksel Y ekseni = Ekranın Yatayı (X)
                    # Sensörün fiziksel X ekseni = Ekranın Dikeyi (Y)
                    if IS_LANDSCAPE:
                        screen_dx = raw_dy
                        screen_dy = raw_dx
                    else:
                        screen_dx = raw_dx
                        screen_dy = raw_dy

                    # Dikey Hareket (Aşağı/Yukarı):
                    # Parmağı aşağı çekince sayfa aşağı iner, yukarı itince sayfa yukarı çıkar
                    if abs(screen_dy) >= SCROLL_SENSITIVITY:
                        v_steps = int(screen_dy / SCROLL_SENSITIVITY)
                        mouse.scroll(0, -v_steps)
                        last_scroll_x = avg_raw_x

                    # Yatay Hareket (Sağa/Sola):
                    # Parmağı sağa çekince sağa, sola çekince sola kaydır
                    if abs(screen_dx) >= SCROLL_SENSITIVITY:
                        h_steps = int(screen_dx / SCROLL_SENSITIVITY)
                        mouse.scroll(-h_steps, 0)
                        last_scroll_y = avg_raw_y
                else:
                    last_scroll_x = avg_raw_x
                    last_scroll_y = avg_raw_y

except KeyboardInterrupt:
    print("\nServis durduruldu.")
