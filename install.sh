cat << 'INSTALL_EOF' > install.sh
#!/usr/bin/env bash
set -e

CONFIG_TXT="/boot/firmware/config.txt"
XSESSIONRC="$HOME/.xsessionrc"
WINE_VER="9.0"   # Kron4ek Wine-Builds release tag, change if you want another version

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
add_line() {
    # add_line "<line>" "<file>"  (needs sudo, skips if already present)
    local line="$1" file="$2"
    if ! sudo grep -qxF "$line" "$file" 2>/dev/null; then
        echo "$line" | sudo tee -a "$file" > /dev/null
        echo ">> Added to $file: $line"
    fi
}

add_user_line() {
    local line="$1" file="$2"
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

ask_yes_no() {
    # ask_yes_no "<question>" "<default y|n>"
    local prompt="$1" default="$2" answer
    while true; do
        if [ "$default" = "y" ]; then
            read -rp "$prompt [Y/n]: " answer
            answer="${answer:-y}"
        else
            read -rp "$prompt [y/N]: " answer
            answer="${answer:-n}"
        fi
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

raspi_nonint() {
    sudo raspi-config nonint "$@" || echo "[!] raspi-config $* failed (skipping)"
}

# ---------------------------------------------------------
# 0. Screen selection and options
# ---------------------------------------------------------
echo "========================================================="
echo " Raspberry Pi 5 AI-HAT & Workstation Setup"
echo "========================================================="
echo
echo "Which screen will you use?"
echo "  1) Touch Display Module (physical touchscreen)"
echo "  2) Phone (RealVNC over USB tethering)"
echo

SCREEN=""
while [ -z "$SCREEN" ]; do
    read -rp "Enter 1 or 2: " choice
    case "$choice" in
        1) SCREEN="display" ;;
        2) SCREEN="phone" ;;
        *) echo "Invalid choice, please enter 1 or 2." ;;
    esac
done

INSTALL_HAILO=0
POWER_5A=0

if ask_yes_no "Is an AI HAT (Hailo) connected to the PCIe port?" "y"; then
    INSTALL_HAILO=1
fi

if [ "$SCREEN" = "phone" ]; then
    echo ">> Selected: Phone (RealVNC)"
    if ask_yes_no "Does your power bank truly deliver 5V/5A (enables usb_max_current_enable)?" "n"; then
        POWER_5A=1
    fi
else
    echo ">> Selected: Touch Display Module"
fi

echo
INSTALL_GAMING=0
INSTALL_WINE=0
if ask_yes_no "Install gaming performance tweaks (CPU governor, GameMode, Box64, Mesa, ZRAM)?" "y"; then
    INSTALL_GAMING=1
    if ask_yes_no "Also install Wine for Windows games (large download)?" "n"; then
        INSTALL_WINE=1
    fi
fi

echo
echo "=== Starting Full Setup (screen: $SCREEN | Hailo: $INSTALL_HAILO) ==="

# ---------------------------------------------------------
# 1. 4K Page Size Kernel (required for Box86/Steam)
# ---------------------------------------------------------
echo "[1/8] Checking kernel page size..."
if [ -f "$CONFIG_TXT" ]; then
    if ! grep -q "^kernel=kernel8.img" "$CONFIG_TXT"; then
        echo ">> Appending 4K kernel (kernel=kernel8.img)..."
        echo "kernel=kernel8.img" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
fi

# ---------------------------------------------------------
# 2. System packages, Camera, and dependencies
# ---------------------------------------------------------
echo "[2/8] Installing required system & camera packages..."
sudo apt update

COMMON_PKGS="git curl wget xdotool xkbset ffmpeg \
    rpicam-apps libcamera-apps libcamera-tools \
    python3-picamera2 python3-libcamera python3-kms++ \
    python3-simplejpeg python3-gpiozero \
    python3-pygame python3-pip python3-pyqt5 python3-opencv python3-numpy"

if [ "$SCREEN" = "display" ]; then
    sudo apt install -y $COMMON_PKGS \
        python3-evdev python3-pynput python3-tk \
        matchbox-keyboard light-locker
    echo "[*] Updating user group permissions..."
    sudo usermod -aG input,gpio,video,render "$USER"
    sudo chmod 666 /sys/class/backlight/*/brightness 2>/dev/null || true
else
    sudo apt install -y $COMMON_PKGS network-manager
    echo "[*] Updating user group permissions..."
    sudo usermod -aG gpio,video,render "$USER"
fi

# Configure Camera (IMX708) permissions and kernel module
sudo modprobe imx708 2>/dev/null || true
sudo chmod 666 /dev/video* /dev/media* 2>/dev/null || true

# ---------------------------------------------------------
# 3. Screen-specific & AI HAT (Hailo) configuration
# ---------------------------------------------------------
echo "[3/8] Applying $SCREEN and hardware configuration..."
mkdir -p "$HOME/.config/autostart"

if [ "$SCREEN" = "display" ]; then
    # --- Touch modules and quick panel scripts ---
    [ -f "touch_right_click.py" ] && sudo cp touch_right_click.py /usr/local/bin/touch_right_click.py && sudo chmod +x /usr/local/bin/touch_right_click.py
    [ -f "quick-panel.py" ] && sudo cp quick-panel.py /usr/local/bin/quick-panel.py && sudo chmod +x /usr/local/bin/quick-panel.py
    [ -f "lock-sleep.sh" ] && sudo cp lock-sleep.sh /usr/local/bin/lock-sleep.sh && sudo chmod +x /usr/local/bin/lock-sleep.sh

    if [ -f "touch-rightclick.desktop" ]; then
        cp touch-rightclick.desktop "$HOME/.config/autostart/touch-rightclick.desktop"
    fi

    echo "[*] Adding X11 keyboard and panel session configurations..."
    add_user_line "xkbset accessx sticky -twokey -latchto" "$XSESSIONRC"
    add_user_line "xkbset exp =sticky" "$XSESSIONRC"
    add_user_line "xset r rate 250 35" "$XSESSIONRC"
    add_user_line "python3 /usr/local/bin/quick-panel.py &" "$XSESSIONRC"
else
    # --- raspi-config settings ---
    echo "[*] Applying raspi-config settings (VNC, X11, resolution, PCIe)..."
    raspi_nonint do_vnc 0
    raspi_nonint do_ssh 0
    raspi_nonint do_vnc_resolution 1280x720
    raspi_nonint do_blanking 1
    raspi_nonint do_wayland W1
    raspi_nonint do_pci 0
    raspi_nonint do_boot_behaviour B4

    sudo systemctl enable --now vncserver-x11-serviced || echo "[!] Could not enable vncserver-x11-serviced"

    # --- Power bank ---
    if [ "$POWER_5A" -eq 1 ]; then
        add_line "usb_max_current_enable=1" "$CONFIG_TXT"
    fi

    # --- USB tethering auto-connect ---
    echo "[*] Enabling auto-connect on wired (USB tethering) connections..."
    nmcli -t -f NAME,TYPE con show 2>/dev/null | awk -F: '$2=="802-3-ethernet"{print $1}' | while read -r con; do
        sudo nmcli con modify "$con" connection.autoconnect yes || true
    done

    # --- Sticky keys and key repeat ---
    add_user_line "xkbset accessx sticky -twokey -latchto" "$XSESSIONRC"
    add_user_line "xkbset exp =sticky" "$XSESSIONRC"
    add_user_line "xset r rate 250 35" "$XSESSIONRC"
fi

# --- AI HAT (Hailo) PCIe & 5s Delayed Cron Load (prevents DSI display conflict) ---
if [ "$INSTALL_HAILO" -eq 1 ]; then
    echo "[*] Configuring AI HAT (Hailo) PCIe with 5s delayed boot load..."
    sudo apt install -y hailo-all || echo "[!] hailo-all installation failed"
    add_line "dtparam=pciex1" "$CONFIG_TXT"
    add_line "dtparam=pciex1_gen=3" "$CONFIG_TXT"

    # Disable early loading at boot to prevent display conflicts
    sudo rm -f /etc/modules-load.d/hailo.conf
    echo "blacklist hailo_pci" | sudo tee /etc/modprobe.d/hailo-blacklist.conf > /dev/null
    sudo depmod -a

    # Clean up any legacy systemd delayed-load service remnants
    sudo systemctl disable --now hailo-delayed-load.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/hailo-delayed-load.service \
               /etc/systemd/system/graphical.target.wants/hailo-delayed-load.service \
               /etc/systemd/system/multi-user.target.wants/hailo-delayed-load.service
    sudo systemctl daemon-reload

    # Add cron job to load the AI HAT driver 5 seconds after boot
    (sudo crontab -l 2>/dev/null | grep -v "hailo_pci"; echo "@reboot sleep 5 && /sbin/modprobe hailo_pci") | sudo crontab -
fi

# ---------------------------------------------------------
# 4. KOReader installation
# ---------------------------------------------------------
echo "[4/8] Downloading and installing KOReader..."
KO_URL=$(curl -s https://api.github.com/repos/koreader/koreader/releases/latest | grep "browser_download_url.*arm64.*\.deb" | cut -d '"' -f 4 | head -n 1)
if [ -n "$KO_URL" ]; then
    wget -qO /tmp/koreader.deb "$KO_URL"
    sudo dpkg -i /tmp/koreader.deb || sudo apt install -f -y
    rm -f /tmp/koreader.deb
fi

# ---------------------------------------------------------
# 5. RPiCamGUI installation
# ---------------------------------------------------------
echo "[5/8] Cloning RPiCamGUI repository..."
if [ ! -d "$HOME/RPiCamGUI" ]; then
    git clone https://github.com/Gordon999/RPiCamGUI.git "$HOME/RPiCamGUI"
    chmod +x "$HOME/RPiCamGUI/RPiCamGUI.py"
fi

# ---------------------------------------------------------
# 6. Steam (Box86 and Box64) setup
# ---------------------------------------------------------
echo "[6/8] Configuring Box86, Box64, and Steam..."
sudo dpkg --add-architecture armhf

sudo wget -q https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
sudo wget -q https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg > /dev/null
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg > /dev/null

sudo apt update
sudo apt install -y box64-rpi5arm64 box86-generic-arm:armhf libgl1-mesa-dri:armhf
sudo apt install -y libgl1-mesa-glx:armhf 2>/dev/null || sudo apt install -y libglx-mesa0:armhf || echo "[!] Could not install armhf GLX library"

if [ ! -f "/usr/local/bin/steam" ]; then
    wget -qO /tmp/install_steam.sh https://raw.githubusercontent.com/ptitSeb/box86/master/install_steam.sh
    chmod +x /tmp/install_steam.sh
    /tmp/install_steam.sh
    rm -f /tmp/install_steam.sh
fi

# ---------------------------------------------------------
# 7. Gaming performance tweaks
# ---------------------------------------------------------
if [ "$INSTALL_GAMING" -eq 1 ]; then
    echo "[7/8] Applying gaming performance tweaks..."

    # --- 7.1 CPU governor: performance ---
    echo "[*] Setting CPU governor to performance (systemd service)..."
    sudo tee /etc/systemd/system/cpu-performance.service > /dev/null << 'GOV_EOF'
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > $g; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
GOV_EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now cpu-performance.service || echo "[!] Could not enable cpu-performance.service"

    # --- 7.2 GameMode and MangoHud ---
    echo "[*] Installing GameMode and MangoHud..."
    sudo apt install -y gamemode mangohud || echo "[!] gamemode/mangohud installation failed"
    sudo usermod -aG gamemode "$USER" 2>/dev/null || true

    # --- 7.3 Box64 performance profile ---
    echo "[*] Creating Box64 example profile..."
    if [ ! -f /etc/box64.box64rc ]; then
        sudo tee /etc/box64.box64rc > /dev/null << 'BOX_EOF'
# Box64 per-game profiles.
# [hl2_linux]
# BOX64_DYNAREC_BIGBLOCK=2
# BOX64_DYNAREC_FASTNAN=1
# BOX64_DYNAREC_FASTROUND=1
# BOX64_DYNAREC_CALLRET=1
BOX_EOF
    else
        echo ">> /etc/box64.box64rc already exists, leaving it unchanged."
    fi

    # --- 7.4 Mesa / V3D driver check ---
    echo "[*] Installing Mesa / Vulkan packages..."
    sudo apt install -y mesa-utils mesa-vulkan-drivers vulkan-tools libgl1-mesa-dri libglx-mesa0 || echo "[!] Mesa package installation failed"

    # --- 7.5 Wine (optional) ---
    if [ "$INSTALL_WINE" -eq 1 ]; then
        echo "[*] Installing Wine $WINE_VER (x86_64, via Box64)..."
        sudo apt install -y cabextract p7zip-full unzip winetricks || echo "[!] Wine prerequisites failed"

        if [ ! -d "$HOME/wine" ]; then
            WINE_FILE="wine-${WINE_VER}-amd64.tar.xz"
            if wget -qO "/tmp/$WINE_FILE" "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VER}/${WINE_FILE}"; then
                tar -xf "/tmp/$WINE_FILE" -C "$HOME"
                mv "$HOME/wine-${WINE_VER}-amd64" "$HOME/wine"
                rm -f "/tmp/$WINE_FILE"
            else
                echo "[!] Wine download failed (check WINE_VER at the top of this script)"
                rm -f "/tmp/$WINE_FILE"
            fi
        else
            echo ">> $HOME/wine already exists, skipping download."
        fi

        if [ -d "$HOME/wine" ]; then
            sudo tee /usr/local/bin/wine64 > /dev/null << 'WINE_EOF'
#!/bin/bash
exec box64 "$HOME/wine/bin/wine64" "$@"
WINE_EOF
            sudo tee /usr/local/bin/wineserver > /dev/null << 'WINESRV_EOF'
#!/bin/bash
exec box64 "$HOME/wine/bin/wineserver" "$@"
WINESRV_EOF
            sudo chmod +x /usr/local/bin/wine64 /usr/local/bin/wineserver

            add_user_line "export WINEPREFIX=\$HOME/.wine64" "$HOME/.profile"
            add_user_line "export WINEARCH=win64" "$HOME/.profile"
            echo ">> Wine installed. Initialize the prefix after reboot with: wine64 wineboot --init"
        fi
    fi

    # --- 7.6 ZRAM and swap tuning ---
    echo "[*] Configuring ZRAM and swappiness..."
    sudo apt install -y zram-tools || echo "[!] zram-tools installation failed"
    sudo tee /etc/default/zramswap > /dev/null << 'ZRAM_EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
ZRAM_EOF
    sudo systemctl restart zramswap 2>/dev/null || echo "[!] Could not restart zramswap"
    echo "vm.swappiness=100" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
    sudo sysctl --system > /dev/null || true
else
    echo "[7/8] Skipping gaming performance tweaks."
fi

# ---------------------------------------------------------
# 8. Desktop launchers (.desktop)
# ---------------------------------------------------------
echo "[8/8] Generating desktop shortcuts..."
mkdir -p "$HOME/Desktop"

if [ "$SCREEN" = "display" ]; then
    cat << 'DESKTOP_EOF' > "$HOME/Desktop/quick-panel.desktop"
[Desktop Entry]
Type=Application
Name=Quick Panel
Comment=Brightness and Screen Lock Control
Exec=python3 /usr/local/bin/quick-panel.py
Icon=preferences-system
Terminal=false
Categories=Utility;Settings;
DESKTOP_EOF
fi

cat << 'DESKTOP_EOF' > "$HOME/Desktop/koreader.desktop"
[Desktop Entry]
Type=Application
Name=KOReader
Comment=E-Book Reader
Exec=koreader -w 800x600
Icon=accessories-dictionary
Terminal=false
Categories=Office;Viewer;
DESKTOP_EOF

cat << 'DESKTOP_EOF' > "$HOME/Desktop/rpicamgui.desktop"
[Desktop Entry]
Type=Application
Name=RPi Cam GUI
Comment=Camera Controller
Exec=/bin/sh -c "python3 $HOME/RPiCamGUI/RPiCamGUI.py"
Icon=camera-photo
Terminal=false
Categories=AudioVideo;Video;
DESKTOP_EOF

cat << 'DESKTOP_EOF' > "$HOME/Desktop/steam.desktop"
[Desktop Entry]
Type=Application
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=/usr/local/bin/steam %U
Icon=steam
Terminal=false
Categories=Game;
DESKTOP_EOF

chmod +x "$HOME/Desktop/"*.desktop
[ -f "$HOME/Desktop/quick-panel.desktop" ] && sudo cp "$HOME/Desktop/quick-panel.desktop" /usr/share/applications/ 2>/dev/null || true
sudo cp "$HOME/Desktop/rpicamgui.desktop" /usr/share/applications/ 2>/dev/null || true

# ---------------------------------------------------------
# Done
# ---------------------------------------------------------
echo
echo "========================================================="
echo "[+] All installation steps completed successfully!"
if [ "$SCREEN" = "phone" ]; then
    echo
    echo "Next steps for phone usage:"
    echo "  1. Reboot:  sudo reboot"
    echo "  2. Connect the phone to a USB-A port and enable USB Tethering"
    echo "  3. Find the Pi IP:  hostname -I"
    echo "  4. Open RealVNC Viewer on the phone and connect (IP or Cloud)"
fi
if [ "$INSTALL_HAILO" -eq 1 ]; then
    echo
    echo "AI HAT (Hailo) verification (wait 5s after reboot):"
    echo "  - Check device:    ls -l /dev/hailo0"
    echo "  - Check firmware:  hailortcli fw-control identify"
    echo "  - Check camera:    rpicam-hello --list-cameras"
fi
if [ "$INSTALL_GAMING" -eq 1 ]; then
    echo
    echo "Gaming tips:"
    echo "  - Check throttling:  vcgencmd get_throttled   (0x0 = OK)"
    echo "  - Check GPU driver:  glxinfo -B | grep renderer   (should show V3D 7.1)"
    echo "  - Steam launch options:  gamemoderun %command%"
    echo "  - Box64 per-game profiles:  /etc/box64.box64rc"
    if [ "$INSTALL_WINE" -eq 1 ]; then
        echo "  - Wine: after reboot run  wine64 wineboot --init"
    fi
fi
echo
echo "[!] A system reboot is required to activate the 4K kernel"
echo "    and apply user group permissions: sudo reboot"
echo "========================================================="
INSTALL_EOF
chmod +x install.sh
