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

## Install Starship

Needed for zsh.

Follow the [installation guide](https://starship.rs/guide/) to install Starship to make the terminal look awesome.

## Install Required Tools

### fzf

Follow the instructions on the [GitHub page](https://github.com/junegunn/fzf) to install fzf, a tool for fuzzy filename matching.

### Zoxide

Follow the instructions on the [GitHub page](https://github.com/ajeetdsouza/zoxide) to install Zoxide, a tool to enable shortcuts when changing directories.

## Install Optional Tools

### Eza

Follow the instructions on the [GitHub page](https://github.com/eza-community/eza/blob/main/INSTALL.md) to install Eza, a tool to replace the ls command.

### Micro

Follow the instructions on the [GitHub page](https://github.com/zyedidia/micro#package-managers) to install Micro, a modern simple text editor.

### Ripgrep

Needed for Neovim.

```zsh
brew install ripgrep
```

```zsh
sudo pacman -S ripgrep
```

### Fd

Needed for Neovim.

```zsh
brew install fd
```

```zsh
sudo pacman -S fd
```

### LazyGit

Needed for Neovim.

```zsh
brew install lazygit
```

```zsh
sudo pacman -S lazygit
```

### Treesitter CLI

Needed for Neovim.

```zsh
npm install tree-sitter-cli
```

## Install Tmux

Follow the instructions on the [GitHub wiki page](https://github.com/tmux/tmux/wiki/Installing) to install Tmux.

### Install Tmux Plugin Manager

```zsh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Install Dotfiles

If this repo is cloned into your home directory, `cd` into the dotfiles repo and run the `stow` command for each package you want to install.
```zsh
cd ~/dotfiles
stow zsh
stow iterm
stow tmux
stow nvm
```

In order to prevent symlinks from being made to entire folders, you can run (for example):
```zsh
stow --no-folding tmux
```

Otherwise, `cd` into the dotfiles folder and run:
```zsh
stow <package> --target=$HOME
```

## Syncing Changed Dotfiles

1. Commit any changes to dotfiles to the main branch of this repo.
2. On other computers, pull changes.

## Revert dotfiles to Originals

If you need to uninstall this repo, go to the dotfiles repo and run the delete command:

```zsh
cd ~/dotfiles
stow --delete <package>
```

## Adding New Dotfiles

1. Commit new files to the main branch.
2. On other computers, pull changes.
3. Run the stow install commands above.