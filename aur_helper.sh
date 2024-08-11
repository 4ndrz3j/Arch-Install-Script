#!/bin/bash

# This script will install yay, as pacman wrapper, to make life easier with aur.


USERNAME=`whoami`

# Make sure that we are operating on our home catalog
export HOME=/home/$USERNAME

install_yay(){
    
    echo "Installing yay-bin"
    cd ~
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si
    cd ~
    rm -rf yay-bin
}


install_software(){
    ln -s ~/git/dotfiles/zsh/.zshrc ~/.zshrc

    yay -Syuu aur/waterfox-bin aur/xcwd  

    chown -R $USERNAME:$USERNAME /home/$USERNAME
    }

install_yay
install_software

echo "Done!"
