# Custom environment scripts
# This file is loaded after everything else, but before Antigen is applied and ~/extra.zsh sourced.
# Put anything here that you want to exist on all your environments, and to have the highest priority
# over any other customization.

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

    # Configure these via env vars (e.g. in ~/.config/dotfiles-secrets/.env):
    #   OPENAI_PROXY_URL, AI_PROXY_TEAM_ID, AI_PROXY_PROJECT_ID, AI_PROXY_REPO
    local proxy_url="${OPENAI_PROXY_URL:?OPENAI_PROXY_URL is not set}"
    local team_id="${AI_PROXY_TEAM_ID:?AI_PROXY_TEAM_ID is not set}"
    local project_id="${AI_PROXY_PROJECT_ID:?AI_PROXY_PROJECT_ID is not set}"
    local repo="${AI_PROXY_REPO:-shopify}"
    local environment="${AI_PROXY_ENVIRONMENT:-dev}"

    curl_output=$(curl -si "$proxy_url" \
    -H 'accept: */*' \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer $bearer_token" \
    --data-raw "{\"team\":${team_id},\"project\":${project_id},\"repo\":\"${repo}\",\"environment\":\"${environment}\"}" 2>&1)
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

get_global_auth_token() {
  # Prefer real secrets stored outside the dotfiles repo.
  local secrets_env_file="${HOME}/.config/dotfiles-secrets/.env"
  local repo_env_file="${DF_USER}/.env"
  if [[ -f "$secrets_env_file" ]]; then
    source "$secrets_env_file"
  elif [[ -f "$repo_env_file" ]]; then
    source "$repo_env_file"
  else
    echo "Error: .env file not found at $secrets_env_file or $repo_env_file" >&2
    return 1
  fi

  curl -X POST "https://api.shopify.com/auth/access_token" \
    -H "Content-Type: application/json" \
    -d "{
    \"client_id\": \"${AGENTIC_API_KEY}\",
    \"client_secret\": \"${AGENTIC_APP_SECRET_KEY}\",
    \"grant_type\": \"client_credentials\"
  }"
}

set_global_auth_token() {
  local ucp_env_file="${HOME}/Desktop/.ucp_env"
  local response
  local token

  if ! response=$(get_global_auth_token 2>&1); then
    echo "Error in set_global_auth_token: get_global_auth_token failed" >&2
    echo "$response" >&2
    return 1
  fi

  # Extract the JSON body (get_global_auth_token uses curl without -s,
  # so the output includes the progress meter). Grab from the first `{` onward.
  token=$(echo "$response" | sed -n '/^{/,$p' | jq -r '.access_token')

  if [[ -z "$token" || "$token" == "null" ]]; then
    echo "Error in set_global_auth_token: could not parse access_token from response" >&2
    echo "Response: $response" >&2
    return 1
  fi

  # Ensure the file exists
  touch "$ucp_env_file"

  # Replace existing GLOBAL_AUTH_TOKEN line, or append if missing
  if grep -q '^GLOBAL_AUTH_TOKEN=' "$ucp_env_file"; then
    # Use a temp file for portable in-place edit (macOS sed-friendly)
    local tmp_file
    tmp_file=$(mktemp)
    awk -v token="$token" '
      /^GLOBAL_AUTH_TOKEN=/ { print "GLOBAL_AUTH_TOKEN=" token; next }
      { print }
    ' "$ucp_env_file" > "$tmp_file" && mv "$tmp_file" "$ucp_env_file"
  else
    echo "GLOBAL_AUTH_TOKEN=${token}" >> "$ucp_env_file"
  fi

  echo "GLOBAL_AUTH_TOKEN set in $ucp_env_file"
}

#### ALIASES ####

# Neovim: nvim -> nv
alias nv="nvim"
alias config='/usr/bin/git --git-dir=$DF_HOME --work-tree=$DF_HOME'

# Modern CLI replacements (all guarded so bootstrap works before brew install).
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
else
  alias ll='ls -la'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  export PAGER='bat --style=plain'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v zoxide >/dev/null 2>&1; then
  # Tec/dev may install a cd alias; zoxide needs `cd` to be a function.
  unalias cd 2>/dev/null || true
  _zoxide_bin="$(command -v zoxide)"
  _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zoxide-init.zsh"
  [[ -d "${_zoxide_cache:h}" ]] || mkdir -p "${_zoxide_cache:h}"
  if [[ ! -s "$_zoxide_cache" || "$_zoxide_bin" -nt "$_zoxide_cache" ]]; then
    "$_zoxide_bin" init zsh --cmd cd >| "$_zoxide_cache"
  fi
  source "$_zoxide_cache"
  unset _zoxide_bin _zoxide_cache
fi

if command -v atuin >/dev/null 2>&1; then
  _atuin_bin="$(command -v atuin)"
  _atuin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/atuin-init.zsh"
  [[ -d "${_atuin_cache:h}" ]] || mkdir -p "${_atuin_cache:h}"
  if [[ ! -s "$_atuin_cache" || "$_atuin_bin" -nt "$_atuin_cache" ]]; then
    "$_atuin_bin" init zsh --disable-up-arrow >| "$_atuin_cache"
  fi
  source "$_atuin_cache"
  unset _atuin_bin _atuin_cache
fi

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
