#!/bin/bash

# Setup logging
exec > >(tee /var/log/arch_install.log)
exec 2>&1

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check for internet connectivity
if ! ping -c 3 google.com; then
    echo "Internet connection is required" >&2
    exit 1
fi

# Update system clock
timedatectl set-ntp true

# Partition the disk
echo "Partitioning the disk..."
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart ESP fat32 1MiB 513MiB
parted -s /dev/sda set 1 esp on
parted -s /dev/sda mkpart primary ext4 513MiB 100%

# Format partitions
echo "Formatting the partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount partitions
echo "Mounting the partitions..."
mount /dev/sda2 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# Install essential packages
echo "Installing essential packages..."
pacstrap /mnt base linux linux-firmware vim networkmanager grub efibootmgr xrdp git

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure the system
arch-chroot /mnt /bin/bash -e <<EOF

# Timezone and locale
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "myhostname" > /etc/hostname
{
    echo "127.0.0.1 localhost"
    echo "::1       localhost"
    echo "127.0.1.1 myhostname.localdomain myhostname"
} >> /etc/hosts
systemctl enable NetworkManager

# Root password
echo root:password | chpasswd

# Bootloader installation
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Create second-stage script for user setup
cat > /mnt/root/second_stage.sh <<'EOSTAGE'
#!/bin/bash

# Install XFCE4 and LightDM
pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter

# Enable and configure automatic login for LightDM
sed -i 's/#autologin-user=/autologin-user=username/' /etc/lightdm/lightdm.conf
sed -i 's/#autologin-session=/autologin-session=xfce/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service

# Add a regular user with password
useradd -m -G wheel -s /bin/bash username
echo username:password | chpasswd

# Enable sudo for the user
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install and configure Enhanced Session Mode
git clone https://github.com/Microsoft/linux-vm-tools /opt/linux-vm-tools
cd /opt/linux-vm-tools/arch
./makepkg.sh
./install-config.sh

# Configure .xinitrc for xrdp session
echo "exec startxfce4" > /home/username/.xinitrc
chown username:username /home/username/.xinitrc

# Start and enable xrdp service
systemctl enable xrdp
systemctl start xrdp

# Disable the firstboot service so it doesn't run again
systemctl disable firstboot.service

EOSTAGE

chmod +x /mnt/root/second_stage.sh

# Setup systemd service to run second_stage.sh on first boot
cat > /mnt/etc/systemd/system/firstboot.service <<'EOF'
[Unit]
Description=First Boot Script
After=network.target
Before=getty@tty1.service

[Service]
Type=oneshot
ExecStart=/root/second_stage.sh
StandardOutput=journal
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the firstboot service
arch-chroot /mnt systemctl enable firstboot.service

# Unmount partitions and reboot
umount -R /mnt
echo "Setup complete. Rebooting..."
reboot
