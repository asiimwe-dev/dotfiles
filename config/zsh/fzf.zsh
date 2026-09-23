# ==============================================================================
# FZF Theme & Core Settings (Solarized Osaka Glass + Nerd Icons)
# ==============================================================================

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS=" \
  --color=bg:-1,bg+:-1,gutter:-1 \
  --color=fg:#839496,fg+:#ffffff \
  --color=hl:#2aa198,hl+:#00ffff \
  --color=prompt:#859900,header:#93a1a1 \
  --color=info:#b58900,pointer:#d33682 \
  --color=marker:#cb4b16,spinner:#6c71c4 \
  --color=border:#586e75,label:#2aa198 \
  --border='rounded' \
  --prompt='󰁔 ' \
  --pointer='󰅂' \
  --marker='󰄬 ' \
  --height 50% \
  --layout=reverse \
  --info=inline"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --theme=Solarized\ \(dark\) --line-range :500 {} 2>/dev/null || eza --tree --icons --level=2 --color=always {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --level=2 --color=always {} 2>/dev/null'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap"

# Sourcing shell integration AFTER defining options
source <(fzf --zsh)

# Josean's Interactive Git bindings (fzf-git)
source ~/.config/zsh/fzf-git/fzf-git.sh

# Use fd for **<Tab> completion generator
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}
