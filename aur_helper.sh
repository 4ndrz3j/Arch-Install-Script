#!/bin/bash

# This script will install yay, as pacman wrapper, to make life easier with aur.


USERNAME=`whoami`

# Make sure that we are operating on our home catalog
export HOME=/home/$USERNAME

install_software(){

    yay -Syuu --noprovides --answerdiff None --answerclean None --mflags "--noconfirm" aur/xcwd  

    }

install_software

echo "Done!"
