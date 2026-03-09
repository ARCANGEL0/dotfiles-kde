#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'

theme_name="miside-sddm-theme"
theme_install_path="/usr/share/sddm/themes/$theme_name"

echo -e "${green}[*] Installing MiSide SDDM theme.${no_color}"

sudo -v || { echo -e "${red}[*] Sudo access is required.${no_color}"; exit 1; }

if [ -d "$theme_install_path" ]; then
    sudo mv "$theme_install_path" "${theme_install_path}_backup_$(date +%s)"
    echo -e "${green}[*] Old theme backup created.${no_color}"
fi

sudo mkdir -p "$theme_install_path"

sudo cp -r ./* "$theme_install_path"

if [ -d "$theme_install_path/Fonts" ]; then
    sudo cp -r "$theme_install_path/Fonts/"* /usr/share/fonts/
fi

sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]
Current=$theme_name" | sudo tee /etc/sddm.conf.d/00-miside-theme.conf >/dev/null

sudo systemctl disable display-manager.service 2>/dev/null
sudo systemctl enable sddm.service

echo -e "${green}[*] MiSide SDDM theme installed successfully! Reboot to apply.${no_color}"
