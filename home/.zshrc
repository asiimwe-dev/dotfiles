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
source "$ZSH_CONFIG/starship.zsh"

# zsh-syntax-highlighting MUST be sourced last: it wraps widgets created by
# fzf, autosuggestions, the transient-prompt hooks and starship itself.
source "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
. "/home/asiimwe/.deno/env"

# opencode
export PATH=/home/asiimwe/.opencode/bin:$PATH
