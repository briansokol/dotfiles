# dotfiles

All my dotfiles, ready to be installed and synced with Stow.

## Install Stow

Mac using Homebrew:

```zsh
brew install stow
```

Debian/Ubuntu using apt:

```zsh
sudo apt update
sudo apt install stow
```

Fedora, RHEL, or CentOS using Yum:

```zsh
sudo yum install stow
```

Or using DNF:
```zsh
sudo dnf install stow
```

Arch Linux (and maybe Git Bash) using Pacman:
```zsh
sudo pacman -S stow
```

## Install fzf

Follow the instructions on the [GitHub page](https://github.com/junegunn/fzf) to install fzf.

## Install Zoxide

Follow the instructions on the [GitHub page](https://github.com/ajeetdsouza/zoxide) to install Zoxide.

## Install Dotfiles

If this repo is checked out into your home directory, `cd` into the dotfiles repo and run the `stow` command for each package you want to install.
```zsh
cd ~/dotfiles
stow zsh
stow ghostty
stow nvm
```

Otherwise, `cd` into the dotfiles folder and run:
```zsh
stow <package> --target=$HOME
```

## Syncing Changed Dotfiles

1. Commit any changes to dotfiles to the main branch of this repo.
2. On other computers, pull changes.

## Revert dotfiles to Originals

If you need to uninstall this repo:

```zsh
cd ~
stow --delete
```

## Adding New Dotfiles

1. Commit new files to the main branch.
2. On other computers, pull changes.
3. Run the stow install commands above.