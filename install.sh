#!/usr/bin/env zsh

# Runs on setup of a new spin environment.
# Create common color functions.
autoload -U colors
colors

# Create an unversioned script for scripts that are specific to this local environment
# and that you don't want to follow you across environments.
touch ~/extra.zsh

DOTFILES_DIRECTORY_NAME="dotfiles"

export DF_HOME=~/$DOTFILES_DIRECTORY_NAME
export DF_USER=$DF_HOME/personal
export DF_CORE=$DF_HOME/core

HOMEBREW_PACKAGES_FILE=$DF_HOME/homebrew_packages
SYMLINKS_FILE=$DF_HOME/symlink_paths
GIT_REPOS_FILE=$DF_HOME/git_repos

ZSH_HOST_OS=$(uname | awk '{print tolower($0)}')

case $ZSH_HOST_OS in
  darwin*)

  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "\nInstalling homebrew packages\n"
  # Install homebrew packages
  while IFS= read -r homebrew_package_to_install; do
      if brew list "$homebrew_package_to_install" &>/dev/null; then
          echo "$homebrew_package_to_install is already installed"
      else
          brew install "$homebrew_package_to_install"
      fi
  done < "$HOMEBREW_PACKAGES_FILE"
;;
esac

if [ $SPIN ]; then
  # Install Ripgrep for better code searching: `rg <string>` to search. Obeys .gitignore
  echo "Installing packages"

  sudo apt-get install -y ripgrep
fi

# Clone git repos
# Function to clone git repositories from a given file
clone_git_repos() {
    local repos_file="$1"
    echo "\nCloning git repos from $repos_file\n"
    while IFS= read -r git_repo_and_target_path; do
        repo_url=$(echo "$git_repo_and_target_path" | cut -d' ' -f1)
        # We need to do this so it expands them correctly
        eval target_clone_path=$(echo "$git_repo_and_target_path" | cut -d' ' -f2)

        if [ ! -d "$target_clone_path" ]; then
            echo "Cloning $repo_url to $target_clone_path"
            git clone --depth 1 "$repo_url" "$target_clone_path"
        fi
    done < "$repos_file"
}

clone_git_repos "$GIT_REPOS_FILE"

# Set up symlinks --needs to happen last--
echo "\nSetting up symlinks\n"
while IFS= read -r symlink_path; do
    eval source_path=$(echo "$symlink_path" | cut -d' ' -f1)
    eval target_path=$(echo "$symlink_path" | cut -d' ' -f2)

    ln -vsfn $source_path $target_path
done < "$SYMLINKS_FILE"

source ~/.zshrc
