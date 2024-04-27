#!/bin/bash
# Inspired by xct https://github.com/xct/kali-clean/blob/main/install.sh

USERNAME=`whoami`

# Make sure that we are operating on our home catalog
export HOME=/home/$USERNAME


copy_config(){
    echo "Cloning dotfiles"
    cd ~
    git clone https://github.com/4ndrz3j/dotfiles git/dotfiles
    cp ~/git/dotfiles/zprofile ~/.zprofile
    ln -s ~/git/dotfiles/ ~/.config
    #Making scripts executable
    chmod +x ~/.config/i3/i3blocks_scripts/*
    ln -s ~/git/dotfiles/zsh/.zshrc ~/.zshrc
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME

}


copy_config

echo "Done!"
