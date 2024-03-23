# Custom actions to take on initial install of dotfiles.
# This runs after default install actions, so you can overwrite changes it makes if you want.

# Install AstroNvim

# need to figure out how not to do this unless specified
# First backup files if needed
if [ -d "~/.config/nvim/lua/astronvim" ]; then
  echo "Astronvim already exists. skipping install"
else
  mv ~/.config/nvim ~/.config/nvim.bak
  mv ~/.local/share/nvim ~/.local/share/nvim.bak
  mv ~/.local/state/nvim ~/.local/state/nvim.bak
  mv ~/.cache/nvim ~/.cache/nvim.bak

  echo "Installing Astronvim"
  git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim

  # link nvim config
  ln -vsfn ~/$DOTFILES_DIRECTORY_NAME/personal/nvim/user ~/.config/nvim/

fi

if [ -d "~/.tmux.plugins/tmp"]
  echo "tmux tmp already exists"
else
  echo "Installing tmux tmp"
  # install tmux plugin manager
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
end
