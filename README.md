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
Comment=Parlaklık ve Kilit Kontrolü
Exec=python3 /usr/local/bin/quick-panel.py
Icon=preferences-system
Terminal=false
Categories=Utility;Settings;
EOF

chmod +x ~/Desktop/quick-panel.desktop
sudo cp ~/Desktop/quick-panel.desktop /usr/share/applications/
```

auto start  
```
mkdir -p ~/.config/autostart
```

# Her masaüstü açılışında kalıcı olması için:  
```
# Sticky Keys & Timeout Prevention
grep -qxF "xkbset accessx sticky -twokey -latchto" ~/.xsessionrc 2>/dev/null || echo "xkbset accessx sticky -twokey -latchto" >> ~/.xsessionrc
grep -qxF "xkbset exp =sticky" ~/.xsessionrc 2>/dev/null || echo "xkbset exp =sticky" >> ~/.xsessionrc

# Continuous Key Auto-Repeat
grep -qxF "xset r rate 250 35" ~/.xsessionrc 2>/dev/null || echo "xset r rate 250 35" >> ~/.xsessionrc

# Autostart Quick Panel
grep -qxF "python3 /usr/local/bin/quick-panel.py &" ~/.xsessionrc 2>/dev/null || echo "python3 /usr/local/bin/quick-panel.py &" >> ~/.xsessionrc
```

sudo reboot



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


# Fast Installation  

```
sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2.git  
cd raspberry-pi5_ai-hat_display-module2  
chmod +x install.sh  
./install.sh  
```
