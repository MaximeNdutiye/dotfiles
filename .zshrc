# This script is run every time you log in. It's the entrypoint for all shell environment config.
# Don't modify this file directly, or you'll remove your ability to update against new versions of
# the dotfiles-starter-template

# use this for profiling. Also uncomment the zprof line below
# zmodload zsh/zprof

export DOTFILES_DIRECTORY_NAME="dotfiles"
export DF_HOME=~/$DOTFILES_DIRECTORY_NAME
export DF_CORE=$DF_HOME/core
export DF_USER=$DF_HOME/personal

# Static Homebrew environment (faster than `brew shellenv` on every shell).
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  export MANPATH="/opt/homebrew/share/man:${MANPATH:-}"
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
elif [[ -d /usr/local/Homebrew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
  export HOMEBREW_CELLAR="/usr/local/Cellar"
  export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
  export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

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

# Load lightweight zsh completions/plugins directly (no zinit/Oh My Zsh).
source $DF_CORE/default_bundles.zsh

# Prompt setup (Starship when installed, tiny fallback otherwise).
source $DF_USER/antigen_bundles.zsh

source $DF_CORE/utils.zsh

# Load custom dircolors, if present
if [ -e $DF_USER/dircolors ] && command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors "$DF_USER/dircolors")"
fi

# Tec/dev/shadowenv can add wrapper aliases; load it before personal aliases
# so modern CLI aliases in personal/custom.zsh win.
[[ -x "$HOME/.local/state/tec/profiles/base/current/global/init" ]] && eval "$("$HOME/.local/state/tec/profiles/base/current/global/init" zsh)"

source $DF_CORE/filter_history.zsh

source $DF_USER/custom.zsh

# ZLE plugins should load after custom widgets/keybindings.
source $DF_CORE/zle_plugins.zsh

# Load changes specific to this local environment.
[[ -f ~/extra.zsh ]] && source ~/extra.zsh

# chruby for homebrew
# source /usr/local/opt/chruby/share/chruby/chruby.sh

# Dev
[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }

# Lazy-load Shopify dev only when the `dev` command is used.
if [[ -f /opt/dev/dev.sh ]] && ! command -v dev >/dev/null 2>&1; then
  dev() {
    unfunction dev
    source /opt/dev/dev.sh
    dev "$@"
  }
fi

# Shopify Hydrogen alias to local projects
alias h2='$(npm prefix -s)/node_modules/.bin/shopify hydrogen'

# use this for profiling
# zprof

#export PATH="/opt/homebrew/opt/curl/bin:$PATH"

alias ai-dash='cargo run --manifest-path ~/src/github.com/shopify-playground/ai-dash-rs/Cargo.toml --'
