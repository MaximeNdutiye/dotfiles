# Search in history based on a partially written command.

# Share history across sessions (imports new entries from other shells on each prompt).
# Note: SHARE_HISTORY implies INC_APPEND_HISTORY, so the setopt in
# environment.zsh is harmless but redundant — kept for clarity.
setopt SHARE_HISTORY

# Bind up arrow
bindkey '\eOA' history-beginning-search-backward
bindkey '\e[A' history-beginning-search-backward

# Bind down arrow
bindkey '\eOB' history-beginning-search-forward
bindkey '\e[B' history-beginning-search-forward