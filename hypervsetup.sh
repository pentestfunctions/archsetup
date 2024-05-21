#!/bin/bash

# Fix key issues on fresh install
echo "Fixing key issues on fresh install..."
sudo rm -rf /etc/pacman.d/gnupg/ 2>/dev/null
sudo rm -rf ~/.gnupg 2>/dev/null
sudo pacman-key --init
sudo pacman-key --populate
sudo pacman -Sy archlinux-keyring --noconfirm

# Setup YAY
echo "Setting up YAY..."
cd /tmp
sudo pacman -S --needed git base-devel arch-repro-status --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

# Setup PARU
echo "Setting up PARU..."
sudo pacman -S openssl-1.1 --noconfirm
yay -S paru --noconfirm

# Install packages for Enhanced Session Mode
echo "Installing packages for Enhanced Session Mode..."
sudo pacman -S hyperv --noconfirm
sudo systemctl enable --now hv_fcopy_daemon
sudo systemctl enable --now hv_kvp_daemon
sudo systemctl enable --now hv_vss_daemon

# Install XRDP
echo "Installing XRDP..."
yay -S xrdp --noconfirm
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 61ECEABBF2BB40E3A35DF30A9F72CDBC01BF10EB
yay -S xorgxrdp --noconfirm
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo xrdp-keygen xrdp /etc/xrdp/rsakeys.ini
yay -S sbc --noconfirm
yay -S pulseaudio-module-xrdp --noconfirm

# Additional setup for XRDP
echo "Running additional setup for XRDP..."
cd /tmp
git clone https://github.com/Microsoft/linux-vm-tools
cd linux-vm-tools/arch
sudo ./install-config.sh
echo "exec startxfce4" > ~/.xinitrc

sudo tee /usr/lib/hyperv/kvp_scripts/hv_get_dhcp_info > /dev/null <<EOF
#!/bin/bash
echo "DHCP info not implemented"
exit 0
EOF
sudo chmod +x /usr/lib/hyperv/kvp_scripts/hv_get_dhcp_info

sudo tee /usr/lib/hyperv/kvp_scripts/hv_get_dns_info > /dev/null <<EOF
#!/bin/bash
echo "DNS info not implemented"
exit 0
EOF
sudo chmod +x /usr/lib/hyperv/kvp_scripts/hv_get_dns_info

sudo systemctl restart hv_kvp_daemon

sudo cp resources/xrdp.ini /etc/xrdp/xrdp.ini

echo "Setup complete!"
