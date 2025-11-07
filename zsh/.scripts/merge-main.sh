#!/bin/zsh
set -euo pipefail

# Parse arguments
DRY_RUN=false
CUSTOM_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --branch)
            CUSTOM_BRANCH="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage: $0 [--dry-run] [--branch <branch-name>]"
            exit 1
            ;;
    esac
done

# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check for detached HEAD
if [[ "$BRANCH" == "HEAD" ]]; then
    echo "Error: You are in detached HEAD state"
    echo "Please checkout a branch first"
    exit 1
fi

# Determine target branch
if [[ -n "$CUSTOM_BRANCH" ]]; then
    # Use custom branch if specified
    TARGET_BRANCH="$CUSTOM_BRANCH"

    # Verify the custom branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$TARGET_BRANCH"; then
        echo "Error: Branch 'origin/$TARGET_BRANCH' does not exist"
        exit 1
    fi
else
    # Auto-detect main branch (main or master)
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        TARGET_BRANCH="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        TARGET_BRANCH="master"
    else
        echo "Error: Could not find origin/main or origin/master"
        exit 1
    fi
fi

# Prevent merging a branch into itself
if [[ "$BRANCH" == "$TARGET_BRANCH" ]]; then
    echo "Error: You are already on $TARGET_BRANCH"
    echo "Cannot merge a branch into itself"
    exit 1
fi

echo "Merging latest origin/$TARGET_BRANCH into $BRANCH"

# Fetch latest changes
git fetch --prune

# Show what will be merged in dry-run mode
if [[ "$DRY_RUN" == true ]]; then
    echo "\nCommits that would be merged:"
    git log --oneline "$BRANCH..origin/$TARGET_BRANCH"
    echo "\nDry-run complete. Run without --dry-run to execute the merge."
    exit 0
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Error: You have uncommitted changes"
    echo "Please commit or stash your changes before merging"
    git status --short
    exit 1
fi

# Merge origin/$TARGET_BRANCH into current branch
if git merge "origin/$TARGET_BRANCH"; then
    echo "Merge completed successfully"
else
    echo "Merge failed - you may need to resolve conflicts"
    echo "After resolving conflicts, run 'git merge --continue' or 'git commit'"
    exit 1
fi