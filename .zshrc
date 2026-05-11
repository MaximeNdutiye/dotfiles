# This script is run every time you log in. It's the entrypoint for all shell environment config.
# Don't modify this file directly, or you'll remove your ability to update against new versions of
# the dotfiles-starter-template

# use this for profiling. Also uncomment the zprof line below
# zmodload zsh/zprof

export DOTFILES_DIRECTORY_NAME="dotfiles"
export DF_HOME=~/$DOTFILES_DIRECTORY_NAME
export DF_CORE=$DF_HOME/core
export DF_USER=$DF_HOME/personal

# Create common color functions.
# autoload -U colors
# colors

# Enable vi mode
# bindkey -v

# Set up custom environment variables
source $DF_CORE/environment.zsh
source $DF_USER/environment.zsh

# Load real secrets from outside the (public) dotfiles repo, if present.
[ -f "$HOME/.config/dotfiles-secrets/.env" ] && source "$HOME/.config/dotfiles-secrets/.env"

# Load color helper variable definitions
source $DF_CORE/formatting.zsh

# Load configs for MacOS. Does nothing if not on MacOS
if [ "$ZSH_HOST_OS" = "darwin" ]; then
  source $DF_CORE/macos.zsh
  if [ -e $DF_USER/macos.zsh ]; then
    source $DF_USER/macos.zsh
  fi
fi

# Load zsh plugins via zinit
source $DF_CORE/default_bundles.zsh
source $DF_USER/antigen_bundles.zsh

source $DF_CORE/utils.zsh

# Load custom dircolors, if present
if [ -e $DF_USER/dircolors ]; then
  eval $(dircolors $DF_USER/dircolors)
fi

source $DF_CORE/filter_history.zsh

source $DF_USER/custom.zsh

# Load changes specific to this local environment.
source ~/extra.zsh

# chruby for homebrew
# source /usr/local/opt/chruby/share/chruby/chruby.sh

# Dev
[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }

[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

[ -f /opt/dev/dev.sh ] && source /opt/dev/dev.sh

# Shopify Hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# use this for profiling
# zprof

# Added by tec agent
[[ -x "$HOME/.local/state/tec/profiles/base/current/global/init" ]] && eval "$("$HOME/.local/state/tec/profiles/base/current/global/init" zsh)"

#export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# fixes the prompt not showing up in the terminal
add-zsh-hook -d precmd prompt_grml_precmd

alias ai-dash='cargo run --manifest-path ~/src/github.com/shopify-playground/ai-dash-rs/Cargo.toml --'
