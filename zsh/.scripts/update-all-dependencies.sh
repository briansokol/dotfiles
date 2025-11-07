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
    brew upgrade

    print_info "Upgrading casks..."
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

    # Check if we have sudo privileges
    if sudo -n true 2>/dev/null; then
        print_info "Updating package list..."
        sudo apt-get update

        print_info "Upgrading packages..."
        sudo apt-get upgrade -y

        print_info "Performing distribution upgrade..."
        sudo apt-get dist-upgrade -y

        print_info "Removing unnecessary packages..."
        sudo apt-get autoremove -y

        print_info "Cleaning package cache..."
        sudo apt-get autoclean

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
