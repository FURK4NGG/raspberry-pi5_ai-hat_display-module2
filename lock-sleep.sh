#!/bin/bash
# Oturumu standart lightdm kilit ekranına al
light-locker-command -l 2>/dev/null || dm-tool lock

# Dokunmatik ekranı uyku moduna (karartma) sok
xset dpms force off
