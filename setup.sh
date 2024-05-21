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

# Prompt for a valid username
while true; do
    read -p "Enter a username: " username

    # Check if the username is valid
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]{2,15}$ ]]; then
        echo "Username '$username' is valid and can be used."
        break
    else
        echo "Invalid username. It must start with a lowercase letter or underscore, can contain lowercase letters, digits, underscores, and hyphens, and be between 3 to 16 characters long."
    fi
done

# Prompt for a valid hostname
while true; do
    read -p "Enter a hostname: " hostname

    # Check if the hostname is valid
    if [[ "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$ ]]; then
        echo "Hostname '$hostname' is valid and can be used."
        break
    else
        echo "Invalid hostname. It must start and end with a letter or digit, can contain letters, digits, and hyphens, and be between 1 to 63 characters long."
    fi
done

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

# Install essential packages including sudo, git, and additional dependencies
echo "Installing essential packages..."
pacstrap /mnt base linux linux-firmware vim networkmanager wget unzip tar grub efibootmgr lightdm lightdm-gtk-greeter xfce4 xfce4-goodies sudo nasm check xorg-xdpyinfo git

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
echo "$hostname" > /etc/hostname
{
    echo "127.0.0.1 localhost"
    echo "::1       localhost"
    echo "127.0.1.1 $hostname.localdomain $hostname"
} >> /etc/hosts
systemctl enable NetworkManager

# Root password
echo root:password | chpasswd

# Create the user and configure automatic login
useradd -m -G wheel -s /bin/bash $username
echo $username:password | chpasswd

# Configure sudoers for passwordless sudo for the wheel group
if ! grep -q '^%wheel ALL=(ALL) NOPASSWD: ALL' /etc/sudoers; then
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Set up automatic login for LightDM and the XFCE session
mkdir -p /etc/lightdm/lightdm.conf.d
echo -e "[Seat:*]\nautologin-user=$username\nautologin-session=xfce" > /etc/lightdm/lightdm.conf.d/20-autologin.conf

# Enable LightDM to start at boot
systemctl enable lightdm.service

# Bootloader installation
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Unmount partitions and reboot
umount -R /mnt
echo "Setup complete. Rebooting..."
reboot
