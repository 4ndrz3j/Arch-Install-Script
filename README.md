
> This install script is designed to work with my config files. You can find them
[here](https://github.com/4ndrz3j/dotfiles)


# Install

First run **install_arch.sh**. Read config and make a proper changes for your
setup.

## Main Packages
| Purpouse          | Package Name  |
|-------------------|-------------- |
| Shell             | zsh           |
| Terminal Emulator | Alacritty     |
| Window manager    | i3wm          |
| Image Viewer      | feh           |
| Status Bar        | i3blocks      |
| dmenu replacment  | Rofi          |
| Web Browser       | Waterfox + Chromium     |
| Text Editor       | neovim        |
| Theme             | Arc Dark      |
| Icons		        | ePapirus-Dark |
| Fonts             | Iosevka|
| Audio             | PulseAudio + pavucontrol|
| Screenshot app    | Flameshot     |
| Notification daemon| dunst        |
| Pacman Wraper / AUR helper | yay |


## Browsers

Main browser is [Waterfox](https://www.waterfox.net/), secondary is [Chromium](https://wiki.archlinux.org/title/chromium).

In the past I used [Librewolf](https://librewolf.net/), but there were some problems with instaling this on Arch. 

## Startup/Shutdown files

*.zprofile* and *.zlogout* is intended to use for startup/shutdown files.

## Display/login manager

There is no standard display manager. i3 is stared using ```.zprofile```

## Opacity

Opacity is achived using picom

## WebCam

[Webcam insttall repo](https://github.com/stefanpartheym/archlinux-ipu6-webcam)

# BlackArch

You can install BlackArch repos by setting variable *BLACKARCH* to ```true```

# Nvidia packages

To run applicaiotns with nvidia gpu, use ```prime-run```, for example: 
```prime-run steam```
