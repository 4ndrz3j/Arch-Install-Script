 #!/bin/bash
# 29.03.2021
# For UEFI/EFI systems
# Inspired by https://www.unixsheikh.com/tutorials/real-full-disk-encryption-using-grub-on-arch-linux-for-bios-and-uefi.html
# Thanks for Archwiki


CR='\033[0m'    # Color reset
BB='\033[1;34m' # Bold blue
BR='\033[1;31m' # Bold red
BY='\033[1;33m' # Bold yellow


# Disk to install Arch on. Probably something like /dev/sda, or /dev/vda

DISK="/dev/vda"

# Place here your desired kernel.
# You can also choose linux-lts, linux-hardened, linux-zen, or other.

KERNEL="linux-zen"

# Essential packages to run system. You shouldn't remove any of it.

PACKAGES="base linux-firmware cryptsetup grub efibootmgr mkinitcpio xterm networkmanager"

# Aditional packages for your install.

PACKAGES_RICE="arc-gtk-theme sysstat base-devel zsh xorg unzip i3 git xorg-xinit alacritty network-manager-applet neovim feh i3blocks pavucontrol i3status i3-gaps rofi picom python-pip wget xss-lock"
PACKAGES_OPTIONAL="signal-desktop chromium flameshot dunst papirus-icon-theme pulseaudio-bluetooth lxappearance-gtk3 qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat"

# Driver for GPU
# See here available drivers
# https://wiki.archlinux.org/index.php/Xorg#Driver_installation

GPU_DRIVER="xf86-video-fbdev"

# Place here your desired hostname

NAME="Arch"

# Your username

USERNAME="user"
TEMP_USERNAME=$USERNAME # Workaround for issues with passing variable to arch-chroo


# Install BlackArch repos?

BLACKARCH=false

echo -e """
${BB}This script is going to create two partitions,
sda1 for efi bootloader, and sda2 for root.
It's meant to be use with UEFI setup on SSD drive.
Make sure that you read whole script. There is preety long
sleep, to make sure, that you wont pipe this script to bash 
directly${CR}
"""
echo -e "${BR}Nothing will be done, until you will edit this script ${CR}"
# You need to remove this exit, make sure that you read everything carefuly (if
# you are doing this on physical machine).
exit

# Localization options & ntp
# 1 - GUID
# 2 - Linux FS x86_64
set_locals(){
    echo -e "${BB}Loading polish keyboard layout${CR}"
    loadkeys pl
    echo -e "${BB}ęśąćż${CR}"
    echo -e "${BB}Loading polish font ${CR}"
    setfont Lat2-Terminus16.psfu.gz -m 8859-2
    echo -e "${BB}Seting NTP${CR}"
    timedatectl set-ntp true
}



# Disk paritioning
# Meant for 500 GB SSD / efi/uefi
# /dev/sdxY - /boot - FAT32/vfat. Partition type EFI System C12A7...93B
# /dev/sdxZ - / - ext4. Partition type Linux root 03849...709



disk_partition(){
    echo -e "${BB}Creating label gpt for $DISK ${CR}"
    parted $DISK mklabel gpt -s
    echo -e "${BB}Creating 1 partition 261MiB ${CR}"
    parted $DISK mkpart fat32 1MiB 261MiB
    parted $DISK set 1 esp on
    echo -e "${BB}Creating second partition${CR}"
    parted $DISK mkpart ext4 261MiB 100%
}

# Encrypt disks
encrypt_disk(){
    echo -e "${BY} Encrypting Disk ${CR}"
    echo -n $DISK_PASSPHRASE | cryptsetup luksFormat --type luks1 $DISK'2' -d -
    echo -n $DISK_PASSPHRASE | cryptsetup open $DISK'2' cryptlvm -d -
    echo -e "${BB} Creating filesystem ${CR}"
    mkfs.ext4 /dev/mapper/cryptlvm
    mount /dev/mapper/cryptlvm /mnt
    mkfs.fat -F32 $DISK'1'
    mkdir /mnt/boot/efi -p
    mount $DISK'1' /mnt/boot/efi

}

# Chroot and install software
# Change Kernel to desired version
chroot_and_install(){
    echo -e "${BB}Installing packages now${CR}"
    pacstrap /mnt $KERNEL $PACKAGES $PACKAGES_OPTIONAL $PACKAGES_RICE $GPU_DRIVER
    echo -e "${BB}Generating fstab${CR}"
    genfstab -U /mnt >> /mnt/etc/fstab
    sed -i "s/relatime/relatime,discard/g" /mnt/etc/fstab
    echo -e "${BB}Enabling NetworkManager${CR}"
    arch-chroot /mnt systemctl enable NetworkManager
    arch-chroot /mnt systemctl start NetworkManager
    arch-chroot /mnt systemctl enable libvirtd
    arch-chroot /mnt systemctl start libvirtd


# Copy key, to avoid typing passphrase two times on boot.
    echo -e "${BB}Creating keyfile${CR}"
    arch-chroot /mnt dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
    echo -n $DISK_PASSPHRASE |cryptsetup luksAddKey $DISK'2' /mnt/crypto_keyfile.bin -d -
    arch-chroot /mnt chmod 000 /crypto_keyfile.bin


    echo -e "${BB}Editing /etc/mkinitcpio.conf${CR}"
    arch-chroot /mnt sed -i "s/^HOOKS=(.*)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
    arch-chroot /mnt sed -i "s/^FILES=()/FILES=(\/crypto_keyfile.bin)/g" /etc/mkinitcpio.conf
    echo -e "${BB}Creating ramdisk${CR}"
    # If you choose linux-lts, change linux to linux-lts, after -p
    arch-chroot /mnt mkinitcpio -p $KERNEL



# vi /etc/default/grub
    echo -e "${BB}Adding boot device to grub ${CR}"
    arch-chroot /mnt sed -i "s@^GRUB_CMDLINE_LINUX=.*@GRUB_CMDLINE_LINUX=\"cryptdevice="$DISK"2:cryptroot:allow-discards\"@g" /etc/default/grub
    echo -e "${BB}Enabling crypto in grub${CR}"
    arch-chroot /mnt sed -i "s/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/g" /etc/default/grub
    arch-chroot /mnt grub-install --target=x86_64-efi $DISK --recheck
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    }

configure_system(){
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    arch-chroot /mnt echo -e $NAME > /etc/hostname
    echo -e "${BB} Change root password ${CR}"
    arch-chroot /mnt passwd
    
    echo -e "${BB} Setting root shel to zsh ${CR}"
    arch-chroot /mnt usermod -s /bin/zsh root


    echo -e "${BB} Change $USERNAME password${CR}"
    arch-chroot /mnt useradd -m -s /bin/zsh $USERNAME
    arch-chroot /mnt passwd $USERNAME
    
    echo -e "${BB} Editing /etc/sudoers${CR}"
    echo "root ALL=(ALL) ALL
$USERNAME ALL=(ALL) ALL
Defaults insults" > /mnt/etc/sudoers


}


# Copy configs, etc.
# This will copy customize.sh and run it to finish instalation.
final_rice(){
echo -e "${BB}Adding final touch.${CR}"
cp customize.sh /mnt/home/$USERNAME
arch-chroot /mnt sudo -u $TEMP_USERNAME bash /home/$TEMP_USERNAME/customize.sh
}

end(){
    echo -e "${BB}Instalation complete.${CR}"
    echo -e "${BB}You should now remove instalation media, and reboot${CR}"

}

get_disk_pass(){
     echo -e "${BB} Enter disk encryption passphrase: ${CR}"
     read -s PASS1
     echo -e "${BB} Confirm your passhprase: ${CR}"
     read -s PASS2
     if [[ "$PASS1" == "$PASS2" ]];then
        DISK_PASSPHRASE=$PASS1
        return
     else
          echo -e "${BR} Passphrases are difrent! ${CR}"
          get_disk_pass
     fi
}

install_blackarch(){
    echo -e "${BB} Instaling BlackArch Repository ${CR}"
    curl -O https://blackarch.org/strap.sh
    cp strap.sh /mnt/root/strap.sh
    arch-chroot /mnt bash /root/strap.sh
    arch-chroot /mnt sudo pacman -Syu

}

install(){

    set_locals
    disk_partition
    get_disk_pass
    encrypt_disk
    chroot_and_install
    configure_system
    final_rice
    if $BLACKARCH;then install_blackarch;fi
    end
}

install
