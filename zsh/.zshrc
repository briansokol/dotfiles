export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

if [[ -f "/opt/homebrew/bin/brew" && -z "$HOMEBREW_PREFIX" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Only initialize zinit if not already loaded
if [[ -z "$__ZINIT_LOADED" ]]; then
  # Download Zinit, if it's not there yet
  [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
  [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

  # Source/Load zinit
  source "${ZINIT_HOME}/zinit.zsh"

  # Add in Powerlevel10k
  # zinit ice depth=1; zinit light romkatv/powerlevel10k

  # Add in zsh plugins
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab

  # Add in snippets
  zinit snippet OMZL::git.zsh
  zinit snippet OMZL::nvm.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::brew
  zinit snippet OMZP::gh
  zinit snippet OMZP::npm
  zinit snippet OMZP::nvm
  zinit snippet OMZP::node
  zinit snippet OMZP::command-not-found

  # Load completions
  autoload -Uz compinit && compinit
  zinit cdreplay -q

  __ZINIT_LOADED=1
fi

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Run nvm autoload
if [[ -s "$HOME/.nvm/nvm.sh" && -z "$NVM_DIR" ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  autoload -U add-zsh-hook
  load-nvmrc() {
    if [[ -f .nvmrc && -r .nvmrc ]]; then
      nvm use --silent
    elif [[ $(nvm version) != $(nvm version default)  ]]; then
      nvm use default --silent
    fi
  }
  # Only add the hook if it's not already registered
  if (( ! ${chpwd_functions[(I)load-nvmrc]} )); then
    add-zsh-hook chpwd load-nvmrc
  fi
  load-nvmrc
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load Starship if installed
# Check if starship_precmd function exists rather than env var (which tmux inherits)
if command -v starship &>/dev/null && ! typeset -f starship_precmd >/dev/null; then
  STARSHIP_CONFIG=${XDG_CONFIG_HOME}/starship.toml
  eval "$(starship init zsh)"
fi

# User configuration
DEFAULT_USER=$(whoami)

# BASH_PROFILE CONFIGS

if (( $+commands[micro] )); then
  export EDITOR=micro
  MICRO_TRUECOLOR=1
else
  export EDITOR=nano
fi

#export JAVA_HOME=$(/usr/libexec/java_home -v 11)
#export PATH=$JAVA_HOME/bin:$PATH

# General Aliases
alias update-all='~/.scripts/update-all-dependencies.sh'
alias bb='bbedit'
alias npmlg='npm list -g --depth=0'

# Git Aliases
alias degit='rm -rf ./.git'
alias merge-dev='sh ~/.scripts/merge-main.sh --branch develop'
alias merge-main='sh ~/.scripts/merge-main.sh'
alias rebase-main='sh ~/.scripts/rebase-main.sh'
alias rebase-main-dry-run='sh ~/.scripts/rebase-main.sh --dry-run'
alias git-clean='git branch --merged | grep -v \* | xargs git branch -d'
alias gas='git add . && git status'

# Micro Alias
(( $+commands[micro] )) && alias mi='micro'

# Neovim
alias nv='nvim'
alias vim='nvim'
alias nf='fzf -m --preview="bat --color=always {}" --bind "enter:become(nvim {+})"'

# Eza Aliases
if (( $+commands[eza] )); then
  alias ls='eza --icons=always --group-directories-first --color=always'
  alias la='eza --icons=always --group-directories-first -lhgmUa --time-style=long-iso --git --color=always'
else
  alias ls='ls --color'
  alias la='ls -la --color'
fi

# Yarn Aliases
alias ya='yarn add --exact'
alias yad='yarn add --exact --dev'
alias yr='yarn remove'

# npm Aliases
alias ni='npm install --save-exact'
alias nid='npm install --save-exact --save-dev'
alias nu='npm uninstall'

# pnpm Aliases
alias pa='pnpm add --save-exact'
alias pad='pnpm add --save-exact --save-dev'
alias pr='pnpm remove'

# Shell Integrations
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# fzf colors (Catppuccin Mocha) — also applies to fzf-tab completion menus
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"

# Only initialize fzf once (check if fzf widgets are already loaded)
if command -v fzf &>/dev/null && ! bindkey | grep -q "fzf-file-widget"; then
  source <(fzf --zsh)
fi

# Atuin shell history — Ctrl-R replaces fzf's history widget (intended).
# Up-arrow stays as zsh's normal history search (--disable-up-arrow).
if command -v atuin &>/dev/null && ! typeset -f _atuin_search_widget >/dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Initialize zoxide with a fallback wrapper (check if __zoxide_z function exists)
if command -v zoxide &>/dev/null && ! typeset -f __zoxide_z >/dev/null; then
  eval "$(zoxide init zsh)"

  # Create a cd wrapper that falls back to builtin cd.
  # Skip zoxide in non-interactive shells (scripts, Claude Code's Bash tool):
  # they source a snapshot of this function without zoxide's chpwd hook, which
  # makes zoxide print a spurious "configuration issue" doctor warning.
  cd() {
    if [[ -o interactive ]] && typeset -f __zoxide_z >/dev/null; then
      __zoxide_z "$@"
    else
      builtin cd "$@"
    fi
  }
fi

# Keychain SSH agent management
if (( $+commands[keychain] )); then
  _kc_keys=()
  for _kc_key in "$HOME"/.ssh/id_*(N); do
    [[ -f "$_kc_key" ]] && _kc_keys+=("${_kc_key:t}")
  done
  if (( ${#_kc_keys[@]} > 0 )); then
    eval "$(keychain --eval --quiet "${_kc_keys[@]}")"
  fi
  unset _kc_keys _kc_key
fi

# iTerm2 Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Add Visual Studio Code (Mac)
if [[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" && ! "$PATH" == */Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin* ]]; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# opencode
if [[ -d "$HOME/.opencode/bin" && ! "$PATH" == *$HOME/.opencode/bin* ]]; then
  export PATH="$HOME/.opencode/bin:$PATH"
fi

# Local bin
if [[ -d "$HOME/.local/bin" && ! "$PATH" == *$HOME/.local/bin* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# .NET SDK installed via dotnet-install.sh (includes TestHostNetFramework,
# unlike the Ubuntu-packaged dotnet8 SDK). Take precedence over /usr/bin/dotnet.
if [[ -d "$HOME/.dotnet" && ! "$PATH" == *$HOME/.dotnet:* ]]; then
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$HOME/.dotnet:$PATH"
fi

# Local environment overrides
[[ -f "$HOME/.local_env" ]] && source "$HOME/.local_env"

# opencode
export PATH=/home/bsokol/.opencode/bin:$PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/Projects/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/Projects/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/Projects/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/Projects/google-cloud-sdk/completion.zsh.inc"; fi

# System info on new session
if (( $+commands[fastfetch] )) && [[ $SHLVL -eq 1 ]]; then
  fastfetch --config neofetch
fi
