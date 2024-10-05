# Define any custom environment scripts here.
# This file is loaded after everything else, but before Antigen is applied and ~/extra.zsh sourced.
# Put anything here that you want to exist on all your environment, and to have the highest priority
# over any other customization.

#### ALIASES #####

set_env_based_on_directory() {
    # Uses alternative git global config when not interacting with shopify repos.
    if [[ "$PWD" =~ "^/Users/$USER/*" ]] && ! [[ "$PWD" =~ "^/Users/$USER/src/*" ]] ; then
        export GIT_CONFIG_GLOBAL=$DF_HOME/configs/.gitconfig
        export GIT_IGNORE_GLOBAL=$DF_HOME/configs/.gitignore_global
    else
        export GIT_CONFIG_GLOBAL=~/.gitconfig
        export GIT_IGNORE_GLOBAL=~/.gitignore_global
    fi
}

precmd_functions+=(set_env_based_on_directory)

set_openai_api_key(){
    export OPENAI_API_KEY=$(
    curl -i 'https://openai-proxy.shopify.io/hmac/team' \
    -H 'accept: */*' \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
    --data-raw '{"team":1526,"project":39580,"repo":"shopify","environment":"dev"}' | sed -n '/^{/,/^}$/p' | jq -r '.key')
}

# Neovim: nvim -> nv
alias nv="nvim"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'

  set_openai_api_key > /dev/null 2>&1
  
  # Launch tmux
  if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
    exec tmux
  fi
fi
