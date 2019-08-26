# dotfiles
My linux dotfiles.

## How to setup a new pc
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
