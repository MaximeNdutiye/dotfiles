# Prompt setup. Kept at this path for backwards compatibility with .zshrc,
# but this file no longer uses Antigen, Oh My Zsh, or zinit.

if command -v starship >/dev/null 2>&1; then
  _starship_bin="$(command -v starship)"
  _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/starship-init.zsh"
  [[ -d "${_starship_cache:h}" ]] || mkdir -p "${_starship_cache:h}"

  if [[ ! -s "$_starship_cache" || "$_starship_bin" -nt "$_starship_cache" ]]; then
    "$_starship_bin" init zsh >| "$_starship_cache"
  fi

  source "$_starship_cache"
  unset _starship_bin _starship_cache
else
  # Tiny fallback prompt when starship is not installed yet.
  autoload -U colors && colors
  setopt prompt_subst
  PROMPT='%F{cyan}%~%f %(!.#.») '
fi
