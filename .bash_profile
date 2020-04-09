if [[ -f /opt/dev/dev.sh ]]; then source /opt/dev/dev.sh; fi

# Remove computer name form terminal
export PS1="\W >>"

# start zsh
zsh

# add vs code to path
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if [ -e /Users/maximendutiye/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/maximendutiye/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"

