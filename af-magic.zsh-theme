# af-magic.zsh-theme
#
# Author: Andy Fleming
# URL: http://andyfleming.com/

# settings
typeset +H my_gray="$FG[237]"
typeset +H my_orange="$FG[214]"

# primary prompt
PS1='$FG[237]%{$reset_color%}
$FG[032]%~$(git_prompt_info)$(hg_prompt_info)$FG[105]%(!.#.»)%{$reset_color%} '
PS2='%{$fg[red]%} %{$reset_color%}'

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX=" ${FG[075]}(${FG[078]}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="${FG[214]}*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${FG[075]})%{$reset_color%}"

# hg settings
ZSH_THEME_HG_PROMPT_PREFIX=" ${FG[075]}(${FG[078]}"
ZSH_THEME_HG_PROMPT_CLEAN=""
ZSH_THEME_HG_PROMPT_DIRTY="${FG[214]}*%{$reset_color%}"
ZSH_THEME_HG_PROMPT_SUFFIX="${FG[075]})%{$reset_color%}"

# virtualenv settings
ZSH_THEME_VIRTUALENV_PREFIX=" ${FG[075]}["
ZSH_THEME_VIRTUALENV_SUFFIX="]%{$reset_color%}"
