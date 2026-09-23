# ------------------------------------------------------------------------------
# Zoxide
# ------------------------------------------------------------------------------

if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# ==============================================================================
# ZSH SYNTAX HIGHLIGHTING: DYNAMIC PATH STYLING
# ==============================================================================

# Ensure zsh-syntax-highlighting plugin is loaded in your .zshrc
# (On Fedora, usually sourced via plugin manager or /usr/share/zsh-syntax-highlighting)

typeset -A ZSH_HIGHLIGHT_STYLES

# 1. PATH EXISTS -> Bold & Bright Accent
ZSH_HIGHLIGHT_STYLES[path]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#7dcfff,bold'

# 2. PATH DOES NOT EXIST / INVALID -> Dimmed Gray
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#565f89,dim'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#bb9af7'

# Turn off any underline styles inherited by default
ZSH_HIGHLIGHT_STYLES[autocd]='fg=#7aa2f7,bold'

# ------------------------------------------------------------------------------
# Yazi Integration
# Launch Yazi and change the shell's working directory on exit.
# ------------------------------------------------------------------------------

function y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)"

    yazi "$@" --cwd-file="$tmp"

    if [[ -f "$tmp" ]]; then
        local cwd
        cwd="$(<"$tmp")"

        if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
            builtin cd -- "$cwd"
        fi

        rm -f -- "$tmp"
    fi
}

# ------------------------------------------------------------------------------
# SSH AGENT AUTHENTICATION
# ------------------------------------------------------------------------------
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# Avoid Kitty Alt+T conflict
bindkey '\et' fzf-file-widget

# ------------------------------------------------------------------------------
# mise
# ------------------------------------------------------------------------------

if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

