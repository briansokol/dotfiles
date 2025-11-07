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

# Prevent rebasing a branch onto itself
if [[ "$BRANCH" == "$TARGET_BRANCH" ]]; then
    echo "Error: You are already on $TARGET_BRANCH"
    echo "Cannot rebase a branch onto itself"
    exit 1
fi

echo "Rebasing $BRANCH onto latest origin/$TARGET_BRANCH"

# Fetch latest changes
git fetch --prune

# Show what will be rebased in dry-run mode
if [[ "$DRY_RUN" == true ]]; then
    echo "\nCommits that would be rebased:"
    git log --oneline "$BRANCH" ^"origin/$TARGET_BRANCH"
    echo "\nDry-run complete. Run without --dry-run to execute the rebase."
    exit 0
fi

# Check if there are uncommitted changes
STASHED=false
if ! git diff-index --quiet HEAD --; then
    echo "Stashing uncommitted changes..."
    git stash push --include-untracked -m "Auto-stash before rebase"
    STASHED=true
fi

# Rebase current branch onto origin/$TARGET_BRANCH
if git rebase "origin/$TARGET_BRANCH"; then
    echo "Rebase completed successfully"

    # Pop the stash if we stashed changes
    if [[ "$STASHED" == true ]]; then
        echo "Restoring stashed changes..."
        if ! git stash pop; then
            echo "Warning: Failed to automatically restore stashed changes"
            echo "You may need to manually resolve stash conflicts with 'git stash pop'"
            exit 1
        fi
    fi
else
    echo "Rebase failed - you may need to resolve conflicts"
    echo "After resolving conflicts, run 'git rebase --continue'"

    if [[ "$STASHED" == true ]]; then
        echo "Your changes are stashed and can be restored with 'git stash pop' after completing the rebase"
    fi

    exit 1
fi
