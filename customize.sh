#!/bin/bash

initial_dir=$(pwd)

# Check if the script is running as root
if [ "$(id -u)" -eq 0 ]; then
  echo "This script should not be run as root. Please run without sudo."
  exit 1
fi

# Setting a new wallpaper for Xfce
install_wallpaper_settings() {
    cd "$initial_dir"
    mkdir -p ~/Pictures
    sudo cp resources/background.jpg ~/Pictures/background.jpg
    sudo cp resources/background.bmp /etc/background.bmp
    sudo cp resources/background2.jpg ~/Pictures/background2.jpg
    sudo mv resources/xrdp.ini /etc/xrdp/xrdp.ini
    xfconf-query -c xfce4-desktop -l -v | grep image-path | grep -oE '^/[^ ]+' | xargs -I % xfconf-query -c xfce4-desktop -p % -s ~/Pictures/background2.jpg
    xfconf-query -c xfce4-desktop -l -v | grep last-image | grep -oE '^/[^ ]+' | xargs -I % xfconf-query -c xfce4-desktop -p % -s ~/Pictures/background2.jpg
}

# Configure our terminal settings
function terminal_transparency() {
    cd "$initial_dir"
    mkdir -p ~/.config/xfce4/terminal
    cp resources/terminalrc ~/.config/xfce4/terminal/terminalrc
}

add_panel_items() {
    local panel_id=$(xfconf-query -c xfce4-panel -l -v 2>/dev/null | grep "applicationsmenu" | awk '{print $1}')
    if ! xfconf-query -c xfce4-panel -p $panel_id -l 2>/dev/null | grep -q "whiskermenu"; then
        xfconf-query -c xfce4-panel -p $panel_id -n -t string -s "whiskermenu" 2>/dev/null
        xfce4-panel -r
    fi
    echo -e "\033[0;32mWhiskermenu setup completed\033[0m"
}

install_dracula_theme() {
    # Check if Dracula theme is installed
    if [ ! -d "/usr/share/themes/Dracula" ]; then
        # Download and install Dracula theme
        wget https://github.com/dracula/gtk/archive/master.zip -O /tmp/master.zip
        unzip -o /tmp/master.zip -d /tmp/master
        sudo mv /tmp/master/gtk-master /usr/share/themes/Dracula
        rm /tmp/master.zip
    fi

    # Activate Dracula theme
    xfconf-query -c xsettings -p /Net/ThemeName -s "Dracula"
    xfconf-query -c xfwm4 -p /general/theme -s "Dracula"

    # Check if Dracula icons are installed
    if [ ! -d "/usr/share/icons/Dracula" ]; then
        # Download and install Dracula icons
        wget https://github.com/dracula/gtk/files/5214870/Dracula.zip -O /tmp/Dracula.zip
        sudo unzip -o /tmp/Dracula.zip -d /usr/share/icons
        rm /tmp/Dracula.zip
    fi

    # Activate Dracula icons
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Dracula"
}

install_wallpaper_settings
terminal_transparency
add_panel_items
cp resources/bashrc ~/.bashrc
sudo cp resources/xfce4-panel-settings.tar.gz /tmp/
tar -xzf /tmp/xfce4-panel-settings.tar.gz -C ~/.config/xfce4/panel
source ~/.bashrc
install_dracula_theme
