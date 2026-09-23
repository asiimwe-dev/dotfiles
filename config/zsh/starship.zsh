# ==============================================================================
# STARSHIP & TERMINAL INTEGRATION (~/.zshrc)
# ==============================================================================

# 0. Transient prompt toggle.
#    STARSHIP_TRANSIENT=1  -> executed prompts collapse to a clean cyan arrow (opt-in)
#    STARSHIP_TRANSIENT=0  -> full prompt stays visible after each command (default)
#    The choice is persisted to ~/.local/state/starship.transient (XDG_STATE_HOME),
#    so it survives terminal restarts until you toggle it again.
#    Toggle at runtime with:  starship-transient   (collapse on)
#                             starship-full        (keep visible)
#                             starship-reset       (clear persisted state -> default)
_STARSHIP_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/starship.transient"
if [[ -f "$_STARSHIP_STATE" ]]; then
  export STARSHIP_TRANSIENT="$(< "$_STARSHIP_STATE")"
else
  export STARSHIP_TRANSIENT="${STARSHIP_TRANSIENT:-0}"
fi

# 1. Fix right-prompt trailing space margin in Zsh
export ZLE_RPROMPT_INDENT=0

# Load Zsh hook utilities
autoload -Uz add-zsh-hook
autoload -Uz add-zle-hook-widget

# ------------------------------------------------------------------------------
# 2. Window Title Hook (Preserves exit status $?)
# ------------------------------------------------------------------------------
function _starship_win_title() {
  local _status=$?
  print -Pn "\e]0;%~\a"
  return $_status
}
add-zsh-hook precmd _starship_win_title

# ------------------------------------------------------------------------------
# 3. Transient Prompt (Collapses executed prompts to a clean cyan arrow)
# ------------------------------------------------------------------------------
function _starship_transient_prompt() {
  [[ "${STARSHIP_TRANSIENT:-0}" == "1" ]] || return 0
  PROMPT='%F{cyan}❯%f '
  RPROMPT=''
  zle reset-prompt
}
add-zle-hook-widget zle-line-finish _starship_transient_prompt

function _starship_restore_prompt() {
  PROMPT="$_STARSHIP_FULL_PROMPT"
  RPROMPT="$_STARSHIP_FULL_RPROMPT"
}
precmd_functions+=(_starship_restore_prompt)

# ------------------------------------------------------------------------------
# 3b. Persistent runtime toggles for the transient prompt
# ------------------------------------------------------------------------------
_starship_persist() {
  export STARSHIP_TRANSIENT="$1"
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}"
  mkdir -p "$dir" 2>/dev/null || true
  print -r -- "$1" > "$dir/starship.transient"
}
starship-transient() {
  _starship_persist 1
  zle reset-prompt 2>/dev/null || true
}
starship-full() {
  _starship_persist 0
  zle reset-prompt 2>/dev/null || true
}
starship-reset() {
  export STARSHIP_TRANSIENT=0
  rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/starship.transient"
  zle reset-prompt 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 4. Initialize Starship (Must run after Oh My Zsh)
# ------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  typeset -g _STARSHIP_FULL_PROMPT="$PROMPT"
  typeset -g _STARSHIP_FULL_RPROMPT="$RPROMPT"
fi
