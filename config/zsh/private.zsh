# ==============================================================================
# PRIVATE MODE (~/.zshrc)
# ==============================================================================
# Fish-like private mode: while on, commands typed in this shell are not added
# to the in-session history, not written to HISTFILE and not recallable.
#
#   private            show status
#   private on         pause history for this shell
#   private off        resume history (this line is kept as an audit marker)
#   private toggle     flip the current state
#
# The state is a normal (non-exported) shell variable, so every new tab,
# window, child shell or `exec zsh` starts public. STARSHIP_PRIVATE is exported
# only to drive the prompt badge.
#
# NOTE: zsh 5.9 has a `private` builtin (`private foo=bar`). The function below
# shadows it for interactive use. `builtin private` still reaches the real
# builtin; this config does not rely on it.
# ==============================================================================

# Startup guard: reset only in a brand-new shell. Re-sourcing ~/.zshrc while
# private must not silently turn history back on.
if (( ! ${+_ZSH_PRIVATE} )); then
  typeset -gi _ZSH_PRIVATE=0
  unset STARSHIP_PRIVATE
fi

# zshaddhistory runs before the line is executed and before it is stored.
# Return 1 = keep it out of the history list, HISTFILE and recall.
_zsh_private_addhistory() {
  (( _ZSH_PRIVATE )) || return 0

  # Keep the control command itself as an audit marker. Anything else on the
  # same line (e.g. `private off && secret`) is not exempt.
  local line=$1
  line=${line#"${line%%[![:space:]]*}"}
  line=${line%"${line##*[![:space:]]}"}
  case $line in
    private|private\ on|private\ off|private\ toggle|private\ status)
      return 0
      ;;
  esac

  return 1
}

autoload -Uz add-zsh-hook
add-zsh-hook zshaddhistory _zsh_private_addhistory

private() {
  emulate -L zsh
  case ${1:-status} in
    on)
      _ZSH_PRIVATE=1
      export STARSHIP_PRIVATE=1
      print -r -- 'Private mode ON - history paused for this shell'
      ;;
    off)
      _ZSH_PRIVATE=0
      unset STARSHIP_PRIVATE
      print -r -- 'Private mode off - history resumed'
      ;;
    toggle)
      if (( _ZSH_PRIVATE )); then
        private off
      else
        private on
      fi
      ;;
    status)
      if (( _ZSH_PRIVATE )); then
        print -r -- 'private mode: ON'
      else
        print -r -- 'private mode: off'
      fi
      ;;
    *)
      print -u2 'usage: private [on|off|toggle|status]'
      return 1
      ;;
  esac
}
