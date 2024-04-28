#!/bin/bash
# Inspired by xct https://github.com/xct/kali-clean/blob/main/install.sh

USERNAME=`whoami`

# Make sure that we are operating on our home catalog
export HOME=/home/$USERNAME




install_sway(){

    yay -Syu swaycwd waybar swaylock swaybr

    }


install_sway

echo "Done!"
