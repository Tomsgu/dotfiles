# Tomsgu dotfiles

## Setup a new pc
```sh
# clone the rep
git clone --bare git@github.com:Tomsgu/dotfiles.git $HOME/.dotfiles
```

```sh
# Make an alias to use the $HOME directory.
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

```sh
# Don't show untracked files 
dotfiles config --local status.showUntrackedFiles no
```  

```sh
# Checkout content from the git repository.
dotfiles checkout
```

* Instead of using `git` to work with the repository use `dotfiles` alias.

## To install
* waybar
* zsh + oh-my-zsh
* powerline fonts
* git
* `blueberry` for bluetooth + bluez.  
* aerc, w3m, dante - email client + programs to read html
* dmenu
* vim-plug: `curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`
* ssh
* pulseaudio, pavucontrol, pulseaudio-alsa, alsa-utils

## Programs independent of this config
* `jetbrains-toolbox`
* brave
* steam
* skype
* spotify
* libreoffice
* shotwell
* evince
* neovim

## TODO
* add environment variables e.g. ~/.config/environment.d/sway.conf
_JAVA_AWT_WM_NONREPARENTING=1
CLUTER_BACKEND=wayland
EDITOR=vim
SDL_VIDEODRIVER=wayland

isync since version 1.5 respects XDG base dir. See https://sourceforge.net/p/isync/feature-requests/14/
  the version is not yet released.

