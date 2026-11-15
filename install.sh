cat << 'INSTALL_EOF' > install.sh
#!/usr/bin/env bash
set -e

CONFIG_TXT="/boot/firmware/config.txt"
XSESSIONRC="$HOME/.xsessionrc"

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
# 0. Screen selection
# ---------------------------------------------------------
echo "========================================================="
echo " Raspberry Pi 5 AI-HAT Setup"
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

if [ "$SCREEN" = "phone" ]; then
    echo ">> Selected: Phone (RealVNC)"
    if ask_yes_no "Is an AI HAT (Hailo) connected to the PCIe port?" "y"; then
        INSTALL_HAILO=1
    else
        INSTALL_HAILO=0
    fi
    if ask_yes_no "Does your power bank truly deliver 5V/5A (enables usb_max_current_enable)?" "n"; then
        POWER_5A=1
    else
        POWER_5A=0
    fi
else
    echo ">> Selected: Touch Display Module"
fi

echo
echo "=== Starting Full Setup (screen: $SCREEN) ==="

# ---------------------------------------------------------
# 1. 4K Page Size Kernel (required for Box86/Steam)
# ---------------------------------------------------------
echo "[1/7] Checking kernel page size..."
if [ -f "$CONFIG_TXT" ]; then
    if ! grep -q "^kernel=kernel8.img" "$CONFIG_TXT"; then
        echo ">> Appending 4K kernel (kernel=kernel8.img)..."
        echo "kernel=kernel8.img" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
fi

# ---------------------------------------------------------
# 2. System packages and dependencies
# ---------------------------------------------------------
echo "[2/7] Installing required system packages..."
sudo apt update

COMMON_PKGS="git curl wget xdotool xkbset python3-pygame python3-pip python3-pyqt5 python3-opencv python3-numpy libcamera-tools"

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

# ---------------------------------------------------------
# 3. Screen-specific configuration
# ---------------------------------------------------------
echo "[3/7] Applying $SCREEN configuration..."
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

    # --- AI HAT (Hailo) PCIe ---
    if [ "$INSTALL_HAILO" -eq 1 ]; then
        echo "[*] Configuring AI HAT (Hailo) PCIe..."
        sudo apt install -y hailo-all || echo "[!] hailo-all installation failed"
        add_line "dtparam=pciex1" "$CONFIG_TXT"
        add_line "dtparam=pciex1_gen=3" "$CONFIG_TXT"

        echo "blacklist hailo_pci" | sudo tee /etc/modprobe.d/hailo-blacklist.conf > /dev/null

        sudo tee /etc/systemd/system/hailo-delayed-load.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Delayed Hailo PCIe module load
After=multi-user.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 15
ExecStart=/sbin/modprobe hailo_pci

[Install]
WantedBy=multi-user.target
SERVICE_EOF

        sudo systemctl daemon-reload
        sudo systemctl enable hailo-delayed-load.service
    fi
fi

# ---------------------------------------------------------
# 4. KOReader installation
# ---------------------------------------------------------
echo "[4/7] Downloading and installing KOReader..."
KO_URL=$(curl -s https://api.github.com/repos/koreader/koreader/releases/latest | grep "browser_download_url.*arm64.*\.deb" | cut -d '"' -f 4 | head -n 1)
if [ -n "$KO_URL" ]; then
    wget -qO /tmp/koreader.deb "$KO_URL"
    sudo dpkg -i /tmp/koreader.deb || sudo apt install -f -y
    rm -f /tmp/koreader.deb
fi

# ---------------------------------------------------------
# 5. RPiCamGUI installation
# ---------------------------------------------------------
echo "[5/7] Cloning RPiCamGUI repository..."
if [ ! -d "$HOME/RPiCamGUI" ]; then
    git clone https://github.com/Gordon999/RPiCamGUI.git "$HOME/RPiCamGUI"
    chmod +x "$HOME/RPiCamGUI/RPiCamGUI.py"
fi

# ---------------------------------------------------------
# 6. Steam (Box86 and Box64) setup
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
# 7. Desktop launchers (.desktop)
# ---------------------------------------------------------
echo "[7/7] Generating desktop shortcuts..."
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
    echo "     (For Cloud: sign in to RealVNC from the VNC icon on the Pi)"
fi
echo
echo "[!] A system reboot is required to activate the 4K kernel"
echo "    and apply user group permissions: sudo reboot"
echo "========================================================="
INSTALL_EOF
chmod +x install.sh
