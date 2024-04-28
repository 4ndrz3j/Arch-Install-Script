
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
| Window manager    | sway          |
| Image Viewer      | TODO           |
| Status Bar        | waybar      |
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

## Windows managers

In the past i used i3wm, but now i migrated to sway. But you can still install sway.

## Browsers

Main browser is [Waterfox](https://www.waterfox.net/), secondary is [Chromium](https://wiki.archlinux.org/title/chromium).

In the past I used [Librewolf](https://librewolf.net/), but there were some problems with instaling this on Arch. 

## Startup/Shutdown files

*.zprofile* and *.zlogout* is intended to use for startup/shutdown files.

## Display/login manager

There is no standard display manager. sway is stared using ```.zprofile```

# BlackArch

You can install BlackArch repos by setting variable *BLACKARCH* to ```true```
