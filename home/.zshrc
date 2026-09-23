# ==============================================================================
# Powerlevel10k Instant Prompt (Must be first)
# DISABLED: reverted to starship. Uncomment to roll back.
# ==============================================================================

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ==============================================================================
# Load Modular Configuration
# ==============================================================================

ZSH_CONFIG="$HOME/.config/zsh"

source "$ZSH_CONFIG/plugins.zsh"
source "$ZSH_CONFIG/env.zsh"
source "$ZSH_CONFIG/path.zsh"
source "$ZSH_CONFIG/tools.zsh"
source "$ZSH_CONFIG/fzf.zsh"
source "$ZSH_CONFIG/aliases.zsh"
source "$ZSH_CONFIG/functions.zsh"
source "$ZSH_CONFIG/options.zsh"
# source "$ZSH_CONFIG/p10k.zsh"
source "$ZSH_CONFIG/starship.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# DISABLED: p10k rolled back in favor of starship. Uncomment to restore.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
