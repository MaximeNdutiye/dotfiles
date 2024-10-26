# Define any custom environment scripts here.
# This file is loaded after everything else, but before Antigen is applied and ~/extra.zsh sourced.
# Put anything here that you want to exist on all your environment, and to have the highest priority
# over any other customization.

# Load zsh-async library
source ~/.antigen/bundles/mafredri/zsh-async-main/async.zsh

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
    local curl_output
    local curl_exit_code
    local bearer_token

    if ! bearer_token=$(gcloud auth print-identity-token 2>&1); then
        echo "Error in set_openai_api_key: gcloud auth failed" >&2
        echo "gcloud output: $bearer_token" >&2
        return 1
    fi

    curl_output=$(curl -si 'https://openai-proxy.shopify.io/hmac/team' \
    -H 'accept: */*' \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer $bearer_token" \
    --data-raw '{"team":1526,"project":39580,"repo":"shopify","environment":"dev"}' 2>&1)
    curl_exit_code=$?

    if [ $curl_exit_code -ne 0 ]; then
        echo "Error in set_openai_api_key: curl command failed" >&2
        echo "Curl output: $curl_output" >&2
    else
        OPENAI_API_KEY=$(echo "$curl_output" | sed -n '/^{/,/^}$/p' | jq -r '.key')
        export OPENAI_API_KEY
    fi
}

set_openai_api_key_async_callback() {
    if [[ -n $3 ]]; then
        echo "Error in set_openai_api_key_async: $3" >&2
    else
        export OPENAI_API_KEY=$2
    fi
}

# Neovim: nvim -> nv
alias nv="nvim"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'

  # Set up async worker
  async_init
  async_start_worker openai_worker -n
  async_job openai_worker set_openai_api_key
  async_register_callback openai_worker set_openai_api_key_async_callback
 
  # Launch tmux
  # if  [ -n "$TERM" ] && command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  #   echo "launching tmux"
  #   exec tmux
  # fi
fi
