# Lightweight zsh setup — no Oh My Zsh or zinit.
# Plugins are cloned by install.sh/git_repos into:
#   ${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins

_zsh_plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# zsh-completions must be on fpath before compinit runs.
if [[ -d "$_zsh_plugin_dir/zsh-completions/src" ]]; then
  fpath=("$_zsh_plugin_dir/zsh-completions/src" $fpath)
fi

# ── Native completion system ────────────────────────────────────────
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"

# -C skips expensive security and rebuild checks when a dump already exists.
if [[ -f "$_zcompdump" ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
fi

zmodload -i zsh/complist

unsetopt menu_complete   # do not autoselect first completion
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab
setopt complete_in_word  # complete from cursor position
setopt always_to_end     # move cursor to end after completion

# Case-insensitive, partial-word, and substring completion.
zstyle ':completion:*' matcher-list \
  'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  'r:|=*' \
  'l:|=* r:|=*'
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
zstyle ':completion:*:*:*:users' ignored-patterns '_*' daemon nobody
zstyle '*' single-ignored show

# ── fzf shell integration ───────────────────────────────────────────
# fzf's shell scripts restore zle options and are noisy in `zsh -i -c`.
# Only load them for real terminal sessions.
if [[ -t 0 ]]; then
  _fzf_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf/shell"
  [[ -r "$_fzf_prefix/key-bindings.zsh" ]] && source "$_fzf_prefix/key-bindings.zsh"
  [[ -r "$_fzf_prefix/completion.zsh" ]] && source "$_fzf_prefix/completion.zsh"
fi

unset _zsh_plugin_dir _zcompdump _fzf_prefix
