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

install_fonts(){
    cd ~
    mkdir -p ~/.local/share/fonts/
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
    unzip Iosevka.zip -d ~/.local/share/fonts/
    fc-cache -fv
    rm Iosevka.zip;
    }


copy_config
install_fonts

echo "Done!"
