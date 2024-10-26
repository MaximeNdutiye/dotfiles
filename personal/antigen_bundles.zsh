# Additional oh-my-zsh plugins to include
# Default bundles included can be seen in core/default_bundles.zsh
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins for available oh-my-zsh plugins.
# See https://github.com/zsh-users/antigen/wiki/Commands#antigen-bundle for instructions on including custom plugins. 
#
# Include a plugin with `antigen bundle <plugin-name>`.

# Do not wrap `antigen theme` or `antigen bundle` in conditions. Antigen has cache invalidation issues.
# If you want to conditionally load bundles, uncomment the following line:
# ANTIGEN_CACHE=false
# You can read more in https://github.com/zsh-users/antigen/wiki/Commands#antigen-theme for info on how to define
# custom caching keys for different environments, if you desire that. The cache speeds up your terminal startup, so
# try to avoid disabling the cache unless you have no other choice.
ANTIGEN_LOG=~/$DOTFILES_DIRECTORY_NAME/antigen_log

# ZSH Theme
antigen theme MaximeNdutiye/dotfiles themes/af-magic

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundles <<EOBUNDLES
  git-auto-fetch
  mafredri/zsh-async --branch=main
EOBUNDLES

# zsh autocomplete
# This thing is so so slow. Constantly holds up my command prompt
# antigen bundle marlonrichert/zsh-autocomplete --branch=main
