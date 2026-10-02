## 👀 raspberry-pi5_ai-hat_display-module2 Overview  

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
/usr/local/bin/quick-panel.py  

/usr/local/bin/lock-sleep.sh

├── /usr/share/matchbox-keyboard/keyboard.xml  
└── ~/.config/openbox/lxde-pi-rc.xml  



```
sudo apt update  
sudo apt install -y python3-evdev python3-pynput matchbox-keyboard xdotool xkbset light-locker
  
sudo usermod -aG input $USER  

sudo chmod 666 /sys/class/backlight/*/brightness 2>/dev/null

sudo chmod +x /usr/local/bin/touch_right_click.py
sudo chmod +x /usr/local/bin/quick-panel.py
```

Run Touch Movements  
```
python3 /usr/local/bin/touch_right_click.py
```

Run Keyboard  
```
killall -9 matchbox-keyboard 2>/dev/null  
matchbox-keyboard &  
```

Run light-locker  
```
light-locker &
```

Run Brightness Panel  
```
python3 /usr/local/bin/quick-panel.py &
```

Create Brightness Panel Desktop Shortcut  
```
cat << 'EOF' > ~/Desktop/quick-panel.desktop
[Desktop Entry]
Type=Application
Name=Quick Panel
Comment=Parlaklık ve Kilit Kontrolü
Exec=python3 /usr/local/bin/quick-panel.py
Icon=preferences-system
Terminal=false
Categories=Utility;Settings;
EOF

chmod +x ~/Desktop/quick-panel.desktop
# Sistem menüsüne de ekle:
sudo cp ~/Desktop/quick-panel.desktop /usr/share/applications/
```

auto start  
mkdir -p ~/.config/autostart   


# Aktif oturum için hemen devreye al:  
xkbset accessx sticky -twokey -latchto  

# Her masaüstü açılışında kalıcı olması için:  
grep -qxF "xkbset accessx sticky -twokey -latchto" ~/.xsessionrc 2>/dev/null || echo "xkbset accessx sticky -twokey -latchto" >> ~/.xsessionrc
grep -qxF "xset r rate 250 35" ~/.xsessionrc 2>/dev/null || echo "xset r rate 250 35" >> ~/.xsessionrc

grep -qxF "python3 /usr/local/bin/quick-panel.py &" ~/.xsessionrc 2>/dev/null || echo "python3 /usr/local/bin/quick-panel.py &" >> ~/.xsessionrc

Control  
>xkbset accessx sticky -twokey -latchto  
>xset r rate 250 35  

sudo reboot


Touch Movements Control  
```
pgrep -af touch_right_click  
```

# Fast Installation  

```
sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2.git  
cd raspberry-pi5_ai-hat_display-module2  
chmod +x install.sh  
./install.sh  
```
