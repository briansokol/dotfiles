# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Stow-based dotfiles management repository for cross-platform development environments (macOS and Linux/Wayland). Each top-level directory represents an independently installable "stow package" that creates symlinks to configuration files.

### Architecture Principles

- **Stow Package Pattern**: Each directory (zsh, nvim, tmux, etc.) can be installed independently via `stow <package>`
- **XDG Base Directory Compliance**: Configurations follow `package_name/.config/app_name/` structure
- **Cross-Platform Support**: Conditional loading based on platform detection (macOS vs Linux)
- **Theme Consistency**: Catppuccin color scheme used across Starship, Tmux, Waybar, and SwayOSD
- **Plugin-Based Management**: Zinit (Zsh), LazyVim (Neovim), TPM (Tmux) for modular configurations

## Common Commands

### Bootstrap (first-time install)
```bash
./bootstrap.sh                  # Detect OS, install package manifest, clone zinit/TPM, stow everything
./bootstrap.sh --no-packages    # Skip package install (stow + plugin bootstrap only)
./bootstrap.sh --packages-only  # Install packages, skip stow
./bootstrap.sh --macos|--arch|--ubuntu  # Override platform detection
```

The bootstrap script is idempotent (uses `stow --restow --no-folding`) and safe to re-run.
Package sets are arrays at the top of `bootstrap.sh` — `COMMON`, `MACOS_ONLY`, `LINUX_ONLY`.

### Stow Management
```bash
stow <package>                  # Install package by creating symlinks
stow --delete <package>         # Uninstall package
stow --no-folding <package>     # Prevent directory-level symlinks (creates file-level only)
```

### Dependency Updates
The `update-all` script ([zsh/.scripts/update-all-dependencies.sh](zsh/.scripts/update-all-dependencies.sh)) manages all system dependencies:

```bash
update-all                      # Update everything (Homebrew, npm, Zinit, Pacman, Yay, APT, Flatpak, uv tools)
update-all -h                   # Update only Homebrew (macOS)
update-all -n                   # Update only npm global packages
update-all -p                   # Update only Pacman (Arch Linux)
update-all -y                   # Update only Yay AUR packages
update-all -f                   # Update only Flatpak apps
update-all -z                   # Update only Zinit plugins
update-all -u                   # Update uv and global uv tools
update-all -c                   # Update Claude Code (claude update)
update-all -s                   # Install missing packages from Brewfile / packages/<distro>.txt / packages/flatpak.txt
update-all --sync-packages      # Same as -s (opt-in: prompts for sudo on Linux)
update-all --no-git-check       # Skip dotfiles repository update check
```

**Note:** `-s`/`--sync-packages` is intentionally opt-in (not part of the default `update-all` run)
because `sudo pacman -S --needed` / `sudo apt install` prompt for sudo every time.
Run it explicitly when you've added entries to a manifest.

**Important**: The script automatically checks for dotfiles updates before running package updates. If updates are found, it pulls them and exits (requiring shell restart).

### Git Workflow Helpers
```bash
merge-main                      # Merge origin/main into current branch (with git pull & fetch)
merge-main --dry-run            # Preview merge without executing
rebase-main                     # Rebase current branch onto origin/main (handles stash/restore)
rebase-main --dry-run           # Preview rebase without executing
gas                             # Git add all and show status
git-clean                       # Delete all merged branches
```

### Productivity Aliases
```bash
# Editor shortcuts
nv, vim                         # Open Neovim
nf                              # Fuzzy file search (fzf) + open in Neovim
mi                              # Open Micro editor (if installed)

# Package manager aliases (exact versions)
ni, nid                         # npm install --save-exact / --save-dev
ya, yad                         # yarn add --exact / --exact --dev
pa, pad                         # pnpm add --save-exact / --save-dev

# Enhanced directory listing
la                              # eza with git status, icons, and details (or ls -la fallback)
```

## Key Architectural Patterns

### Plugin Management Strategy

**Zsh (Zinit)**
- Fast, async plugin manager replacing Oh-My-Zsh
- Lazy-loads Oh-My-Zsh snippets for git, npm, nvm, gh, brew, sudo, node
- Plugins: zsh-syntax-highlighting, zsh-completions, zsh-autosuggestions, fzf-tab
- Auto-updates via `update-all -z`

**Neovim (LazyVim)**
- Minimal configuration that delegates to LazyVim framework
- Structure: `lua/config/` for core settings, `lua/plugins/` for plugin overrides
- Requires: ripgrep, fd, lazygit, tree-sitter-cli

**Tmux (TPM)**
- Catppuccin mocha theme
- Plugin manager: [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- Installation: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

**SwayOSD (Linux/Wayland)**
- On-screen display daemon for volume, brightness, and system controls
- Catppuccin mocha theme with custom styling
- Config: [swayosd/.config/swayosd/config.toml](swayosd/.config/swayosd/config.toml)
- Styling: [swayosd/.config/swayosd/style.css](swayosd/.config/swayosd/style.css)
- Provides visual feedback for hardware controls in Wayland compositors

### Shell Integration Ecosystem

**Critical Integrations** (defined in [zsh/.zshrc](zsh/.zshrc)):

1. **Starship Prompt**: Fast, language-aware prompt (Catppuccin macchiato theme)
   - Config: [starship/.config/starship.toml](starship/.config/starship.toml)
   - Shows git status, language versions (Node, Python, Go, Rust, etc.)

2. **NVM Auto-Switching**: Automatically loads Node version from `.nvmrc` files
   - Triggers on directory change via zsh hook
   - Falls back to default version when leaving project

3. **fzf Integration**: Fuzzy finder with tab completion and file preview
   - Custom completion for `cd` and `zoxide` commands
   - Preview window shows directory contents

4. **Zoxide**: Smart directory jumping with cd wrapper
   - Falls back to builtin cd if zoxide function unavailable

### Configuration Structure

```
package_name/
└── .config/
    └── app_name/
        └── config_files
```

**XDG Environment Variables** (set in .zshrc):
```bash
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
```

## Development Patterns

### Dotfiles Sync Workflow

1. **Before Changes**: Commit dotfiles to main branch
2. **On Other Machines**:
   - Pull changes: `cd ~/dotfiles && git pull`
   - Re-run stow: `stow <package>`
3. **Automatic Sync**: `update-all` checks for dotfiles updates before package updates
   - Uses fast-forward pull if no local commits
   - Uses rebase if local commits exist
   - Exits early if updates found (shell restart required)

### Multi-Platform Support

**Platform Detection Pattern**:
```bash
# Homebrew on macOS
if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Tool availability checks
if (( $+commands[eza] )); then
  alias ls='eza --icons=always --group-directories-first'
else
  alias ls='ls --color'
fi
```

**Platform-Specific Packages**:
- **macOS**: aerospace (window manager), iterm, sketchybar
- **Linux/Wayland**: hyprland (window manager), waybar, wofi, swaync, swayosd, ghostty

### Git Branch Management

**merge-main and rebase-main Scripts**:
- Auto-detect main vs master branch
- Support `--dry-run` flag for safety
- Handle stash/restore during rebase automatically
- Support custom branch targets: `merge-main --branch develop`

## Special Considerations

### NVM Automatic Version Switching

The `.zshrc` includes a `chpwd` hook that automatically runs `nvm use` when:
- Entering a directory with `.nvmrc` file
- Leaving a project (switches back to default version)
- No manual intervention required

### Update Script Intelligence

**Key Behaviors** ([update-all-dependencies.sh](zsh/.scripts/update-all-dependencies.sh)):
- **Git Self-Update**: Checks dotfiles repo first, pulls if behind, exits for shell restart
- **Separate Official/AUR Updates**: pacman always handles official-repo packages; yay handles AUR only, upgrading in a single `-Sua` sysupgrade while showing each PKGBUILD diff and prompting for review/approval natively. The sysupgrade fires yay's `UpgradeSelect` Lua hook, which warns when an AUR package's maintainer has changed (see "yay maintainer-change hook" below)
- **NVM Multi-Version Updates**: Loops through all installed Node versions, updates global packages per version
- **Default Packages**: Installs missing packages from `~/.nvm/default-packages`
- **Dependencies**: Requires `jq` for npm updates (JSON parsing)

### Stow Best Practices

1. **Run from correct directory**: `cd ~/dotfiles` before running stow
2. **Use --no-folding**: Prevents entire directory symlinks, creates file-level symlinks only
3. **Custom target**: Use `stow <package> --target=$HOME` if repo is not in home directory

## Required Tools

`bootstrap.sh` installs these from the package manifests. Listed here for reference / manual installs:

**Core Dependencies**:
- GNU Stow - Symlink management
- Starship - Shell prompt
- fzf - Fuzzy finder
- Zoxide - Directory jumping
- atuin - Magical shell history (Ctrl-R; replaces fzf's default Ctrl-R widget)
- git-delta - Pager for `git diff`/`git log` (wired in `git/.gitconfig`)
- bat - Syntax-highlighted `cat`; theme cache built by bootstrap.sh
- btop - System monitor

**Optional but Recommended**:
- eza - Modern ls replacement
- ripgrep, fd, lazygit - For Neovim
- tree-sitter-cli - For Neovim syntax highlighting
- jq - For npm update script
- micro - Modern terminal text editor

## Package Manifests

Declarative lists of what should be installed per platform — kept in sync by `bootstrap.sh`
and (optionally) `update-all -s`:

| File | Platform | Tool |
|------|----------|------|
| `Brewfile` | macOS | `brew bundle install --file=Brewfile` |
| `packages/arch.txt` | Arch | `pacman -S --needed` |
| `packages/aur.txt` | Arch | `yay -S --needed` |
| `packages/ubuntu.txt` | Ubuntu/Debian | `apt-get install -y` |
| `packages/flatpak.txt` | Linux (any) | `flatpak install flathub` (reverse-DNS app IDs) |

Ubuntu's apt is intentionally sparse — `bootstrap.sh` installs `starship`/`atuin` via their
official install scripts and warns about `lazygit`/`git-delta`/`btop`/`eza` (which often
aren't packaged on recent Ubuntu LTS). The script also symlinks `~/.local/bin/bat` → `batcat`
and `~/.local/bin/fd` → `fdfind` so configs that reference the upstream binary names work.

## btop config (theme-only stow)

The `btop/` stow package ships **only** the Catppuccin Mocha theme file, not
`btop.conf`. Reason: btop rewrites its own config on exit, which would dirty
the dotfiles repo every time you run btop. Set the theme once by editing the
real `~/.config/btop/btop.conf` (or via btop's options menu → `O`):

```
color_theme = "catppuccin_mocha"
```

## yay maintainer-change hook (Linux/Arch)

The `yay/` stow package ships a single Lua hook, [yay/.config/yay/init.lua](yay/.config/yay/init.lua),
loaded automatically by yay v13+ from `~/.config/yay/init.lua`. It registers an
`UpgradeSelect` autocmd that fires on every `yay -Syu` / `yay -Sua` and warns
(via `yay.log.error`) when an AUR package's maintainer has changed since the last
upgrade. This guards against AUR package hijacking / ownership handoffs.

- **State**: last-seen maintainer per package is cached at
  `${XDG_CACHE_HOME:-~/.cache}/yay/maintainer_cache` (`pkgname=maintainer` per line).
- **First upgrade** of a package seeds the cache silently; **subsequent** upgrades
  compare and warn on mismatch, then update the cache.
- The hook is a near-verbatim copy of yay's upstream `doc/examples/maintainer_change.lua`.
- Requires yay ≥ v13 (the release that added the Lua hook system). It fires during
  a full sysupgrade, which is why `update-all` upgrades the AUR via `yay -Sua`
  rather than per-package `yay -S <pkg>`.
- `yay` is a Linux-only stow package (in `LINUX_ONLY` in `bootstrap.sh`).

## Shell History (atuin)

Atuin replaces the default Ctrl-R history search. The `.zshrc` initialization uses
`--disable-up-arrow` so the Up key continues to do normal Zsh history search.
The init block must run **after** the `fzf --zsh` source so atuin's Ctrl-R binding wins.

Per-machine sync (E2E-encrypted) is opt-in: run `atuin register` or `atuin login` on each
machine. The encryption key is not checked into this repo.

`bootstrap.sh` runs `atuin import auto` once per machine to ingest existing `~/.zsh_history`.
