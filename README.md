# raspberry-pi5_ai-hat_display_module2

sudo apt update
sudo apt install -y python3-evdev python3-pynput


/usr/local/bin/touch_right_click.py

sudo chmod +x /usr/local/bin/touch_right_click.py
python3 /usr/local/bin/touch_right_click.py


auto start
sudo nano /etc/systemd/system/touch-rightclick.service

sudo systemctl daemon-reload
sudo systemctl enable --now touch-rightclick.service
