# Define important environment variables

# XDG Base Directory defaults. .zshenv sets these for all zsh invocations;
# keep them here too for shells that source this file directly.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export PATH="$HOME/.local/bin:$PATH"

# Detect the current OS
# 'darwin' = macOS
# 'linux'  = Linux
export ZSH_HOST_OS="${$(uname):l}"

# Make sure we're saving history to an XDG-compliant location.
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000
export SAVEHIST=100000
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
[[ -e "$HISTFILE" ]] || : > "$HISTFILE"

# Deduplicate and clean up history
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_REDUCE_BLANKS     # Strip superfluous blanks
setopt HIST_IGNORE_SPACE      # Don't record commands starting with a space
setopt INC_APPEND_HISTORY     # Write immediately, not at shell exit
setopt SHARE_HISTORY          # Share history across sessions
setopt AUTO_CD                # Type a directory path to cd into it