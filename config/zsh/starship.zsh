# ==============================================================================
# STARSHIP & TERMINAL INTEGRATION (~/.zshrc)
# ==============================================================================

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
# 4. Initialize Starship (Must run after Oh My Zsh)
# ------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  typeset -g _STARSHIP_FULL_PROMPT="$PROMPT"
  typeset -g _STARSHIP_FULL_RPROMPT="$RPROMPT"
fi
