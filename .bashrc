#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export XDG_CONFIG_HOME="$HOME/.config"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
# PS1='[\u@\h \W]\$ '
PS1='[\u@\[\e[31m\]\h\[\e[0m\] \W]\$ '

PERSONAL="$XDG_CONFIG_HOME/personal"
# for i in `find -L $PERSONAL -type f`; do
    # source $i
# done

PROMPT_COMMAND="history -a"
shopt -s histappend

# if [[ $- == *i* && -z $INSIDE_EMACS ]]; then
#     [ -f ~/.fzf.bash ] && source ~/.fzf.bash
#     bind '"\C-h":"tmux-sessionizer\n"'
# fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    # alias dir='dir --color=auto'
    # alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

alias copy="xclip -selection clipboard < $1"

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/streamer/.lmstudio/bin"
# End of LM Studio CLI section


alias claude-mem='/home/streamer/.bun/bin/bun "/home/streamer/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
