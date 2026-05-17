# Set up OSX specific configs

case $ZSH_HOST_OS in
	darwin*)

	# GNU coreutils — cache the prefix so we don't fork `brew` on every shell
	_brew_coreutils="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/coreutils"
	export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:${_brew_coreutils}/libexec/gnubin:$PATH"
	export MANPATH="${_brew_coreutils}/libexec/gnuman:$MANPATH"
	unset _brew_coreutils

	# Prefer eza when installed; otherwise fall back to GNU ls.
	if command -v eza >/dev/null 2>&1; then
		alias ls='eza --icons --group-directories-first'
	else
		alias ls='gls --color=auto'
	fi

	# Aliases
	alias stfu="osascript -e 'set volume output muted true'"
	alias flushdns="dscacheutil -flushcache"
;;
esac
