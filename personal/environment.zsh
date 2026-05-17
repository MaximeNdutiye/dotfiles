# Define custom environment variables.
# This will overwrite any environment variables defined by `core/environment.zsh`.

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# Keep Homebrew commands snappy; install.sh still installs/updates explicitly.
export HOMEBREW_NO_AUTO_UPDATE=1
