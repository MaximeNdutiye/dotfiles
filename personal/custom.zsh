# Custom environment scripts
# This file is loaded after everything else, but before Antigen is applied and ~/extra.zsh sourced.
# Put anything here that you want to exist on all your environments, and to have the highest priority
# over any other customization.

# Load zsh-async library
source ~/.antigen/bundles/mafredri/zsh-async-main/async.zsh

#### FUNCTIONS ####

# Set AI Proxy API key
set_openai_api_key() {
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
        API_KEY=$(echo "$curl_output" | sed -n '/^{/,/^}$/p' | jq -r '.key')
        
        echo "$API_KEY" 2>&1
    fi
}

# Callback function for async OpenAI API key setting
set_openai_api_key_async_callback() {
    if [[ -n $3 ]]; then
        export OPENAI_API_KEY=$3
    else
        echo "Error in set_openai_api_key_async" >&2
    fi
}

#### ALIASES ####

# Neovim: nvim -> nv
alias nv="nvim"

#### EDITOR SETTINGS ####

# Set preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
    export VISUAL='nvim'

    # Set up async worker for OpenAI API key
    # async_init
    # async_start_worker openai_worker -n
    # async_job openai_worker set_openai_api_key
    # async_register_callback openai_worker set_openai_api_key_async_callback
fi
