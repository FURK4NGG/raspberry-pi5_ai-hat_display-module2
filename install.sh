cat << 'EOF' > install.sh
#!/usr/bin/env bash
set -e

echo "=== Starting Full Setup for Raspberry Pi 5 AI-HAT & Touch Display ==="

# ---------------------------------------------------------
# 1. 4K Page Size Kernel Configuration (Required for Box86/Steam)
# ---------------------------------------------------------
echo "[1/7] Checking kernel page size..."
CONFIG_TXT="/boot/firmware/config.txt"
if [ -f "$CONFIG_TXT" ]; then
    if ! grep -q "^kernel=kernel8.img" "$CONFIG_TXT"; then
        echo ">> Appending 4K kernel (kernel=kernel8.img)..."
        echo "kernel=kernel8.img" | sudo tee -a "$CONFIG_TXT"
    fi
fi

# ---------------------------------------------------------
# 2. System Packages & Dependencies
# ---------------------------------------------------------
echo "[2/7] Installing required system packages..."
sudo apt update
sudo apt install -y \
    git curl wget \
    python3-evdev python3-pynput python3-tk \
    python3-pygame python3-pip python3-pyqt5 python3-opencv python3-numpy \
    libcamera-tools \
    matchbox-keyboard xdotool xkbset light-locker

# Grant user group permissions (Input, GPIO, Video access)
echo "[*] Updating user group permissions..."
sudo usermod -aG input,gpio,video,render "$USER"

# Backlight permissions
sudo chmod 666 /sys/class/backlight/*/brightness 2>/dev/null || true

# ---------------------------------------------------------
# 3. Touch Modules & Quick Panel Scripts
# ---------------------------------------------------------
echo "[3/7] Deploying touch and panel scripts..."
[ -f "touch_right_click.py" ] && sudo cp touch_right_click.py /usr/local/bin/touch_right_click.py && sudo chmod +x /usr/local/bin/touch_right_click.py
[ -f "quick-panel.py" ] && sudo cp quick-panel.py /usr/local/bin/quick-panel.py && sudo chmod +x /usr/local/bin/quick-panel.py
[ -f "lock-sleep.sh" ] && sudo cp lock-sleep.sh /usr/local/bin/lock-sleep.sh && sudo chmod +x /usr/local/bin/lock-sleep.sh

# Configure autostart
mkdir -p "$HOME/.config/autostart"
if [ -f "touch-rightclick.desktop" ]; then
    cp touch-rightclick.desktop "$HOME/.config/autostart/touch-rightclick.desktop"
fi

# Session persistence (.xsessionrc)
echo "[*] Adding X11 keyboard and panel session configurations..."
grep -qxF "xkbset accessx sticky -twokey -latchto" "$HOME/.xsessionrc" 2>/dev/null || echo "xkbset accessx sticky -twokey -latchto" >> "$HOME/.xsessionrc"
grep -qxF "xkbset exp =sticky" "$HOME/.xsessionrc" 2>/dev/null || echo "xkbset exp =sticky" >> "$HOME/.xsessionrc"
grep -qxF "xset r rate 250 35" "$HOME/.xsessionrc" 2>/dev/null || echo "xset r rate 250 35" >> "$HOME/.xsessionrc"
grep -qxF "python3 /usr/local/bin/quick-panel.py &" "$HOME/.xsessionrc" 2>/dev/null || echo "python3 /usr/local/bin/quick-panel.py &" >> "$HOME/.xsessionrc"

# ---------------------------------------------------------
# 4. KOReader Installation
# ---------------------------------------------------------
echo "[4/7] Downloading and installing KOReader..."
KO_URL=$(curl -s https://api.github.com/repos/koreader/koreader/releases/latest | grep "browser_download_url.*arm64.*\.deb" | cut -d '"' -f 4 | head -n 1)
if [ -n "$KO_URL" ]; then
    wget -qO /tmp/koreader.deb "$KO_URL"
    sudo dpkg -i /tmp/koreader.deb || sudo apt install -f -y
    rm -f /tmp/koreader.deb
fi

# ---------------------------------------------------------
# 5. RPiCamGUI Installation
# ---------------------------------------------------------
echo "[5/7] Cloning RPiCamGUI repository..."
if [ ! -d "$HOME/RPiCamGUI" ]; then
    git clone https://github.com/Gordon999/RPiCamGUI.git "$HOME/RPiCamGUI"
    chmod +x "$HOME/RPiCamGUI/RPiCamGUI.py"
fi

# ---------------------------------------------------------
# 6. Steam (Box86 & Box64) Setup
# ---------------------------------------------------------
echo "[6/7] Configuring Box86, Box64, and Steam..."
sudo dpkg --add-architecture armhf

sudo wget -q https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
sudo wget -q https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg > /dev/null
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg > /dev/null

sudo apt update
sudo apt install -y box64-rpi5arm64 box86-generic-arm:armhf libgl1-mesa-dri:armhf libgl1-mesa-glx:armhf

if [ ! -f "/usr/local/bin/steam" ]; then
    wget -qO /tmp/install_steam.sh https://raw.githubusercontent.com/ptitSeb/box86/master/install_steam.sh
    chmod +x /tmp/install_steam.sh
    /tmp/install_steam.sh
    rm -f /tmp/install_steam.sh
fi

# ---------------------------------------------------------
# 7. Desktop Launchers (.desktop)
# ---------------------------------------------------------
echo "[7/7] Generating desktop shortcuts..."
mkdir -p "$HOME/Desktop"

# Quick Panel
cat << 'EOF' > "$HOME/Desktop/quick-panel.desktop"
[Desktop Entry]
Type=Application
Name=Quick Panel
Comment=Brightness and Screen Lock Control
Exec=python3 /usr/local/bin/quick-panel.py
Icon=preferences-system
Terminal=false
Categories=Utility;Settings;
EOF

# KOReader
cat << 'EOF' > "$HOME/Desktop/koreader.desktop"
[Desktop Entry]
Type=Application
Name=KOReader
Comment=E-Book Reader
Exec=koreader -w 800x600
Icon=accessories-dictionary
Terminal=false
Categories=Office;Viewer;
EOF

# RPiCamGUI
cat << 'EOF' > "$HOME/Desktop/rpicamgui.desktop"
[Desktop Entry]
Type=Application
Name=RPi Cam GUI
Comment=Touchscreen Camera Controller
Exec=/bin/sh -c "python3 $HOME/RPiCamGUI/RPiCamGUI.py"
Icon=camera-photo
Terminal=false
Categories=AudioVideo;Video;
EOF

# Steam
cat << 'EOF' > "$HOME/Desktop/steam.desktop"
[Desktop Entry]
Type=Application
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=/usr/local/bin/steam %U
Icon=steam
Terminal=false
Categories=Game;
EOF

chmod +x "$HOME/Desktop/"*.desktop
sudo cp "$HOME/Desktop/quick-panel.desktop" /usr/share/applications/ 2>/dev/null || true
sudo cp "$HOME/Desktop/rpicamgui.desktop" /usr/share/applications/ 2>/dev/null || true

echo "========================================================="
echo "[+] All installation steps completed successfully!"
echo "[!] A system reboot is required to activate the 4K kernel"
echo "    and apply user group permissions: sudo reboot"
echo "========================================================="
EOF
chmod +x install.sh
