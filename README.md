# Dotfiles

Modern zsh/tmux/neovim/terminal setup with no Oh My Zsh or zinit dependency.

## What this uses

- Native zsh completion/key binding configuration
- Directly sourced small zsh plugins:
  - `zsh-users/zsh-autosuggestions`
  - `zsh-users/zsh-syntax-highlighting`
  - `zsh-users/zsh-completions`
- [Starship](https://starship.rs/) for a fast prompt
- Modern CLI replacements: `eza`, `bat`, `fd`, `rg`, `zoxide`, `atuin`, `delta`, `btop`

## Installation

1. Clone the repo to `~/dotfiles`.
2. Run:
   ```sh
   ./install.sh
   ```
3. Open a new terminal or run:
   ```sh
   exec zsh
   ```

`install.sh` installs Homebrew packages, clones small helper repos/plugins, sets up symlinks from `symlink_paths`, and writes a few macOS defaults.

## Layout

- `.zshenv` — minimal XDG/path env loaded by all zsh invocations
- `.zshrc` — interactive shell entrypoint
- `core/` — shared shell framework, completions, keybindings, utilities
- `personal/` — machine/user-level customizations
- `personal/nvim/` — Neovim config
- `personal/tmux/` — tmux config
- `configs/` — global git config/ignore files
- `homebrew_packages` — packages installed by bootstrap
- `git_repos` — plugin/helper repos cloned by bootstrap
- `symlink_paths` — source/target symlink map

## Secrets

Never commit real secrets. Use:

```sh
~/.config/dotfiles-secrets/.env
```

with `chmod 600`. `personal/.env` is gitignored and is only a local fallback.

## Updating zsh plugins

Plugins are plain git repos under `~/.local/share/zsh/plugins`; update them with normal git commands or rerun the clone step in `install.sh` after deleting a plugin directory.
