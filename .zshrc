# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

if [[ -f /opt/dev/dev.sh ]]; then source /opt/dev/dev.sh; fi

# start tmux
if [[ $TERM != "screen" && ! $TMUX ]]; then
    tmux
fi

# Path to your oh-my-zsh installation.
export ZSH="/Users/maximendutiye/.oh-my-zsh"

#### ALIASES #####

# Neovim: nvim -> nv
alias nv="nvim"

# git aliases
alias gitlog="git log --all --decorate --oneline --graph"
alias gitdiffm="git fetch origin master && git diff origin/master"

# Check for errors with code
alias yarncheck="yarn run eslint && yarn run tsc"
alias yarnfix="yarn run eslint --fix"
alias checkcode="yarn run eslint && yarn run tsc && rubocop"

# GIT PULL REBASE AUTO
# Rebase with automatic corrections
# $1 ours (favour current changes) | theirs
# $2 branch to pull from, probably master
# alias gpra="git pull --rebase --strategy-option $1 origin $2"

# GIT PULL AUTO
# alias gpa="git pull --strategy-option $1 origin $2"

# Kubectl commands
alias getpods="kubectl get pods --namespace=identity-staging"

gwl() { kubectl logs "$1" web -n identity-staging; }
grl() { kubectl logs "$1" rails -n identity-staging; }
gnl() { kubectl logs "$1" nginx -n identity-staging }
gjl() { kubectl logs "$1" -n identity-staging; }

alias create_db_snapshot="./script/db_snapshot dump"
alias amr="./script/db_snapshot load && dev u && dev s"
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh
#eval "$(rbenv init -)"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# cloudplatform: add Shopify clusters to your local kubernetes config
export KUBECONFIG=${KUBECONFIG:+$KUBECONFIG:}/Users/maximendutiye/.kube/config:/Users/maximendutiye/.kube/config.shopify.cloudplatform
if [ /usr/local/bin/kubectl ]; then source <(kubectl completion zsh); fi
