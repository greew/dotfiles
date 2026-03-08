# Path
export PATH="$HOME/.local/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="wedisagree"

plugins=(
  common-aliases
  aliases
  docker-compose
  git
  gitfast
  zsh-autosuggestions
)

ZSH_TMUX_AUTOSTART=false
ZSH_DISABLE_COMPFIX=true

# Source machine-local pre-OMZ overrides (add plugins, change theme, etc.)
[ -f ~/.zshrc.local.pre ] && source ~/.zshrc.local.pre

source $ZSH/oh-my-zsh.sh

# Editor
export VISUAL="vim"
export EDITOR="$VISUAL"

# Aliases
alias ls="eza -lhBa --icons --group-directories-first --git"
alias lls="/bin/ls"

# Git shortcuts
alias gfc='__gco() { local branch=$(echo "$*" | sed "s/git checkout //"); git fetch; git checkout "$branch"; unset -f __gco; }; __gco'
alias gsp="git branch --merged origin/master | grep -Ev '^ *\*? *master$'"
alias gspp="gsp | xargs git branch -d"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Source machine-local overrides (aliases, functions, etc.)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
