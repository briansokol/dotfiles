# dotfiles

Cross-platform dotfiles for **macOS**, **Arch Linux**, and **Ubuntu/Debian**, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start

On a fresh machine:

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` is idempotent — re-run it any time. It will:

1. Detect the OS (override with `--macos` / `--arch` / `--ubuntu`).
2. Install the matching package manifest:
   - macOS → [`Brewfile`](Brewfile) via `brew bundle`
   - Arch → [`packages/arch.txt`](packages/arch.txt) + [`packages/aur.txt`](packages/aur.txt)
   - Ubuntu → [`packages/ubuntu.txt`](packages/ubuntu.txt) (with fallbacks for tools that aren't in apt — see comments at the top of that file)
3. Clone plugin managers: [zinit](https://github.com/zdharma-continuum/zinit) for Zsh, [TPM](https://github.com/tmux-plugins/tpm) for tmux.
4. Stow the right package set with `--restow --no-folding`.
5. Build the `bat` theme cache, import existing Zsh history into `atuin`, and `chmod +x` the helper scripts.

Useful flags:

```sh
./bootstrap.sh --no-packages    # stow + plugin bootstrap only (no sudo/brew)
./bootstrap.sh --packages-only  # install packages, skip stow
./bootstrap.sh -h               # all flags
```

LazyVim self-installs on first `nvim` launch.

## Manual / partial install

If you'd rather skip the bootstrap and only install some packages:

```sh
cd ~/dotfiles
stow --no-folding zsh tmux nvim git atuin   # whichever you want
```

To uninstall a package's symlinks:

```sh
stow --delete <package>
```

## Packages

Cross-platform (always stowed): `zsh nvim tmux starship nvm micro ghostty yazi rofi claude git atuin bat lazygit btop`

macOS only: `iterm aerospace sketchybar`

Linux/Wayland only: `hyprland waybar wofi swaync swayosd`

(`p10k` is in the repo for reference but unused — Starship is the active prompt.)

## Keeping things up to date

```sh
update-all                  # update everything (zinit, brew/apt/pacman/yay, npm globals)
update-all --sync-packages  # also install anything new from the manifests
update-all -h               # show all flags
```

`update-all` self-checks for new commits in `~/dotfiles` first — if found, it pulls them and exits so you can restart your shell.

## Per-machine overrides

- `~/.local_env` — shell secrets/env vars (sourced from `.zshrc`; not in the repo).
- `~/.gitconfig.local` or `~/.gitconfig-work` — git identity overrides (see comments in [`git/.gitconfig`](git/.gitconfig)).
- `atuin` sync — run `atuin register` / `atuin login` per machine; the encryption key isn't checked in.

## Theme

Catppuccin Mocha across the board (with Macchiato for Starship): tmux, bat, delta, fzf, atuin, lazygit, btop, waybar, swaync, swayosd, rofi, yazi, micro, ghostty.

## Layout

```
dotfiles/
├── bootstrap.sh           # one-shot installer
├── Brewfile               # macOS package manifest
├── packages/              # Linux package manifests
│   ├── arch.txt
│   ├── aur.txt
│   └── ubuntu.txt
├── zsh/                   # one directory per stow package
│   ├── .zshrc             # → ~/.zshrc
│   └── .scripts/
│       ├── update-all-dependencies.sh
│       ├── merge-main.sh
│       └── rebase-main.sh
├── nvim/.config/nvim/...  # → ~/.config/nvim/...
└── ...
```
