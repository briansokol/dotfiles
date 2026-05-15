# dotfiles project overview
- Purpose: cross-platform dotfiles repo managed with GNU Stow for macOS, Arch Linux, and Ubuntu/Debian.
- Structure: top-level directories are stow packages such as zsh, nvim, tmux, hyprland, waybar, swaync, swayosd.
- Platforms: Linux/Wayland packages include hyprland, waybar, wofi, swaync, swayosd; macOS packages include aerospace, iterm, sketchybar.
- Bootstrap: `./bootstrap.sh` installs packages, clones plugin managers, and stows packages with `--restow --no-folding`.
- Theme: Catppuccin Mocha is used broadly across terminal and Wayland tools.
