#!/usr/bin/env python3
import glob
import os
import subprocess
import tkinter as tk

# Raspberry Pi ekran arka ışık dosyasını bul
backlight_files = glob.glob("/sys/class/backlight/*/brightness")
max_backlight_files = glob.glob("/sys/class/backlight/*/max_brightness")

BRIGHTNESS_FILE = backlight_files[0] if backlight_files else None
MAX_BRIGHTNESS = 255

if max_backlight_files:
  try:
    with open(max_backlight_files[0], "r") as f:
      MAX_BRIGHTNESS = int(f.read().strip())
  except Exception:
    MAX_BRIGHTNESS = 255

STEP = max(1, int(MAX_BRIGHTNESS * 0.1))


def get_brightness():
  if not BRIGHTNESS_FILE:
    return MAX_BRIGHTNESS
  try:
    with open(BRIGHTNESS_FILE, "r") as f:
      return int(f.read().strip())
  except Exception:
    return MAX_BRIGHTNESS


def set_brightness(val):
  val = max(1, min(MAX_BRIGHTNESS, val))
  if BRIGHTNESS_FILE:
    try:
      with open(BRIGHTNESS_FILE, "w") as f:
        f.write(str(val))
    except Exception:
      os.system(f"brightnessctl set {val} 2>/dev/null")
  percent = int((val / MAX_BRIGHTNESS) * 100)
  lbl_info.config(text=f"%{percent}")


def bright_down():
  set_brightness(get_brightness() - STEP)


def bright_up():
  set_brightness(get_brightness() + STEP)


def lock_sleep():
  subprocess.Popen(["/usr/local/bin/lock-sleep.sh"])


# Tkinter Penceresi
root = tk.Tk()
root.title("Quick Panel")
root.geometry("320x65+40+40")
root.attributes("-topmost", True)  # Daima üstte kalsın
root.configure(bg="#1e1e1e")

# Başlık Çubuğu / Kontrol Paneli Alanı
frame = tk.Frame(root, bg="#1e1e1e")
frame.pack(expand=True, fill="both", padx=6, pady=6)

# Parlaklık Azalt (-)
btn_down = tk.Button(
    frame,
    text="—",
    font=("Arial", 14, "bold"),
    bg="#333333",
    fg="white",
    width=3,
    command=bright_down,
)
btn_down.pack(side="left", padx=3, fill="both")

# Yüzde Bilgisi
initial_pct = int((get_brightness() / MAX_BRIGHTNESS) * 100)
lbl_info = tk.Label(
    frame,
    text=f"%{initial_pct}",
    font=("Arial", 11, "bold"),
    bg="#1e1e1e",
    fg="#00e5ff",
    width=4,
)
lbl_info.pack(side="left", padx=2)

# Parlaklık Artır (+)
btn_up = tk.Button(
    frame,
    text="+",
    font=("Arial", 14, "bold"),
    bg="#333333",
    fg="white",
    width=3,
    command=bright_up,
)
btn_up.pack(side="left", padx=3, fill="both")

# Kapatma Butonu (✕) - En Sağda
btn_close = tk.Button(
    frame,
    text="✕",
    font=("Arial", 12, "bold"),
    bg="#444444",
    fg="#ff5555",
    width=2,
    command=root.destroy,
)
btn_close.pack(side="right", padx=3, fill="both")

# Kilit / Uyku Butonu (🔒) - Kapatmanın Yanında
btn_lock = tk.Button(
    frame,
    text="🔒",
    font=("Arial", 12),
    bg="#b71c1c",
    fg="white",
    width=3,
    command=lock_sleep,
)
btn_lock.pack(side="right", padx=3, fill="both")

root.mainloop()
