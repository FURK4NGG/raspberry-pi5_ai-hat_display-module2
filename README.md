# raspberry-pi5_ai-hat_display-module2

Directory Structures  
/usr/local/bin/touch_right_click.py  
~/.config/autostart/touch-rightclick.desktop  

/boot/firmware/config.txt  
/boot/firmware/cmdline.txt  
/etc/modprobe.d/hailo-blacklist.conf  
/etc/systemd/system/hailo-delayed-load.service  




sudo apt update  
sudo apt install -y python3-evdev python3-pynput  
sudo usermod -aG input $USER  

sudo chmod +x /usr/local/bin/touch_right_click.py  
RUN  
python3 /usr/local/bin/touch_right_click.py  


auto start
mkdir -p ~/.config/autostart   

sudo reboot


Control  
pgrep -af touch_right_click  


# Fast Installation  

sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/raspberry-pi5_ai-hat_display-module2.git  
cd raspberry-pi5_ai-hat_display-module2  
chmod +x install.sh  
./install.sh  
