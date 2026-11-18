HISTSIZE=10000
SAVEHIST=10000

HISTFILE="$HOME/.zsh_history"

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

# Show full date+time stamps when listing history
alias history='fc -li 1'

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt COMPLETE_IN_WORD

unsetopt FLOW_CONTROL
unsetopt BEEP