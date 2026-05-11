#!/usr/bin/env zsh

# Runs on setup of a new development environment.
autoload -U colors
colors

# Create an unversioned script for scripts that are specific to this local environment
touch ~/extra.zsh

DOTFILES_DIRECTORY_NAME="dotfiles"

export DF_HOME=~/$DOTFILES_DIRECTORY_NAME
export DF_USER=$DF_HOME/personal
export DF_CORE=$DF_HOME/core

HOMEBREW_PACKAGES_FILE=$DF_HOME/homebrew_packages
SYMLINKS_FILE=$DF_HOME/symlink_paths
GIT_REPOS_FILE=$DF_HOME/git_repos

ZSH_HOST_OS=$(uname | awk '{print tolower($0)}')

# ── Homebrew ─────────────────────────────────────────────────────────
case $ZSH_HOST_OS in
  darwin*)
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "\nInstalling homebrew packages\n"
  while IFS= read -r homebrew_package_to_install; do
      [[ -z "$homebrew_package_to_install" || "$homebrew_package_to_install" == \#* ]] && continue
      if brew list "$homebrew_package_to_install" &>/dev/null; then
          echo "$homebrew_package_to_install is already installed"
      else
          brew install "$homebrew_package_to_install"
      fi
  done < "$HOMEBREW_PACKAGES_FILE"
;;
esac

# ── Zinit ────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  echo "\nInstalling zinit\n"
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Remove old antigen if present
if [[ -d "$HOME/antigen" ]]; then
  echo "\nRemoving old antigen installation\n"
  rm -rf "$HOME/antigen"
fi

# ── Git repos ────────────────────────────────────────────────────────
clone_git_repos() {
    local repos_file="$1"
    echo "\nCloning git repos from $repos_file\n"
    while IFS=' ' read -r repo_url raw_target; do
        [[ -z "$repo_url" || "$repo_url" == \#* ]] && continue
        # Expand ~ to $HOME safely (no eval)
        local target_clone_path="${raw_target/#\~/$HOME}"

        if [ ! -d "$target_clone_path" ]; then
            echo "Cloning $repo_url to $target_clone_path"
            git clone --depth 1 "$repo_url" "$target_clone_path"
        fi
    done < "$repos_file"
}

clone_git_repos "$GIT_REPOS_FILE"

# ── Symlinks ─────────────────────────────────────────────────────────
setup_symlinks() {
    local symlinks_file="$1"
    echo "\nSetting up symlinks\n"
    while IFS='|' read -r raw_source raw_target; do
        [[ -z "$raw_source" || "$raw_source" == \#* ]] && continue
        # Expand ~ and $DOTFILES_DIRECTORY_NAME safely (no eval)
        local source_path="${raw_source/#\~/$HOME}"
        source_path="${source_path//\$DOTFILES_DIRECTORY_NAME/$DOTFILES_DIRECTORY_NAME}"
        local target_path="${raw_target/#\~/$HOME}"
        target_path="${target_path//\$DOTFILES_DIRECTORY_NAME/$DOTFILES_DIRECTORY_NAME}"

        # Ensure parent directory exists
        mkdir -p "$(dirname "$target_path")"
        ln -vsfn "$source_path" "$target_path"
    done < "$symlinks_file"
}

setup_symlinks "$SYMLINKS_FILE"

# ── macOS preferences (run once at install, not every shell) ─────────
case $ZSH_HOST_OS in
  darwin*)
    # Faster keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain InitialKeyRepeat -int 12
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles YES
    # Always show POSIX path in Finder title
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    echo "macOS defaults written. Some changes require logout/restart."
  ;;
esac

source ~/.zshrc
