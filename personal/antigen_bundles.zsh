# Additional zinit plugins for personal use.
# Default bundles are loaded in core/default_bundles.zsh.
# See https://github.com/zdharma-continuum/zinit for full syntax.

ZINIT_LOG=~/$DOTFILES_DIRECTORY_NAME/zinit_log

# ── Theme ────────────────────────────────────────────────────────────
# Load the af-magic theme from this repo
zinit snippet "$DF_HOME/themes/af-magic.zsh-theme"

# ── Extra plugins ────────────────────────────────────────────────────
# Async worker library (used by set_openai_api_key_async, etc.)
zinit light mafredri/zsh-async
