Uses [oh-my-zsh](https://ohmyz.sh/) snippets with [zinit](https://github.com/zdharma-continuum/zinit) to manage zsh plugins and themes.
Default theme is [af-magic](themes/af-magic.zsh-theme).

### Installation
1. Clone the repo to `~/dotfiles`:
```
git clone https://github.com/Shopify/dotfiles-starter-template.git ~/dotfiles
```
2. Run `install.sh`. This will install zinit, homebrew packages, symlink configs, and set macOS defaults.
3. Open a new terminal, or `exec zsh`. Zinit will download plugins on first load.

To make your own copy to save your customizations, create a branch with your Github handle to the [dotfiles repo](https://github.com/Shopify/dotfiles), and push to it.

### Update
If you've made your own copy, you can still pull updates from the main repo by creating an `upstream` origin.

```
git remote add upstream https://github.com/Shopify/dotfiles-starter-template
```

Updating your copy can be done with:
```
git pull upstream main --rebase
```

### Customization
The `core` directory contains the framework scripts. Don't alter these unless you want to leave the upgrade path and
do your own thing.

The `personal` directory is where all of your customizations should go. The main repo will not alter these significantly,
so you should be able to easily resolve any merge conflicts during an update.

#### Available customizations
Files are listed in the order they are loaded. Conflicts between files, such as
environment variable definitions, will be resolved by "last definition wins".

Load order can be seen in `.zshrc`.

- `environment.zsh`: Define any environment variables you always want.
- `macos.zsh`: Customizations that should only be run on MacOS.
- `antigen_bundles.zsh`: Define additional zsh plugins (via zinit). Your theme selection should be set here as well.
- `dircolors`: Define a custom dircolors file. Optional, falls back to system default.
- `custom.zsh`: Customizations that should apply everywhere. This is the LAST file
loaded, so any conflicting changes made here will override any previous files.

#### Secrets
Never commit real secrets. Use `~/.config/dotfiles-secrets/.env` (chmod 600) for API keys and tokens.
`personal/.env` is gitignored and serves as a local fallback.
