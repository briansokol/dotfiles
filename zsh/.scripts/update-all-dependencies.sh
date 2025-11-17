#!/bin/zsh

# Handle pipeline failures but allow individual commands to fail gracefully
set -o pipefail

# Trap errors for better messaging (but allow specific commands to override)
trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

# Color codes for output
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN=''
    BLUE=''
    YELLOW=''
    RED=''
    BOLD=''
    RESET=''
fi

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to print section headers
print_section() {
    echo "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${BOLD}${BLUE}$1${RESET}"
    echo "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

# Helper function for info messages
print_info() {
    echo "${BLUE}ℹ${RESET}  $1"
}

# Helper function for success messages
print_success() {
    echo "${GREEN}✓${RESET}  $1"
}

# Helper function for warning messages
print_warning() {
    echo "${YELLOW}⚠${RESET}  $1"
}

# Helper function for skip messages
print_skip() {
    echo "${YELLOW}⊘${RESET}  $1"
}

# Track what was updated
UPDATED_ITEMS=()
SKIPPED_ITEMS=()
NPM_UPDATED_PACKAGES=()
BREW_UPDATED_FORMULAE=()
BREW_UPDATED_CASKS=()
PACMAN_UPDATED_PACKAGES=()
YAY_UPDATED_PACKAGES=()

# Load NVM if available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Function to update npm packages for a given node version
updateNpmOutdated () {
    print_info "Updating npm..."
    nvm install-latest-npm

    print_info "Scanning for outdated global packages..."

    # Check if ncu (npm-check-updates) is available
    if ! command_exists ncu; then
        print_warning "npm-check-updates (ncu) not found. Skipping global package updates."
        print_info "Install with: npm install -g npm-check-updates"
        return 0
    fi

    # Check if jq is available
    if ! command_exists jq; then
        print_warning "jq not found. Skipping global package updates."
        print_info "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        return 0
    fi

    local packages=$(ncu -g --jsonUpgraded | jq -r 'to_entries[] | "\(.key)@\(.value)"')

    if [[ -z "$packages" ]]; then
        print_success "All global packages are up to date"
        return 0
    fi

    echo "$packages" | while IFS= read -r package; do
        # Skip npm itself (updated separately)
        if [[ "$package" = "npm@"* ]]; then
            continue
        fi
        print_info "Upgrading → $package"
        npm -g install --quiet "$package"

        # Extract package name (without version)
        package_name="${package%@*}"
        NPM_UPDATED_PACKAGES+=("$package_name")
    done

    print_success "Global packages updated"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Zinit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command_exists zinit; then
    print_section "Updating Zinit"

    # Temporarily disable error trapping for zinit operations
    # zinit manages its own errors and background compilation processes
    trap - ERR

    print_info "Updating Zinit core..."
    zinit self-update
    UPDATED_ITEMS+=("Zinit core")

    print_info "Updating Zinit plugins..."
    zinit update

    UPDATED_ITEMS+=("Zinit plugins")
    print_success "Zinit updated successfully"

    # Wait for zinit background processes to complete and suppress their output
    sleep 1
    wait 2>/dev/null || true

    # Re-enable error trapping
    trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
else
    print_section "Zinit"
    print_skip "Zinit not found, skipping Zinit updates"
    SKIPPED_ITEMS+=("Zinit")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Homebrew
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command_exists brew; then
    print_section "Updating Homebrew"

    print_info "Updating Homebrew formula list..."
    brew update

    print_info "Upgrading formulae..."
    # Capture the list of outdated formulae before upgrading
    outdated_formulae=$(brew outdated --formula --quiet 2>/dev/null || true)
    if [[ -n "$outdated_formulae" ]]; then
        while IFS= read -r formula; do
            BREW_UPDATED_FORMULAE+=("$formula")
        done <<< "$outdated_formulae"
    fi
    brew upgrade

    print_info "Upgrading casks..."
    # Capture the list of outdated casks before upgrading
    outdated_casks=$(brew outdated --cask --quiet 2>/dev/null || true)
    if [[ -n "$outdated_casks" ]]; then
        while IFS= read -r cask; do
            BREW_UPDATED_CASKS+=("$cask")
        done <<< "$outdated_casks"
    fi
    brew upgrade --cask

    print_info "Cleaning up old versions..."
    brew cleanup

    UPDATED_ITEMS+=("Homebrew packages")
    print_success "Homebrew updated successfully"
else
    print_section "Homebrew"
    print_skip "Homebrew not found, skipping (not available on this system)"
    SKIPPED_ITEMS+=("Homebrew")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update APT (Debian/Ubuntu)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command_exists apt-get; then
    print_section "Updating APT"

    # Determine if we need sudo prefix
    # If already running as root (EUID=0), no sudo needed
    # Otherwise, check if we have sudo privileges
    if [[ $EUID -eq 0 ]]; then
        # Running as root, no sudo needed
        SUDO_CMD=""
        HAS_PERMISSION=true
    elif sudo -n true 2>/dev/null; then
        # Not root, but sudo is available
        SUDO_CMD="sudo"
        HAS_PERMISSION=true
    else
        HAS_PERMISSION=false
    fi

    if [[ "$HAS_PERMISSION" = true ]]; then
        print_info "Updating package list..."
        $SUDO_CMD apt-get update

        print_info "Upgrading packages..."
        $SUDO_CMD apt-get upgrade -y

        print_info "Performing distribution upgrade..."
        $SUDO_CMD apt-get dist-upgrade -y

        print_info "Removing unnecessary packages..."
        $SUDO_CMD apt-get autoremove -y

        print_info "Cleaning package cache..."
        $SUDO_CMD apt-get autoclean

        UPDATED_ITEMS+=("APT packages")
        print_success "APT updated successfully"
    else
        print_warning "sudo access required for apt-get. Skipping APT updates."
        print_info "Run with sudo or configure passwordless sudo for apt-get"
        SKIPPED_ITEMS+=("APT (no sudo access)")
    fi
else
    print_section "APT"
    print_skip "apt-get not found, skipping (not a Debian/Ubuntu system)"
    SKIPPED_ITEMS+=("APT")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Pacman (Arch Linux)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Skip pacman if yay is available (yay handles both official repos and AUR)
if command_exists yay; then
    print_section "Pacman"
    print_skip "Skipping Pacman (yay will handle all package updates)"
    SKIPPED_ITEMS+=("Pacman (using yay instead)")
elif command_exists pacman; then
    print_section "Updating Pacman"

    # Determine if we need sudo prefix
    # If already running as root (EUID=0), no sudo needed
    # Otherwise, check if we have sudo privileges
    if [[ $EUID -eq 0 ]]; then
        # Running as root, no sudo needed
        SUDO_CMD=""
        HAS_PERMISSION=true
    elif sudo -n true 2>/dev/null; then
        # Not root, but sudo is available
        SUDO_CMD="sudo"
        HAS_PERMISSION=true
    else
        HAS_PERMISSION=false
    fi

    if [[ "$HAS_PERMISSION" = true ]]; then
        print_info "Syncing package databases and upgrading packages..."

        # Capture list of packages that will be updated
        outdated_packages=$(pacman -Qu 2>/dev/null | awk '{print $1}' || true)
        if [[ -n "$outdated_packages" ]]; then
            while IFS= read -r package; do
                PACMAN_UPDATED_PACKAGES+=("$package")
            done <<< "$outdated_packages"
        fi

        # Update and upgrade all packages
        $SUDO_CMD pacman -Syu --noconfirm

        print_info "Removing orphaned packages..."
        # Remove orphaned packages (dependencies no longer needed)
        orphans=$(pacman -Qdtq 2>/dev/null || true)
        if [[ -n "$orphans" ]]; then
            $SUDO_CMD pacman -Rns --noconfirm $orphans
            print_success "Removed orphaned packages"
        else
            print_info "No orphaned packages found"
        fi

        print_info "Cleaning package cache..."
        # Keep only the latest 3 versions of each package in cache
        $SUDO_CMD paccache -rk3 2>/dev/null || print_warning "paccache not found, skipping cache cleanup (install pacman-contrib)"

        UPDATED_ITEMS+=("Pacman packages")
        print_success "Pacman updated successfully"
    else
        print_warning "sudo access required for pacman. Skipping Pacman updates."
        print_info "Run with sudo or configure passwordless sudo for pacman"
        SKIPPED_ITEMS+=("Pacman (no sudo access)")
    fi
else
    print_section "Pacman"
    print_skip "pacman not found, skipping (not an Arch Linux system)"
    SKIPPED_ITEMS+=("Pacman")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Yay (AUR Helper for Arch Linux)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command_exists yay; then
    print_section "Updating Yay (AUR)"

    print_info "Syncing AUR databases and upgrading packages..."

    # Capture list of packages that will be updated
    outdated_packages=$(yay -Qu 2>/dev/null | awk '{print $1}' || true)
    if [[ -n "$outdated_packages" ]]; then
        while IFS= read -r package; do
            YAY_UPDATED_PACKAGES+=("$package")
        done <<< "$outdated_packages"
    fi

    # Update and upgrade all packages (including AUR)
    yay -Syu --noconfirm

    print_info "Cleaning package cache..."
    # Clean uninstalled packages from cache
    yay -Sc --noconfirm

    UPDATED_ITEMS+=("Yay AUR packages")
    print_success "Yay updated successfully"
else
    print_section "Yay (AUR)"
    print_skip "yay not found, skipping (not installed or not an Arch Linux system)"
    SKIPPED_ITEMS+=("Yay")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update npm packages for all node versions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if command_exists nvm; then
    print_section "Updating npm Dependencies"

    # Temporarily disable error trapping for nvm operations
    trap - ERR

    # Get list of installed node versions, filtering only version lines
    # Extract only the installed versions (before the aliases section)
    nvm list | while IFS= read -r line; do
        # Remove spaces, arrows, and ANSI color codes
        version="$(echo "${line}" | tr -d '[:space:]' | sed 's/->//g' | sed -E "s/"$'\E'"\[([0-9]{1,2}(;[0-9]{1,2})*)?m//g")"

        # Only process if it's a valid version number (vX.Y.Z format)
        if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_info "Using Node $version"
            nvm use "$version"
            updateNpmOutdated
            UPDATED_ITEMS+=("npm packages for $version")
        fi
    done

    print_success "All npm dependencies updated"

    # Re-enable error trapping
    trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
else
    print_section "npm Dependencies"
    print_skip "nvm not found, skipping npm updates"
    SKIPPED_ITEMS+=("npm/nvm")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_section "Summary"

if [[ ${#UPDATED_ITEMS[@]} -gt 0 ]]; then
    echo "${BOLD}${GREEN}Updated:${RESET}"
    for item in "${UPDATED_ITEMS[@]}"; do
        echo "  ${GREEN}✓${RESET} $item"
    done
fi

# Display detailed npm packages that were updated
if [[ ${#NPM_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    echo "\n${BOLD}${GREEN}npm packages updated (${#NPM_UPDATED_PACKAGES[@]}):${RESET}"
    for package in "${NPM_UPDATED_PACKAGES[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

# Display detailed Homebrew formulae that were updated
if [[ ${#BREW_UPDATED_FORMULAE[@]} -gt 0 ]]; then
    echo "\n${BOLD}${GREEN}Homebrew formulae updated (${#BREW_UPDATED_FORMULAE[@]}):${RESET}"
    for formula in "${BREW_UPDATED_FORMULAE[@]}"; do
        echo "  ${GREEN}✓${RESET} $formula"
    done
fi

# Display detailed Homebrew casks that were updated
if [[ ${#BREW_UPDATED_CASKS[@]} -gt 0 ]]; then
    echo "\n${BOLD}${GREEN}Homebrew casks updated (${#BREW_UPDATED_CASKS[@]}):${RESET}"
    for cask in "${BREW_UPDATED_CASKS[@]}"; do
        echo "  ${GREEN}✓${RESET} $cask"
    done
fi

# Display detailed Pacman packages that were updated
if [[ ${#PACMAN_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    echo "\n${BOLD}${GREEN}Pacman packages updated (${#PACMAN_UPDATED_PACKAGES[@]}):${RESET}"
    for package in "${PACMAN_UPDATED_PACKAGES[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

# Display detailed Yay AUR packages that were updated
if [[ ${#YAY_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    echo "\n${BOLD}${GREEN}Yay AUR packages updated (${#YAY_UPDATED_PACKAGES[@]}):${RESET}"
    for package in "${YAY_UPDATED_PACKAGES[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

if [[ ${#SKIPPED_ITEMS[@]} -gt 0 ]]; then
    echo "\n${BOLD}${YELLOW}Skipped:${RESET}"
    for item in "${SKIPPED_ITEMS[@]}"; do
        echo "  ${YELLOW}⊘${RESET} $item (not installed)"
    done
fi

echo "\n${BOLD}${GREEN}All available dependencies are up-to-date!${RESET}\n"

# Clean exit - disable error trapping and wait for any background processes
trap - ERR
wait 2>/dev/null || true
