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
# You can also choose linux, linux-lts, linux-hardened, linux-zen, or other.

KERNEL="linux-zen"

# Essential packages to run system. You shouldn't remove any of it.

PACKAGES="base linux-firmware cryptsetup grub efibootmgr mkinitcpio xterm networkmanager base-devel "
PACKAGES_CHAOTIC_AUR="yay librewolf"

# Aditional packages for your install.
# Note -  waterfox is instaled from AUR in aur_helper.sh script. Default AUR helper is yay
# If you wish to install soft from AUR, add it in aur_helper.sh
PACKAGES_UTILITIES="htop usbutils ntfs-3g zsh unzip i3 git xorg-xinit alacritty neovim python-pip wget flameshot openbsd-netcat chromium"

# These packages will make your installation pretty :)
PACKAGES_RICE="papirus-icon-theme acpi feh sysstat xorg network-manager-applet i3blocks i3status i3-gaps lxappearance-gtk3  rofi picom xss-lock dunst"

# You may want to remove something from this list if you, specially if you are installing BlackArch repos in VM.
PACKAGES_OPTIONAL="keepassxc yt-dlp chromium signal-desktop pulseaudio-bluetooth dmidecode qemu virt-manager virt-viewer qemu-full dnsmasq vde2 bridge-utils bluez-utils aom vlc sof-firmware pavucontrol"

# VM Packages - install if this will be VM installation
PACKAGES_VM="spice-vdagent"

# Driver for GPU
# See here available drivers
# https://wiki.archlinux.org/index.php/Xorg#Driver_installation

GPU_DRIVER="xf86-video-fbdev"
#GPU_DRIVER="nvidia-open-dkms mesa-utils"
# Place here your desired hostname

NAME="Arch"

# Your username

USERNAME="user"

# Groups to add for your user

GROUPS="libvirt"


TEMP_USERNAME=$USERNAME # Workaround for issues with passing variable to arch-chroot


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
    pacstrap /mnt $KERNEL $PACKAGES $PACKAGES_OPTIONAL $PACKAGES_UTILITIES  $PACKAGES_RICE $GPU_DRIVER $PACKAGES_VM
    echo -e "${BB}Generating fstab${CR}"
    genfstab -U /mnt >> /mnt/etc/fstab
    sed -i "s/relatime/relatime,discard/g" /mnt/etc/fstab
    echo -e "${BB}Enabling NetworkManager${CR}"
    arch-chroot /mnt systemctl enable NetworkManager
    arch-chroot /mnt systemctl start NetworkManager
    arch-chroot /mnt systemctl enable libvirtd
    arch-chroot /mnt systemctl start libvirtd
    arch-chroot /mnt systemctl enable bluetooth
    arch-chroot /mnt systemctl start bluetooth
    echo -e "${BB}Installing chaotic AUR${CR}"
    arch-chroot /mnt pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    arch-chroot /mnt pacman-key --lsign-key 3056513887B78AEB
    arch-chroot /mnt pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
    arch-chroot /mnt pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    echo "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /mnt/etc/pacman.conf
    arch-chroot /mnt pacman -Syu $PACKAGES_CHAOTIC_AUR --noconfirm


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
    arch-chroot /mnt grub-install --target=x86_64-efi $DISK --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    }

configure_system(){
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    arch-chroot /mnt echo -e $NAME > /etc/hostname
    echo -e "${BB} Change root password ${CR}"
    arch-chroot /mnt /bin/bash -c "echo '$ROOT_PASSWORD' | passwd root --stdin"
    
    echo -e "${BB} Setting root shel to zsh ${CR}"
    arch-chroot /mnt usermod -s /bin/zsh root


    echo -e "${BB} Change $USERNAME password${CR}"
    arch-chroot /mnt useradd -m -s /bin/zsh $USERNAME
    arch-chroot /mnt /bin/bash -c "echo '$USER_PASSWORD' | passwd '$USERNAME' --stdin"



    echo -e "${BB} Editing /etc/sudoers${CR}"
    echo "root ALL=(ALL) ALL
$USERNAME ALL=(ALL) ALL
Defaults insults" > /mnt/etc/sudoers
    
    arch-chroot /mnt usermod -a -G $GROUPS $USERNAME

    # Setup NTP
    echo -e "${BB} Setting up NTP${CR}"
    arch-chroot /mnt timedatectl set-ntp true


}


# Copy configs, etc.
# This will copy customize.sh and run it to finish instalation.
final_rice(){
echo -e "${BB}Adding final touch.${CR}"
cp customize.sh /mnt/home/$USERNAME
cp aur_helper.sh /mnt/home/$USERNAME
arch-chroot /mnt /bin/bash -c "echo '$USER_PASSWORD' | sudo -S -u '$TEMP_USERNAME' bash /home/'$TEMP_USERNAME'/customize.sh"
arch-chroot /mnt /bin/bash -c "echo '$USER_PASSWORD' | sudo -S  -u '$TEMP_USERNAME' bash /home/'$TEMP_USERNAME'/aur_helper.sh"
arch-chroot /mnt /bin/bash -c "echo '$USER_PASSWORD' | sudo -S rm /home/'$TEMP_USERNAME'/aur_helper.sh /home/'$TEMP_USERNAME'/customize.sh"
}

end(){
    echo -e "${BB}Instalation complete.${CR}"
    echo -e "${BB}You should now remove instalation media, and reboot${CR}"

}

get_secrets(){
    # This function is used to get interactivly input form user
    # We are geting Disk Encryption Key, User Password, Root password
    # DP - Disk passhprase > DISK_PASSPHRASE
    # UP - User password > USER_PASSWORD
    # RP - Root password > ROOT_PASSWORD
     DP1="X"
     UP1="X"
     RP1="X"

     until [[ $DP1 == $DP2 ]];do
        echo -e "${BB} Enter disk encryption passphrase: ${CR}"
        read -s DP1
        echo -e "${BB} Confirm your disk encryption passhprase: ${CR}"
        read -s DP2
        if [[ "$DP1" == "$DP2" ]];then
            DISK_PASSPHRASE=$DP2
        else
            echo -e "${BR} Passphrases are difrent! ${CR}"
        fi;
     done

        until [[ $UP1 == $UP2 ]];do
        echo -e "${BB} Enter $USERNAME password: ${CR}"
        read -s UP1
        echo -e "${BB} Confirm $USERNAME password: ${CR}"
        read -s UP2
        if [[ "$UP1" == "$UP2" ]];then
            USER_PASSWORD=$UP2
        else
            echo -e "${BR} Passwords for $USERNAME are difrent! ${CR}"
        fi;
     done

        until [[ $RP1 == $RP2 ]];do
        echo -e "${BB} Enter root password: ${CR}"
        read -s RP1
        echo -e "${BB} Confirm root password: ${CR}"
        read -s RP2
        if [[ "$RP1" == "$RP2" ]];then
            ROOT_PASSWORD=$RP2
        else
            echo -e "${BR} Passwords for root are difrent! ${CR}"
        fi;
        done



}

install_blackarch(){
    echo -e "${BB} Instaling BlackArch Repository ${CR}"
    cp strap_blackarch.sh /mnt/root/strap.sh
    arch-chroot /mnt bash /root/strap.sh
    arch-chroot /mnt sudo pacman -Syuu bind sublist3r subfinder httpx nuclei feroxbuster evil-winrm pidgin exploitdb sqlmap net-snmp php proxychains gobuster ysoserial openvpn smbclient ghidra ffuf seclists nmap netexec metasploit hashcat john patator impacket responder inetutils hcxdumptool hcxkeys hcxtools burpsuite bloodhound bloodhound-python perl-image-exiftool libvncserver freerdp remmina android-tools jadx wireshark-qt nfs-utils
    arch-chroot /mnt rm /root/strap.sh
    
}

install(){

    set_locals
    disk_partition
    get_secrets
    encrypt_disk
    chroot_and_install
    configure_system
    final_rice
    if $BLACKARCH;then install_blackarch;fi
    end
}

install
