export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  elif [[ $(nvm version) != $(nvm version default)  ]]; then
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Detect CPU Architecture
# arch_name="$(uname -m)"

# if [ "${arch_name}" = "x86_64" ]; then
#     if [ "$(sysctl -in sysctl.proc_translated)" = "1" ]; then
#         # echo "Running on Rosetta 2"
#         IS_ROSETTA=true
#         IS_INTEL=false
#         IS_ARM=false
#     else
#         # echo "Running on native Intel"
#         IS_ROSETTA=false
#         IS_INTEL=true
#         IS_ARM=false
#     fi
# elif [ "${arch_name}" = "arm64" ]; then
#     # echo "Running on ARM"
#         IS_ROSETTA=false
#         IS_INTEL=false
#         IS_ARM=true
# else
#     # echo "Unknown architecture: ${arch_name}"
#         IS_ROSETTA=false
#         IS_INTEL=false
#         IS_ARM=false
# fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"

# POWERLEVEL9K_MODE='nerdfont-complete'
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir nvm vcs newline time status)
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time battery)
# POWERLEVEL9K_DISABLE_RPROMPT=true
# POWERLEVEL9K_BATTERY_VERBOSE=false
# POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
# POWERLEVEL9K_SHORTEN_DELIMITER=""
# POWERLEVEL9K_SHORTEN_STRATEGY="truncate_from_right"
# POWERLEVEL9K_TIME_FORMAT="%D{%H:%M %p}"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sudo macos z zsh-autosuggestions zsh-syntax-highlighting)

# User configuration
DEFAULT_USER=$(whoami)

# export PATH="/usr/local/sbin:$HOME/.gvm/vertx/current/bin:$HOME/.gvm/springboot/current/bin:$HOME/.gvm/lazybones/current/bin:$HOME/.gvm/jbake/current/bin:$HOME/.gvm/groovyserv/current/bin:$HOME/.gvm/groovy/current/bin:$HOME/.gvm/griffon/current/bin:$HOME/.gvm/grails/current/bin:$HOME/.gvm/gradle/current/bin:$HOME/.gvm/glide/current/bin:$HOME/.gvm/gaiden/current/bin:$HOME/.gvm/crash/current/bin:$HOME/.gvm/asciidoctorj/current/bin:./node_modules/.bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Library/Ruby/Gems/2.0.0:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# BASH_PROFILE CONFIGS

export EDITOR=nano

# export M2_HOME=$(brew --prefix maven)/libexec
# export M2=$M2_HOME/bin
# export MAVEN_HOME=$M2_HOME

# ulimit -n 2048

# export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
# export JAVA_10_HOME=$(/usr/libexec/java_home -v10)
# export JAVA_9_HOME=$(/usr/libexec/java_home -v9)

# alias java11='export JAVA_HOME=$JAVA_11_HOME'
# alias java10='export JAVA_HOME=$JAVA_10_HOME'
# alias java9='export JAVA_HOME=$JAVA_9_HOME'

# default java11
# export JAVA_HOME=$JAVA_11_HOME
# export JAVA_HOME=$(/usr/libexec/java_home)

# alias ql='quick-look'

# export ANDROID_HOME=$HOME/Library/Android/sdk
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/tools/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools

alias degit='rm -rf ./.git'
alias update-all='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/update-all-dependencies.sh'
alias merge-dev='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-develop.sh'
alias merge-main='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-main.sh'
alias merge-release='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/merge-release.sh'
alias git-pull='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/git-pull.sh'
alias git-fetch='sh ~/Library/Mobile\ Documents/com~apple~CloudDocs/bin/git-fetch.sh'
alias bb='bbedit'
alias npmlg='npm list -g --depth=0'

# export PATH=$PATH:/Library/Ruby/Gems/2.0.0

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

# git shortcuts
alias gas='git add . && git status'

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
#[[ -s "$HOME/.gvm/bin/gvm-init.sh" ]] && source "$HOME/.gvm/bin/g$
#export PATH="/usr/local/sbin:/usr/local/bin:/usr/local/opt:$PATH"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# if $IS_ARM ; then
# 	source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# 	export PATH="/opt/homebrew/bin:$PATH"
# else
# 	source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(gh copilot alias -- zsh)"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
