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
COMMON=(zsh nvim tmux starship nvm micro ghostty yazi rofi claude git atuin bat lazygit btop herdr opencode)
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

# Homebrew is "healthy" only if its Ruby layer loads. Neither `command -v brew`
# nor the cheap probes (--prefix, --version, --cellar) are sufficient: brew.sh
# answers those in shell without starting Ruby, so a Homebrew built for the
# wrong CPU or an unsupported macOS release still passes them and then fails on
# every real subcommand. `brew config` runs cmd/config.rb, so it fails exactly
# when `brew install` would.
brew_healthy() {
    command_exists brew && brew config >/dev/null 2>&1
}

# Homebrew only puts itself on PATH via ~/.zprofile, which a non-login shell
# never reads. Probe both standard prefixes directly and adopt the first healthy
# one; /opt/homebrew (Apple Silicon) wins over /usr/local (Intel).
# Ends in `return 1`, so only ever call this in a condition: a bare call would
# abort the script under `set -e`.
adopt_brew_prefix() {
    local prefix
    for prefix in /opt/homebrew /usr/local; do
        [[ -x "$prefix/bin/brew" ]] || continue
        # Probe before eval so a broken prefix never gets prepended to PATH.
        "$prefix/bin/brew" config >/dev/null 2>&1 || continue
        # `|| true` is required: a bare eval on malformed input returns 2.
        eval "$("$prefix/bin/brew" shellenv)" || true
        case ":$PATH:" in
            *":$prefix/bin:"*) ;;
            *) PATH="$prefix/bin:$prefix/sbin:$PATH"; export PATH ;;
        esac
        if brew_healthy; then
            print_info "Using Homebrew at $prefix."
            return 0
        fi
    done
    return 1
}

ensure_prereqs_macos() {
    print_section "Prerequisites (macOS)"

    if adopt_brew_prefix || brew_healthy; then
        print_skip "Homebrew already installed."
    else
        if command_exists brew; then
            print_warning "A 'brew' is on PATH but does not work — reinstalling Homebrew."
        fi
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if adopt_brew_prefix || brew_healthy; then
            print_success "Homebrew installed."
        else
            print_error "Homebrew install did not produce a working 'brew'."
            print_error "Install it manually from https://brew.sh, then re-run this script."
            exit 1
        fi
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

# git and stow are needed by the plugin-manager and stow phases. They normally
# come from ensure_prereqs_*, which --no-packages skips entirely. Probe by
# running each tool rather than with command_exists: on a Mac without Command
# Line Tools, /usr/bin/git exists and satisfies `command -v` but exits non-zero
# on every invocation.
require_git_and_stow() {
    local missing=""
    git  --version >/dev/null 2>&1 || missing="git"
    stow --version >/dev/null 2>&1 || missing="${missing:+$missing }stow"
    [[ -z "$missing" ]] && return 0

    print_error "Required tool(s) missing or not working: $missing"
    if (( SKIP_PACKAGES == 1 )); then
        print_error "--no-packages skips prerequisite installation. Re-run without it, or install manually:"
    else
        print_error "Package installation finished but did not provide them. Install manually, then re-run:"
    fi
    case "$OS" in
        macos)  print_info "brew install $missing" ;;
        arch)   print_info "sudo pacman -S --needed $missing" ;;
        ubuntu) print_info "sudo apt-get install -y $missing" ;;
    esac
    exit 1
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

require_git_and_stow

print_section "Plugin managers"
bootstrap_zinit
bootstrap_tpm

stow_packages
post_stow

print_section "Done"
print_info "Open a new shell, or run: exec zsh"
print_info "LazyVim will self-install on first 'nvim' launch."
