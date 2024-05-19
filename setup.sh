#!/bin/bash

# Set up logging
exec > >(tee /var/log/arch_install.log)
exec 2>&1

# Check for internet connectivity
ping -c 3 google.com

# Update system clock
timedatectl set-ntp true

# Disk partitioning
echo "Partitioning the disk..."
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart primary fat32 1MiB 513MiB
parted -s /dev/sda set 1 esp on
parted -s /dev/sda mkpart primary ext4 513MiB 100%

# Formatting partitions
echo "Formatting the partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Mounting partitions
echo "Mounting the partitions..."
mount /dev/sda2 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# Install essential packages
echo "Installing essential packages..."
pacstrap /mnt base linux linux-firmware vim networkmanager

# FSTAB generation
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot configuration
echo "Configuring system inside chroot..."
arch-chroot /mnt /bin/bash -e <<EOF

# Set timezone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Generate locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "myhostname" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 myhostname.localdomain myhostname" >> /etc/hosts
systemctl enable NetworkManager

# Set root password
echo "root:password" | chpasswd

# Install and configure bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Unmount all partitions
echo "Unmounting all partitions..."
umount -R /mnt

# Reboot
echo "Rebooting..."
reboot

# After reboot you would run the following commands manually or script them similarly
# pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
# systemctl enable lightdm.service
# systemctl start lightdm.service

