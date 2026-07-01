#!/usr/bin/env bash
# bootstrap.sh — one-shot, idempotent dotfiles installer for macOS / Arch / Ubuntu.
#
# Detects OS, installs packages from the matching manifest (Brewfile / packages/<distro>.txt),
# bootstraps plugin managers (zinit, TPM), and stows the right package set with
# `stow --restow --no-folding` so re-running is safe.
#
# Usage:
#   ./bootstrap.sh                    # auto-detect platform, full install
#   ./bootstrap.sh --no-packages      # skip package install (stow + plugin bootstrap only)
#   ./bootstrap.sh --packages-only    # only install packages
#   ./bootstrap.sh --macos | --arch | --ubuntu   # override platform detection
#   ./bootstrap.sh -h | --help

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants & helpers
# ---------------------------------------------------------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Stow package sets. p10k is intentionally excluded (disabled in .zshrc).
COMMON=(zsh nvim tmux starship nvm micro ghostty yazi rofi claude git atuin bat lazygit btop)
MACOS_ONLY=(aerospace sketchybar)
LINUX_ONLY=(hyprland waybar swaync swayosd yay)

# Colors
if [[ -t 1 ]]; then
    BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
    RED='\033[1;31m'; DIM='\033[2m'; RESET='\033[0m'
else
    BLUE=''; GREEN=''; YELLOW=''; RED=''; DIM=''; RESET=''
fi

print_section() { printf "\n${BLUE}== %s ==${RESET}\n" "$1"; }
print_info()    { printf "${DIM}  • %s${RESET}\n" "$1"; }
print_success() { printf "${GREEN}  ✓ %s${RESET}\n" "$1"; }
print_warning() { printf "${YELLOW}  ! %s${RESET}\n" "$1"; }
print_error()   { printf "${RED}  ✗ %s${RESET}\n" "$1" >&2; }
print_skip()    { printf "${DIM}  ⊘ %s${RESET}\n" "$1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Read a manifest file: strip comments + blank lines, emit non-empty tokens.
read_manifest() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    grep -vE '^\s*(#|$)' "$file"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

OS_OVERRIDE=""
SKIP_PACKAGES=0
PACKAGES_ONLY=0

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --macos)         OS_OVERRIDE="macos" ;;
        --arch)          OS_OVERRIDE="arch" ;;
        --ubuntu)        OS_OVERRIDE="ubuntu" ;;
        --no-packages)   SKIP_PACKAGES=1 ;;
        --packages-only) PACKAGES_ONLY=1 ;;
        -h|--help)       usage 0 ;;
        *)               print_error "Unknown flag: $1"; usage 1 ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

detect_os() {
    if [[ -n "$OS_OVERRIDE" ]]; then
        echo "$OS_OVERRIDE"; return
    fi
    case "$(uname -s)" in
        Darwin) echo "macos"; return ;;
        Linux)  ;;
        *) print_error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        local id="${ID:-}${ID_LIKE:+ ${ID_LIKE}}"
        case " $id " in
            *arch*|*manjaro*|*endeavouros*) echo "arch"; return ;;
            *ubuntu*|*debian*|*pop*|*mint*) echo "ubuntu"; return ;;
        esac
    fi
    print_error "Could not detect Linux distro. Use --arch or --ubuntu."
    exit 1
}

OS="$(detect_os)"

# ---------------------------------------------------------------------------
# Prerequisites per platform
# ---------------------------------------------------------------------------

ensure_prereqs_macos() {
    print_section "Prerequisites (macOS)"
    if ! command_exists brew; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # shellenv for current shell
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        print_success "Homebrew installed."
    else
        print_skip "Homebrew already installed."
    fi
    brew install stow git
}

ensure_prereqs_arch() {
    print_section "Prerequisites (Arch)"
    sudo pacman -S --needed --noconfirm base-devel git stow
    if ! command_exists yay; then
        print_info "Building yay from AUR..."
        local tmp; tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        print_success "yay installed."
    else
        print_skip "yay already installed."
    fi
}

ensure_prereqs_ubuntu() {
    print_section "Prerequisites (Ubuntu/Debian)"
    sudo apt-get update
    sudo apt-get install -y build-essential git stow curl ca-certificates
}

# ---------------------------------------------------------------------------
# Package installation from manifests
# ---------------------------------------------------------------------------

install_packages_macos() {
    print_section "Installing packages (Brewfile)"
    if [[ ! -f "$REPO_DIR/Brewfile" ]]; then
        print_warning "No Brewfile at $REPO_DIR/Brewfile — skipping."
        return
    fi
    brew bundle install --file="$REPO_DIR/Brewfile"
}

install_packages_arch() {
    print_section "Installing packages (pacman + yay)"
    local pkgs
    if mapfile -t pkgs < <(read_manifest "$REPO_DIR/packages/arch.txt") && (( ${#pkgs[@]} > 0 )); then
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    fi
    if mapfile -t pkgs < <(read_manifest "$REPO_DIR/packages/aur.txt") && (( ${#pkgs[@]} > 0 )); then
        yay -S --needed --noconfirm "${pkgs[@]}"
    fi
}

install_packages_ubuntu() {
    print_section "Installing packages (apt)"
    local pkgs
    if mapfile -t pkgs < <(read_manifest "$REPO_DIR/packages/ubuntu.txt") && (( ${#pkgs[@]} > 0 )); then
        sudo apt-get install -y "${pkgs[@]}"
    fi

    # Ubuntu binary aliases (apt names differ from upstream)
    mkdir -p "$HOME/.local/bin"
    if command_exists batcat && ! command_exists bat; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        print_success "Linked ~/.local/bin/bat -> batcat."
    fi
    if command_exists fdfind && ! command_exists fd; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        print_success "Linked ~/.local/bin/fd -> fdfind."
    fi

    # Tools commonly missing or stale in apt — install from official sources if absent.
    if ! command_exists starship; then
        print_info "Installing starship from upstream..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
    if ! command_exists atuin; then
        print_info "Installing atuin from upstream..."
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    fi
    if ! command_exists lazygit; then
        print_warning "lazygit not found and not in apt — install manually from https://github.com/jesseduffield/lazygit/releases"
    fi
    if ! command_exists delta; then
        print_warning "git-delta not found and not in apt — install manually from https://github.com/dandavison/delta/releases"
    fi
    if ! command_exists btop; then
        print_warning "btop not found — install via snap or build from https://github.com/aristocratos/btop"
    fi
    if ! command_exists eza; then
        print_warning "eza not found — install from https://github.com/eza-community/eza/blob/main/INSTALL.md"
    fi
}

# Flatpak apps (Linux). Adds the flathub remote, then installs everything in
# packages/flatpak.txt. flatpak itself comes from the distro manifest above.
install_flatpak_apps() {
    if ! command_exists flatpak; then
        print_warning "flatpak not installed — skipping Flatpak apps."
        return
    fi
    print_section "Installing Flatpak apps (flathub)"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    local pkgs
    if mapfile -t pkgs < <(read_manifest "$REPO_DIR/packages/flatpak.txt") && (( ${#pkgs[@]} > 0 )); then
        flatpak install -y flathub "${pkgs[@]}"
    else
        print_skip "No apps in packages/flatpak.txt."
    fi
}

# ---------------------------------------------------------------------------
# Plugin manager bootstrap
# ---------------------------------------------------------------------------

bootstrap_zinit() {
    local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    if [[ ! -d "$zinit_home/.git" ]]; then
        print_info "Cloning zinit..."
        mkdir -p "$(dirname "$zinit_home")"
        git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
        print_success "zinit cloned."
    else
        print_skip "zinit already cloned."
    fi
}

bootstrap_tpm() {
    if [[ ! -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
        print_info "Cloning TPM..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        print_success "TPM cloned."
    else
        print_skip "TPM already cloned."
    fi
    if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
        print_info "Installing TPM plugins..."
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null
        print_success "TPM plugins installed."
    fi
}

# ---------------------------------------------------------------------------
# Stow
# ---------------------------------------------------------------------------

stow_package() {
    local pkg="$1"
    if [[ ! -d "$REPO_DIR/$pkg" ]]; then
        print_warning "Package '$pkg' not found — skipping."
        return
    fi
    if stow --restow --no-folding --target="$HOME" --dir="$REPO_DIR" "$pkg" 2>/tmp/stow.err; then
        print_success "stowed: $pkg"
    else
        print_error "stow failed for $pkg:"
        sed 's/^/      /' /tmp/stow.err >&2
    fi
    rm -f /tmp/stow.err
}

stow_packages() {
    print_section "Stowing packages"
    local pkg
    for pkg in "${COMMON[@]}"; do stow_package "$pkg"; done
    case "$OS" in
        macos) for pkg in "${MACOS_ONLY[@]}"; do stow_package "$pkg"; done ;;
        arch|ubuntu) for pkg in "${LINUX_ONLY[@]}"; do stow_package "$pkg"; done ;;
    esac
}

# ---------------------------------------------------------------------------
# Post-stow steps
# ---------------------------------------------------------------------------

post_stow() {
    print_section "Post-stow"

    # Make repo scripts executable
    chmod +x "$REPO_DIR"/zsh/.scripts/*.sh 2>/dev/null || true
    chmod +x "$REPO_DIR"/claude/.claude/hook-scripts/*.sh 2>/dev/null || true
    print_success "Made scripts executable."

    # Build bat cache so it picks up the vendored Catppuccin theme
    if command_exists bat; then
        bat cache --build >/dev/null 2>&1 && print_success "bat cache rebuilt."
    fi

    # Import existing zsh history into atuin (only if atuin has nothing yet)
    if command_exists atuin && [[ -f "$HOME/.zsh_history" ]]; then
        local count
        count="$(atuin history list 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "${count:-0}" -lt 5 ]]; then
            print_info "Importing existing zsh history into atuin..."
            atuin import auto >/dev/null 2>&1 || true
            print_success "atuin history imported."
        else
            print_skip "atuin already has history ($count entries)."
        fi
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

print_section "Dotfiles bootstrap — platform: $OS"

if (( SKIP_PACKAGES == 0 )); then
    case "$OS" in
        macos)  ensure_prereqs_macos;  install_packages_macos ;;
        arch)   ensure_prereqs_arch;   install_packages_arch;   install_flatpak_apps ;;
        ubuntu) ensure_prereqs_ubuntu; install_packages_ubuntu; install_flatpak_apps ;;
    esac
else
    print_skip "Skipping package install (--no-packages)."
fi

if (( PACKAGES_ONLY == 1 )); then
    print_section "Done (--packages-only)"
    exit 0
fi

print_section "Plugin managers"
bootstrap_zinit
bootstrap_tpm

stow_packages
post_stow

print_section "Done"
print_info "Open a new shell, or run: exec zsh"
print_info "LazyVim will self-install on first 'nvim' launch."
