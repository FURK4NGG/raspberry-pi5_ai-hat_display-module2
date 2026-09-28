# raspberry-pi5_ai-hat_display-module2

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
