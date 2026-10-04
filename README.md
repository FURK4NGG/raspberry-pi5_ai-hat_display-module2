## 👀 raspberry-pi5_ai-hat_display-module2 Overview  
This setup provides a complete system configuration for Raspberry Pi 5 with AI HAT and touchscreen module, featuring touch right-click emulation, a customized persistent virtual keyboard, a quick brightness/sleep control panel, and stable PCIe AI accelerator startup optimizations

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_1.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_2.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_3.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_4.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_5.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_6.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_7.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_8.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_9.webp)

![raspberry-pi5_ai-hat_display-module2 Demo Image](https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2/blob/main/%7B%7D/raspberry-pi5_ai-hat_display-module2_10.webp)

## 📦 Setup  
Directory Structures  
├── /usr/local/bin/touch_right_click.py  
├── ~/.config/autostart/touch-rightclick.desktop  
├  
├── /boot/firmware/config.txt  
├── /boot/firmware/cmdline.txt  
├── /etc/modprobe.d/hailo-blacklist.conf  
├── /etc/systemd/system/hailo-delayed-load.service  
├  
├── /usr/local/bin/quick-panel.py  
├  
├── /usr/local/bin/lock-sleep.sh  
├  
├── /usr/share/matchbox-keyboard/keyboard.xml  
└── ~/.config/openbox/lxde-pi-rc.xml  



```
sudo apt update  
sudo apt install -y python3-evdev python3-pynput python3-tk matchbox-keyboard xdotool xkbset light-locker
  
sudo usermod -aG input $USER  

sudo chmod 666 /sys/class/backlight/*/brightness 2>/dev/null || true

sudo chmod +x /usr/local/bin/touch_right_click.py
sudo chmod +x /usr/local/bin/quick-panel.py
sudo chmod +x /usr/local/bin/lock-sleep.sh
```
<br>

Create Brightness Panel Desktop Shortcut  
```
cat << 'EOF' > ~/Desktop/quick-panel.desktop
[Desktop Entry]
Type=Application
Name=Quick Panel
Comment=Brightness and Screen Lock Control
Exec=python3 /usr/local/bin/quick-panel.py
Icon=preferences-system
Terminal=false
Categories=Utility;Settings;
EOF

chmod +x ~/Desktop/quick-panel.desktop
# Also add to system menu:
sudo cp ~/Desktop/quick-panel.desktop /usr/share/applications/
```

auto start  
```
mkdir -p ~/.config/autostart
```

## Make persistent on every desktop launch:  
```
# Sticky Keys & Timeout Prevention
grep -qxF "xkbset accessx sticky -twokey -latchto" ~/.xsessionrc 2>/dev/null || echo "xkbset accessx sticky -twokey -latchto" >> ~/.xsessionrc
grep -qxF "xkbset exp =sticky" ~/.xsessionrc 2>/dev/null || echo "xkbset exp =sticky" >> ~/.xsessionrc

# Continuous Key Auto-Repeat
grep -qxF "xset r rate 250 35" ~/.xsessionrc 2>/dev/null || echo "xset r rate 250 35" >> ~/.xsessionrc

# Autostart Quick Panel
grep -qxF "python3 /usr/local/bin/quick-panel.py &" ~/.xsessionrc 2>/dev/null || echo "python3 /usr/local/bin/quick-panel.py &" >> ~/.xsessionrc
```

```
sudo reboot
```
<br>

## 🎉 Run  
Run Touch Movements  
```
python3 /usr/local/bin/touch_right_click.py &
```
<br>

Run Keyboard  
```
killall -9 matchbox-keyboard 2>/dev/null  
matchbox-keyboard &  
```
<br>

Run light-locker  
```
light-locker &
```
<br>

Run Brightness Panel  
```
python3 /usr/local/bin/quick-panel.py &
```

Touch Movements Control  
```
pgrep -af touch_right_click  
```

Apply Openbox Rules  
```
openbox --reconfigure
```


### 📖 KOReader

A versatile, gesture-driven document and e-book reader optimized for touchscreens and e-ink displays. It offers seamless rendering for EPUB, PDF, DJVU, CBZ, and FB2 formats, featuring advanced text reflow for PDFs, full typographic customization, and a lightweight footprint ideal for low-power ARM devices.
<details>
<summary>KOReader</summary>

#### Installation & Setup

```bash
# 1. Fetch the latest ARM64 .deb release URL and download it
URL=$(curl -s [https://api.github.com/repos/koreader/koreader/releases/latest](https://api.github.com/repos/koreader/koreader/releases/latest) | grep "browser_download_url.*arm64.*\.deb" | cut -d '"' -f 4 | head -n 1)
wget -O koreader.deb "$URL"

# 2. Install the package
sudo dpkg -i koreader.deb

# 3. Resolve and install missing dependencies
sudo apt install -f -y

# 4. Clean up the downloaded installer
rm -f koreader.deb



cat << 'EOF' > ~/Desktop/koreader.desktop
[Desktop Entry]
Type=Application
Name=KOReader
Comment=E-Book Reader
Exec=koreader -w 800x600
Icon=accessories-dictionary
Terminal=false
Categories=Office;Viewer;
EOF
```

Run  
```
koreader &
```
</details>


### 📷 RPiCamGUI

Lightweight touch-friendly graphical user interface designed for Raspberry Pi camera modules (such as Camera Module 3 / IMX708). Provides real-time preview, digital zoom controls, and fast parameter tuning directly on the display.

<details>
<summary>Installation & Setup</summary>

#### 1. System Dependencies & Environment Setup
Raspberry Pi OS (Bookworm) uses PEP 668 (`externally-managed-environment`), so all GUI and runtime dependencies must be installed via APT:

```bash
# Update repositories and install native GUI/camera packages
sudo apt update
sudo apt install -y git python3-pygame python3-pip python3-pyqt5 python3-opencv libcamera-tools

cd ~
git clone [https://github.com/Gordon999/RPiCamGUI.git](https://github.com/Gordon999/RPiCamGUI.git)
cd RPiCamGUI
chmod +x RPiCamGUI.py
sudo usermod -aG gpio,video,render $USER


cat << 'EOF' > ~/Desktop/rpicamgui.desktop
[Desktop Entry]
Type=Application
Name=RPi Cam GUI
Comment=Touchscreen Camera Controller
Exec=python3 /home/bob/RPiCamGUI/RPiCamGUI.py
Icon=camera-photo
Terminal=false
Categories=AudioVideo;Video;
EOF

chmod +x ~/Desktop/rpicamgui.desktop
sudo cp ~/Desktop/rpicamgui.desktop /usr/share/applications/
```

Run  
```
python3 /home/bob/RPiCamGUI/RPiCamGUI.py
```
</details>


### 🎮 Steam Client (via Box64 / Box86)

Runs Valve's x86 Steam client on the ARM64 architecture of the Raspberry Pi 5 using dynamic binary translation layers.

<details>
<summary>Installation & Setup</summary>

#### 1. Switch Kernel to 4K Page Size (Mandatory)
The Raspberry Pi 5 kernel defaults to a 16 KB page size (`kernel_2712.img`), causing 32-bit x86/ARM shared libraries (`libm.so.6`) to crash with `ELF load command address/offset not page-aligned`. You must force the standard 4K-paged 64-bit kernel:

```bash
# Enforce standard 4KB page kernel
echo "kernel=kernel8.img" | sudo tee -a /boot/firmware/config.txt
sudo reboot

getconf PAGESIZE

# Enable 32-bit ARM architecture
sudo dpkg --add-architecture armhf

# Add Box64 and Box86 APT sources and GPG keys
sudo wget [https://ryanfortner.github.io/box64-debs/box64.list](https://ryanfortner.github.io/box64-debs/box64.list) -O /etc/apt/sources.list.d/box64.list
sudo wget [https://ryanfortner.github.io/box86-debs/box86.list](https://ryanfortner.github.io/box86-debs/box86.list) -O /etc/apt/sources.list.d/box86.list
wget -qO- [https://ryanfortner.github.io/box64-debs/KEY.gpg](https://ryanfortner.github.io/box64-debs/KEY.gpg) | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg > /dev/null

# Update and install translation layers with graphics runtimes
sudo apt update
sudo apt install -y box64-rpi5arm64 box86-generic-arm:armhf libgl1-mesa-dri:armhf libgl1-mesa-glx:armhf


cd ~
wget [https://raw.githubusercontent.com/ptitSeb/box86/master/install_steam.sh](https://raw.githubusercontent.com/ptitSeb/box86/master/install_steam.sh)
chmod +x install_steam.sh
./install_steam.sh

cat << 'EOF' > ~/Desktop/steam.desktop
[Desktop Entry]
Type=Application
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=/usr/local/bin/steam %U
Icon=steam
Terminal=false
Categories=Game;
EOF

chmod +x ~/Desktop/steam.desktop
```

Run  
```
steam &
```
</details>

# Fast Installation  

```
sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2.git  
cd raspberry-pi5_ai-hat_display-module2  
chmod +x install.sh  
./install.sh  
```
