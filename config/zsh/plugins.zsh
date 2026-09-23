export ZSH="$HOME/.oh-my-zsh"

# Prompt is rendered by starship (see starship.zsh / ~/.config/starship.toml).
# DISABLED: powerlevel10k kept for rollback — uncomment to restore.
# ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME=""

COMPLETION_WAITING_DOTS=true
HYPHEN_INSENSITIVE=true

plugins=(
  git
  sudo
  colored-man-pages
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"