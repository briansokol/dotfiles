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

# Helper function to reload zshrc
reload_zshrc() {
    if [[ -f "$HOME/.zshrc" ]]; then
        print_info "Reloading .zshrc..."
        # Temporarily disable error trapping while sourcing
        trap - ERR
        source "$HOME/.zshrc" 2>/dev/null || true
        # Re-enable error trapping
        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
        print_success "Shell configuration reloaded"
    fi
}

# Track what was updated
UPDATED_ITEMS=()
SKIPPED_ITEMS=()
BREW_UPDATED_FORMULAE=()
BREW_UPDATED_CASKS=()
PACMAN_UPDATED_PACKAGES=()
YAY_UPDATED_PACKAGES=()
NPM_UPDATED_PACKAGES=()

# Load NVM if available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load Zinit if available (disable error trapping temporarily)
trap - ERR
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ -s "${ZINIT_HOME}/zinit.zsh" ]; then
    source "${ZINIT_HOME}/zinit.zsh" 2>/dev/null || true
fi
# Re-enable error trapping
trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Parse command-line flags for selective package manager updates
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Default: run all package managers
RUN_APT=true
RUN_PACMAN=true
RUN_YAY=true
RUN_NPM=true
RUN_HOMEBREW=true
RUN_ZINIT=true
RUN_GIT_CHECK=true

# Pre-process long flags before getopts
ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-git-check)
            RUN_GIT_CHECK=false
            shift
            ;;
        -*)
            # Preserve short flags for getopts
            ARGS+=("$1")
            shift
            ;;
        *)
            # Unknown argument
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore processed arguments for getopts
set -- "${ARGS[@]}"

# If any flags are provided, set all to false and enable only requested ones
if [[ $# -gt 0 ]]; then
    RUN_APT=false
    RUN_PACMAN=false
    RUN_YAY=false
    RUN_NPM=false
    RUN_HOMEBREW=false
    RUN_ZINIT=false

    while getopts "apynhz" opt; do
        case $opt in
            a) RUN_APT=true ;;
            p) RUN_PACMAN=true ;;
            y) RUN_YAY=true ;;
            n) RUN_NPM=true ;;
            h) RUN_HOMEBREW=true ;;
            z) RUN_ZINIT=true ;;
            \?) ;; # Ignore invalid options
        esac
    done
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Git Self-Update Check (Dotfiles)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_GIT_CHECK" = true ]]; then
    DOTFILES_DIR="$HOME/dotfiles"

    # Check if dotfiles directory exists
    if [[ -d "$DOTFILES_DIR" ]]; then
        print_section "Checking for Dotfiles Updates"

        # Temporarily disable error trapping for git operations
        trap - ERR

        # Save current directory and change to dotfiles
        ORIGINAL_DIR="$PWD"
        cd "$DOTFILES_DIR" 2>/dev/null || {
            print_warning "Could not access dotfiles directory at $DOTFILES_DIR"
            print_skip "Git self-update check skipped"
            SKIPPED_ITEMS+=("Git self-update (directory not accessible)")
            # Re-enable error trapping
            trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
        }

        # Verify we're in a git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            print_warning "Not in a git repository"
            print_skip "Git self-update check skipped"
            SKIPPED_ITEMS+=("Git self-update (not a git repo)")
            # Re-enable error trapping
            trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
            cd "$ORIGINAL_DIR" 2>/dev/null || true
        else
            # Fetch latest changes from remote
            print_info "Fetching latest changes from remote..."
            if ! git fetch --prune origin 2>/dev/null; then
                print_warning "Failed to fetch from remote repository"
                print_warning "This might be a network issue or remote access problem"
                print_info "Continuing with package updates..."
                SKIPPED_ITEMS+=("Git self-update (fetch failed)")
                # Re-enable error trapping
                trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
                cd "$ORIGINAL_DIR" 2>/dev/null || true
            else
                # Determine main branch (main or master)
                if git show-ref --verify --quiet refs/remotes/origin/main; then
                    MAIN_BRANCH="main"
                elif git show-ref --verify --quiet refs/remotes/origin/master; then
                    MAIN_BRANCH="master"
                else
                    print_warning "Could not find origin/main or origin/master"
                    print_skip "Git self-update check skipped"
                    SKIPPED_ITEMS+=("Git self-update (no main branch found)")
                    # Re-enable error trapping
                    trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
                    cd "$ORIGINAL_DIR" 2>/dev/null || true
                fi

                if [[ -n "$MAIN_BRANCH" ]]; then
                    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

                    # Only check for updates if we're on the main branch
                    if [[ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]]; then
                        print_warning "Not on $MAIN_BRANCH branch (currently on: $CURRENT_BRANCH)"
                        print_skip "Git self-update check skipped (not on main branch)"
                        SKIPPED_ITEMS+=("Git self-update (not on main branch)")
                        # Re-enable error trapping
                        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
                        cd "$ORIGINAL_DIR" 2>/dev/null || true
                    else
                        # Check if we're behind the remote
                        COMMITS_BEHIND=$(git rev-list HEAD..origin/$MAIN_BRANCH --count 2>/dev/null || echo "0")

                        if [[ "$COMMITS_BEHIND" -eq 0 ]]; then
                            # No updates available, continue with script
                            print_success "Dotfiles are up-to-date with remote"
                            # Re-enable error trapping
                            trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
                            cd "$ORIGINAL_DIR" 2>/dev/null || true
                        else
                            # Updates are available - check if repo is clean
                            print_info "Found $COMMITS_BEHIND new commit(s) available:"
                            git log --oneline HEAD..origin/$MAIN_BRANCH 2>/dev/null | sed 's/^/  /'
                            echo ""

                            # Check for uncommitted changes (modified files)
                            HAS_MODIFIED=false
                            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                                HAS_MODIFIED=true
                            fi

                            # Check for untracked files
                            UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || true)
                            HAS_UNTRACKED=false
                            if [[ -n "$UNTRACKED" ]]; then
                                HAS_UNTRACKED=true
                            fi

                            # If repo is dirty, warn but continue
                            if [[ "$HAS_MODIFIED" = true ]] || [[ "$HAS_UNTRACKED" = true ]]; then
                                print_warning "Cannot pull updates - you have uncommitted changes:"
                                git status --short 2>/dev/null
                                echo ""
                                print_warning "Updates are available but can't be pulled until you commit your changes."
                                print_info "To pull these updates later, commit your changes and re-run this script:"
                                print_info "  cd ~/dotfiles"
                                print_info "  git status           # to see changes"
                                print_info "  git add .            # to stage changes"
                                print_info "  git commit -m '...'  # to commit changes"
                                print_info "  git pull --rebase    # to pull and rebase"
                                echo ""
                                print_info "Continuing with package updates..."
                                SKIPPED_ITEMS+=("Git self-update (uncommitted changes)")
                                # Re-enable error trapping
                                trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
                                cd "$ORIGINAL_DIR" 2>/dev/null || true
                            else
                                # Repo is clean, check for unpushed local commits
                                COMMITS_AHEAD=$(git rev-list origin/$MAIN_BRANCH..HEAD --count 2>/dev/null || echo "0")

                                if [[ "$COMMITS_AHEAD" -eq 0 ]]; then
                                    # No local commits, use fast-forward pull
                                    print_info "Pulling latest changes..."
                                    if git pull --ff-only origin "$MAIN_BRANCH" 2>/dev/null; then
                                        # Re-enable error trapping
                                        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

                                        print_success "Successfully pulled latest dotfiles changes"
                                        echo ""
                                        cd "$ORIGINAL_DIR" 2>/dev/null || true
                                        reload_zshrc
                                        echo ""
                                        print_info "Continuing with package updates..."
                                    else
                                        # Re-enable error trapping before exit
                                        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

                                        print_warning "Failed to pull changes from remote"
                                        print_warning "This might indicate merge conflicts or other issues"
                                        print_info "Please resolve manually:"
                                        print_info "  cd ~/dotfiles"
                                        print_info "  git status"
                                        print_info "  git pull"
                                        echo ""
                                        cd "$ORIGINAL_DIR" 2>/dev/null || true
                                        exit 1
                                    fi
                                else
                                    # Have local commits, use rebase
                                    print_info "You have $COMMITS_AHEAD local commit(s) ahead of remote"
                                    print_info "Using rebase to replay your commits on top of remote changes..."
                                    if git pull --rebase origin "$MAIN_BRANCH" 2>/dev/null; then
                                        # Re-enable error trapping
                                        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

                                        print_success "Successfully rebased local commits on top of remote changes"
                                        echo ""
                                        cd "$ORIGINAL_DIR" 2>/dev/null || true
                                        reload_zshrc
                                        echo ""
                                        print_info "Continuing with package updates..."
                                    else
                                        # Re-enable error trapping before exit
                                        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR

                                        print_warning "Failed to rebase changes from remote"
                                        print_warning "This might indicate merge conflicts during rebase"
                                        print_info "Please resolve manually:"
                                        print_info "  cd ~/dotfiles"
                                        print_info "  git status"
                                        print_info "  git rebase --abort      # to cancel the rebase"
                                        print_info "  git pull --rebase       # to try again"
                                        echo ""
                                        cd "$ORIGINAL_DIR" 2>/dev/null || true
                                        exit 1
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    else
        print_section "Git Self-Update Check"
        print_skip "Dotfiles directory not found at $DOTFILES_DIR"
        SKIPPED_ITEMS+=("Git self-update (directory not found)")
    fi
else
    print_section "Git Self-Update Check"
    print_skip "Git self-update check disabled (--no-git-check flag)"
    SKIPPED_ITEMS+=("Git self-update (disabled by flag)")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Zinit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_ZINIT" = true ]]; then
    if command_exists zinit; then
        print_section "Updating Zinit"

        # Temporarily disable error trapping for zinit operations
        # zinit manages its own errors and background compilation processes
        trap - ERR

        print_info "Updating Zinit core..."
        zinit self-update
        UPDATED_ITEMS+=("Zinit core")

        print_info "Updating Zinit plugins..."
        zinit update --parallel

        UPDATED_ITEMS+=("Zinit plugins")
        print_success "Zinit updated successfully"

        print_info "Cleaning Up..."
        zinit cclear

        # Re-enable error trapping
        trap 'echo "\n❌ Error occurred on line $LINENO. Exiting."; exit 1' ERR
    else
        print_section "Zinit"
        print_skip "Zinit not found, skipping Zinit updates"
        SKIPPED_ITEMS+=("Zinit")
    fi
else
    print_section "Zinit"
    print_skip "Zinit skipped (not requested by user)"
    SKIPPED_ITEMS+=("Zinit")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Homebrew
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_HOMEBREW" = true ]]; then
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
else
    print_section "Homebrew"
    print_skip "Homebrew skipped (not requested by user)"
    SKIPPED_ITEMS+=("Homebrew")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update APT (Debian/Ubuntu)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_APT" = true ]]; then
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
else
    print_section "APT"
    print_skip "APT skipped (not requested by user)"
    SKIPPED_ITEMS+=("APT")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Pacman (Arch Linux)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_PACMAN" = true ]]; then
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
else
    print_section "Pacman"
    print_skip "Pacman skipped (not requested by user)"
    SKIPPED_ITEMS+=("Pacman")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update Yay (AUR Helper for Arch Linux)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_YAY" = true ]]; then
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
        # Suppress errors about temporary download files that can't be opened
        yay -Sc --noconfirm 2>&1 | grep -v "could not open file.*download-" || true

        UPDATED_ITEMS+=("Yay AUR packages")
        print_success "Yay updated successfully"
    else
        print_section "Yay (AUR)"
        print_skip "yay not found, skipping (not installed or not an Arch Linux system)"
        SKIPPED_ITEMS+=("Yay")
    fi
else
    print_section "Yay (AUR)"
    print_skip "Yay skipped (not requested by user)"
    SKIPPED_ITEMS+=("Yay")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Update NPM Global Packages
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$RUN_NPM" = true ]]; then
    # Check if jq is available (required for JSON parsing)
    if ! command_exists jq; then
        print_section "NPM Global Packages"
        print_skip "jq not found, skipping npm updates (jq is required for JSON parsing)"
        SKIPPED_ITEMS+=("NPM (jq not installed)")
    elif ! command_exists npm; then
        print_section "NPM Global Packages"
        print_skip "npm not found, skipping (Node.js not installed)"
        SKIPPED_ITEMS+=("NPM")
    else
    print_section "Updating NPM Global Packages"

    # Check if ncu (npm-check-updates) is available
    if ! command_exists ncu; then
        print_info "npm-check-updates not found, attempting to install..."
        if npm install -g npm-check-updates 2>/dev/null; then
            print_success "npm-check-updates installed successfully"
        else
            print_warning "Failed to install npm-check-updates, skipping npm updates"
            SKIPPED_ITEMS+=("NPM (could not install npm-check-updates)")
            # Jump to next section
            print_section "NPM Global Packages"
            print_skip "Skipped due to npm-check-updates installation failure"
        fi
    fi

    # Only proceed if ncu is now available
    if command_exists ncu; then
        # Determine if nvm is installed (nvm is a function, not a command, so check if it exists as a function)
        if type nvm >/dev/null 2>&1 || [[ -s "$NVM_DIR/nvm.sh" ]]; then
            # Ensure nvm is loaded as a function
            if ! type nvm >/dev/null 2>&1 && [[ -s "$NVM_DIR/nvm.sh" ]]; then
                source "$NVM_DIR/nvm.sh"
            fi

            print_info "NVM detected, updating packages for all Node versions..."

            # Get current active version to restore later
            ORIGINAL_NODE_VERSION=$(nvm current 2>/dev/null || echo "")

            # Get list of installed Node versions
            # Parse nvm list output to get only the version numbers (including 'system')
            # Use --no-alias to exclude alias lines and only show installed versions
            # Extract version numbers using capture groups for reliable parsing
            NODE_VERSIONS=$(nvm list --no-alias 2>/dev/null | sed 's/.*v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/; s/.*\(system\).*/\1/' | grep -E '^[0-9]|^system')

            if [[ -z "$NODE_VERSIONS" ]]; then
                print_warning "No Node versions found in nvm"
                SKIPPED_ITEMS+=("NPM (no Node versions in nvm)")
            else
                # Get default packages list if it exists
                DEFAULT_PACKAGES_FILE="$HOME/.nvm/default-packages"
                if [[ -f "$DEFAULT_PACKAGES_FILE" ]]; then
                    DEFAULT_PACKAGES=$(grep -v '^#' "$DEFAULT_PACKAGES_FILE" | grep -v '^$' || true)
                else
                    DEFAULT_PACKAGES=""
                fi

                # Process each Node version
                while IFS= read -r version; do
                    [[ -z "$version" ]] && continue

                    print_info "Switching to Node $version..."
                    if ! nvm use "$version" >/dev/null 2>&1; then
                        print_warning "Failed to switch to Node $version, skipping"
                        continue
                    fi

                    print_info "Checking for updates in Node $version..."

                    # Build list of packages to update
                    PACKAGES_TO_UPDATE=()

                    # Get currently installed global packages
                    INSTALLED_PACKAGES=$(npm list -g --json 2>/dev/null | jq -r '.dependencies | keys[]' 2>/dev/null || echo "")

                    # Check for missing default packages
                    if [[ -n "$DEFAULT_PACKAGES" ]]; then
                        while IFS= read -r pkg; do
                            [[ -z "$pkg" ]] && continue
                            if ! echo "$INSTALLED_PACKAGES" | grep -q "^${pkg}$"; then
                                print_info "Default package '$pkg' not installed, adding to update list"
                                PACKAGES_TO_UPDATE+=("$pkg")
                            fi
                        done <<< "$DEFAULT_PACKAGES"
                    fi

                    # Check for packages with available updates
                    OUTDATED_PACKAGES=$(ncu -g --jsonUpgraded 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "")
                    if [[ -n "$OUTDATED_PACKAGES" ]]; then
                        while IFS= read -r pkg; do
                            [[ -z "$pkg" ]] && continue
                            PACKAGES_TO_UPDATE+=("$pkg")
                        done <<< "$OUTDATED_PACKAGES"
                    fi

                    # Install updates if any packages need updating
                    if [[ ${#PACKAGES_TO_UPDATE[@]} -gt 0 ]]; then
                        print_info "Updating ${#PACKAGES_TO_UPDATE[@]} package(s) in Node $version: ${PACKAGES_TO_UPDATE[*]}"
                        if npm install -g "${PACKAGES_TO_UPDATE[@]}" 2>/dev/null; then
                            # Add packages to the tracking array
                            for pkg in "${PACKAGES_TO_UPDATE[@]}"; do
                                NPM_UPDATED_PACKAGES+=("$pkg")
                            done
                            print_success "Updated packages in Node $version"
                        else
                            print_warning "Failed to update packages in Node $version, continuing to next version"
                        fi
                    else
                        print_info "No updates needed for Node $version"
                    fi
                done <<< "$NODE_VERSIONS"

                # Restore original Node version
                if [[ -n "$ORIGINAL_NODE_VERSION" ]] && [[ "$ORIGINAL_NODE_VERSION" != "none" ]]; then
                    print_info "Restoring original Node version: $ORIGINAL_NODE_VERSION"
                    nvm use "$ORIGINAL_NODE_VERSION" >/dev/null 2>&1 || print_warning "Failed to restore Node $ORIGINAL_NODE_VERSION"
                fi

                UPDATED_ITEMS+=("NPM global packages")
                print_success "NPM global packages updated successfully"
            fi
        else
            # No nvm, just update the current Node installation
            print_info "NVM not detected, updating global packages for current Node installation..."

            # Build list of packages to update
            PACKAGES_TO_UPDATE=()

            # Check for packages with available updates
            OUTDATED_PACKAGES=$(ncu -g --jsonUpgraded 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "")
            if [[ -n "$OUTDATED_PACKAGES" ]]; then
                while IFS= read -r pkg; do
                    [[ -z "$pkg" ]] && continue
                    PACKAGES_TO_UPDATE+=("$pkg")
                done <<< "$OUTDATED_PACKAGES"
            fi

            # Install updates if any packages need updating
            if [[ ${#PACKAGES_TO_UPDATE[@]} -gt 0 ]]; then
                print_info "Updating ${#PACKAGES_TO_UPDATE[@]} package(s): ${PACKAGES_TO_UPDATE[*]}"
                if npm install -g "${PACKAGES_TO_UPDATE[@]}" 2>/dev/null; then
                    # Add packages to the tracking array
                    for pkg in "${PACKAGES_TO_UPDATE[@]}"; do
                        NPM_UPDATED_PACKAGES+=("$pkg")
                    done
                    UPDATED_ITEMS+=("NPM global packages")
                    print_success "NPM global packages updated successfully"
                else
                    print_warning "Failed to update npm packages"
                    SKIPPED_ITEMS+=("NPM (update failed)")
                fi
            else
                print_info "No npm updates available"
                print_success "All npm global packages are up-to-date"
            fi
        fi
    fi
    fi
else
    print_section "NPM Global Packages"
    print_skip "NPM skipped (not requested by user)"
    SKIPPED_ITEMS+=("NPM")
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

# Display detailed Homebrew formulae that were updated
if [[ ${#BREW_UPDATED_FORMULAE[@]} -gt 0 ]]; then
    # De-duplicate the array
    local -a deduped_brew_formulae=($(printf '%s\n' "${BREW_UPDATED_FORMULAE[@]}" | sort -u))
    echo "\n${BOLD}${GREEN}Homebrew formulae updated (${#deduped_brew_formulae[@]}):${RESET}"
    for formula in "${deduped_brew_formulae[@]}"; do
        echo "  ${GREEN}✓${RESET} $formula"
    done
fi

# Display detailed Homebrew casks that were updated
if [[ ${#BREW_UPDATED_CASKS[@]} -gt 0 ]]; then
    # De-duplicate the array
    local -a deduped_brew_casks=($(printf '%s\n' "${BREW_UPDATED_CASKS[@]}" | sort -u))
    echo "\n${BOLD}${GREEN}Homebrew casks updated (${#deduped_brew_casks[@]}):${RESET}"
    for cask in "${deduped_brew_casks[@]}"; do
        echo "  ${GREEN}✓${RESET} $cask"
    done
fi

# Display detailed Pacman packages that were updated
if [[ ${#PACMAN_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    # De-duplicate the array
    local -a deduped_pacman=($(printf '%s\n' "${PACMAN_UPDATED_PACKAGES[@]}" | sort -u))
    echo "\n${BOLD}${GREEN}Pacman packages updated (${#deduped_pacman[@]}):${RESET}"
    for package in "${deduped_pacman[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

# Display detailed Yay AUR packages that were updated
if [[ ${#YAY_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    # De-duplicate the array
    local -a deduped_yay=($(printf '%s\n' "${YAY_UPDATED_PACKAGES[@]}" | sort -u))
    echo "\n${BOLD}${GREEN}Yay AUR packages updated (${#deduped_yay[@]}):${RESET}"
    for package in "${deduped_yay[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

# Display detailed npm packages that were updated
if [[ ${#NPM_UPDATED_PACKAGES[@]} -gt 0 ]]; then
    # De-duplicate the array
    local -a deduped_npm=($(printf '%s\n' "${NPM_UPDATED_PACKAGES[@]}" | sort -u))
    echo "\n${BOLD}${GREEN}NPM packages updated (${#deduped_npm[@]}):${RESET}"
    for package in "${deduped_npm[@]}"; do
        echo "  ${GREEN}✓${RESET} $package"
    done
fi

if [[ ${#SKIPPED_ITEMS[@]} -gt 0 ]]; then
    echo "\n${BOLD}${YELLOW}Skipped:${RESET}"
    for item in "${SKIPPED_ITEMS[@]}"; do
        echo "  ${YELLOW}⊘${RESET} $item"
    done
fi

echo "\n${BOLD}${GREEN}All packages are up-to-date!${RESET}\n"

# Reload shell configuration at the end
reload_zshrc

# Clean exit - disable error trapping and wait for any background processes
trap - ERR
wait 2>/dev/null || true
