#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/streamer/.lmstudio/bin"
# End of LM Studio CLI section


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
