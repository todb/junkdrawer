# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile-53161
HISTSIZE=3000
SAVEHIST=3000
bindkey -v
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

# zsh-git-prompt

source $HOME/git/zsh-git-prompt/zshrc.sh
PROMPT='%B%m:%~%b$(git_super_status)
%# '

# Start lines added by todb

EDITOR=vim
VISUAL=vim
source $HOME/.zsh_aliases
# RVM

source $HOME/.rvm/scripts/rvm
