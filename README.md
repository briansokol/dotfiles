# dotfiles

All my dotfiles, ready to be installed and synced with Mackup.

## Install Mackup

If you're on a Mac, use Homebrew:

```zsh
brew install mackup
```

If you're on Linux, use PIP:

```zsh
pip install --upgrade mackup
```

## Setup Mackup

Create a Mackup config file:

```zsh
nano ~/.mackup.cfg
```

Add these contents, changing the path as appropriate:

```ini
[storage]
engine = file_system
path = {path/to/this/repo}/dotfiles

[applications_to_sync]
git
homebrew
nvm
p10k
zsh
```

If the path does not have a starting slash, it will be relative to the user directory.

## Install Dotfiles

```zsh
mackup restore
```

## Syncing Changed Dotfiles

1. Commit any changes to dotfiles to the main branch of this repo.
2. On other computers, pull changes.

## Revert dotfiles to Originals

If you need to uninstall this repo:

```zsh
mackup uninstall
```

## Adding New Dotfiles

1. Update the `.mackup.cfg` file to list the new application to sync.
2. Run `mackup backup` to add new files to the repo.
3. Commit changes to the main branch.
4. On other computers, pull changes.