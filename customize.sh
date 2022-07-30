#!/bin/sh
# Inspired by xct https://github.com/xct/kali-clean/blob/main/install.sh

USERNAME=`whoami`
PACKAGES_CATALOG="/opt/packages"

install_fonts(){
    cd ~
    mkdir -p ~/.local/share/fonts/
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
    unzip Iosevka.zip -d ~/.local/share/fonts/
    unzip RobotoMono.zip -d ~/.local/share/fonts/
    fc-cache -fv
    rm Iosevka.zip; rm RobotoMono.zip
    }

copy_config(){
    echo "Cloning dotfiles"
    git clone https://github.com/4ndrz3j/dotfiles git/dotfiles
    cp ~/git/dotfiles/zprofile ~/.zprofile
    ln -s ~/git/dotfiles/ ~/.config
    #Making scripts executable
    chmod +x ~/.config/i3/i3blocks_scripts/*
}


install_software(){
    echo "Installing OhMyZsh"
    ZSH="$HOME/.config/zsh/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # Removing original config and replacing with our
    rm ~/.zshrc ~/.zshrc.pre-oh-my-zsh
    ln -s ~/git/dotfiles/zsh/zshrc ~/.zshrc


    sudo mkdir $PACKAGES_CATALOG; sudo chown $USERNAME:root $PACKAGES_CATALOG
    echo "Installing Librewolf"
    gpg --recv-keys 2954CC8585E27A3F
    git clone https://aur.archlinux.org/librewolf-bin.git $PACKAGES_CATALOG/librewolf-bin
    cd $PACKAGES_CATALOG/librewolf-bin && makepkg -si

    echo "Installing xcwd"
    git clone https://github.com/schischi/xcwd $PACKAGES_CATALOG/xcwd
    cd $PACKAGES_CATALOG/xcwd && make; sudo make install
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
    }

# Make sure that we are operating on our home catalog
export HOME=/home/$USERNAME

copy_config
install_fonts
install_software

echo "Done!"
