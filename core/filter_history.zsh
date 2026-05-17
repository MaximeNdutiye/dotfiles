# History search and key bindings. Native zsh only — no Oh My Zsh.

bindkey -e  # emacs mode

# Prefix-aware history search with arrow keys.
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '\eOA' up-line-or-beginning-search
bindkey '\eOB' down-line-or-beginning-search

# Common terminal navigation bindings.
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^?' backward-delete-char
bindkey ' ' magic-space

# Edit the current command line in $VISUAL/$EDITOR.
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# Double-ESC to prepend sudo to the current command.
sudo-command-line() {
  [[ -z "$BUFFER" ]] && BUFFER="$(fc -ln -1)"
  BUFFER="sudo $BUFFER"
  zle end-of-line
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line
