cat << 'EOF' > install.sh
#!/bin/bash
set -e

echo "[*] Gerekli paketler yukleniyor..."
sudo apt update
sudo apt install -y python3-evdev python3-pynput

echo "[*] Kullanici yetkileri ayarlaniyor..."
sudo usermod -aG input $USER

echo "[*] Betik /usr/local/bin altina kopyalaniyor..."
sudo cp touch_right_click.py /usr/local/bin/touch_right_click.py
sudo chmod +x /usr/local/bin/touch_right_click.py

echo "[*] Autostart kaydi olusturuluyor..."
mkdir -p ~/.config/autostart
cp touch-rightclick.desktop ~/.config/autostart/touch-rightclick.desktop

echo "[+] Kurulum tamamlandi. Sistemi yeniden baslatabilirsiniz: sudo reboot"
EOF

chmod +x install.sh
