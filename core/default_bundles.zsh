# Zsh plugins managed by zinit (https://github.com/zdharma-continuum/zinit)
# Additional plugins can be found at https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins

# Bootstrap zinit if not installed
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── oh-my-zsh libs (lightweight foundation) ──────────────────────────
zinit snippet OMZL::git.zsh
zinit snippet OMZL::theme-and-appearance.zsh
zinit snippet OMZL::spectrum.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::key-bindings.zsh

# ── oh-my-zsh plugins ───────────────────────────────────────────────
# Rails & Rake autocompletion
zinit snippet OMZP::rails

# Ripgrep completions are installed by homebrew into site-functions automatically.

# Ruby shortcuts
zinit snippet OMZP::ruby

# Prefix a command with sudo by double-tapping ESC
zinit snippet OMZP::sudo

# ── Community plugins ────────────────────────────────────────────────
# Syntax highlighting — loaded last (deferred) for speed
zinit light zsh-users/zsh-syntax-highlighting
