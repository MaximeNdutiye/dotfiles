# ZLE plugins sourced after initial prompt for faster perceived startup.
# Keep syntax highlighting last.

_dotfiles_load_zle_plugins() {
  local _zsh_plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

  if [[ -r "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  if [[ -r "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi

  unfunction _dotfiles_load_zle_plugins 2>/dev/null || true
}

# Load shortly after the first prompt instead of blocking shell startup.
if zmodload zsh/sched 2>/dev/null; then
  sched +1 _dotfiles_load_zle_plugins
else
  _dotfiles_load_zle_plugins
fi
