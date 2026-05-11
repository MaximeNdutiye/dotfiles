# Define important environment variables

# Detect the current OS
# 'darwin' = MacOS
# 'linus'  = linux
export ZSH_HOST_OS=$(uname | awk '{print tolower($0)}')

# Make sure we're saving our history to a file
export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
touch $HISTFILE

# Deduplicate and clean up history
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_REDUCE_BLANKS     # Strip superfluous blanks
setopt HIST_IGNORE_SPACE      # Don't record commands starting with a space
setopt INC_APPEND_HISTORY     # Write immediately, not at shell exit