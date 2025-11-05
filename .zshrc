export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:=$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

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

# Run nvm autoload
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
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# User configuration
DEFAULT_USER=$(whoami)

# BASH_PROFILE CONFIGS

export EDITOR=nano

#export JAVA_HOME=$(/usr/libexec/java_home -v 11)
#export PATH=$JAVA_HOME/bin:$PATH

# General Shortcuts
alias degit='rm -rf ./.git'
alias update-all='source ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/update-all-dependencies.sh'
alias merge-dev='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-develop.sh'
alias merge-main='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-main.sh'
alias merge-release='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-release.sh'
alias rebase-main='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/rebase-main.sh'
alias git-pull='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/git-pull.sh'
alias git-fetch='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/git-fetch.sh'
alias git-clean='git branch --merged | grep -v \* | xargs git branch -d'
alias gas='git add . && git status'
alias bb='bbedit'
alias npmlg='npm list -g --depth=0'
alias ls='ls --color'

# Yarn shortcuts
alias ya='yarn add --exact'
alias yad='yarn add --exact --dev'
alias yr='yarn remove'

# npm shortcuts
alias ni='npm install --save-exact'
alias nid='npm install --save-exact --save-dev'
alias nu='npm uninstall'

# pnpm shortcuts
alias pa='pnpm add --save-exact'
alias pad='pnpm add --save-exact --save-dev'
alias pr='pnpm remove'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

eval "$(gh copilot alias -- zsh)"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
