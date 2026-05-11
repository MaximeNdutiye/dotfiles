# Custom configs for MacOS environments.
# This file will only be executed if the current environment is MacOS.
# Note: `defaults write` commands are in install.sh (run once, not every shell).

# ----------------------------------------------------------------------------
# Pi: auto-match theme to macOS Light/Dark mode.
# Pi has no built-in "system" mode; its `theme` setting is a single string.
# This wrapper syncs ~/.pi/agent/settings.json to current macOS appearance
# every time you launch `pi`.
# ----------------------------------------------------------------------------
_pi_macos_appearance() {
  # `defaults read -g AppleInterfaceStyle` prints "Dark" in dark mode and
  # exits non-zero in light mode (the key is unset).
  if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi dark; then
    printf '%s\n' dark
  else
    printf '%s\n' light
  fi
}

_pi_sync_theme() {
  local settings="$HOME/.pi/agent/settings.json"
  [[ -f $settings ]] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local desired current
  desired=$(_pi_macos_appearance)
  current=$(jq -r '.theme // ""' "$settings" 2>/dev/null)

  [[ $current == $desired ]] && return 0

  local tmp
  tmp=$(mktemp "${settings}.XXXXXX") || return 1
  if jq --arg t "$desired" '.theme = $t' "$settings" > "$tmp"; then
    mv "$tmp" "$settings"
  else
    rm -f "$tmp"
  fi
}

pi() {
  _pi_sync_theme
  command pi "$@"
}
