alias c="clear"
alias e="exit"
alias r="reset"
alias icat="kitty +kitten icat"
alias zshconfig="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc"
alias open="dolphin"
alias top="btop"
alias browse="w3m"
alias download="yt-dlp"
alias play="mpv"

# List installed packages in fzf (returns cleanly when cancelled)
unalias pkglist 2>/dev/null
pkglist() {
  dnf list --installed 2>/dev/null | fzf --prompt 'packages> ' --no-sort
  return 0
}

alias tls="tmux ls"
alias t="tmux"
alias info="tldr"

# Neovim
alias v="nvim"
# alias vim="nvim"

# Git
alias g="git"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

# Update and Install package
alias upgrade='sudo dnf5 upgrade -y --refresh && sudo dnf5 autoremove -y'
alias i="sudo dnf install "
alias install="sudo dnf install "
# List flatpak applications
alias flist='PAGER=cat flatpak list --app --columns=application,name,version,origin,size'
# Remove a flatpak application
alias flatpak-remove='flatpak uninstall --delete-data'

# ------------------------------------------------------------------------------
# Yazi Aliases
# ------------------------------------------------------------------------------
alias fm='y'           # Open current directory in Yazi
alias yh='y ~'         # Open home directory
alias yd='y ~/Dev'     # Open development workspace
alias yc='y ~/.config' # Open config directory

# Flutter
alias f="flutter"
alias fget="flutter pub get"
alias fr="flutter run"
alias fdoctor="flutter doctor"

# ------------------------------------------------------------------------------
# eza (Modern ls)
# ------------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  # Default listing
  alias ls='eza \
        --icons=always \
        --group-directories-first'

  # Long listing (fast)
  alias ll='eza -lh \
        --icons=always \
        --group \
        --git \
        --git-ignore \
        --header \
        --classify \
        --group-directories-first'

  # Long listing including hidden files
  alias la='eza -lah \
        --icons=always \
        --group \
        --git \
        --git-ignore \
        --header \
        --classify \
        --group-directories-first'

  # Directory tree
  alias lt='eza --tree \
        --level=2 \
        --icons=always \
        --git-ignore \
        --group-directories-first'

  # Tree with hidden files
  alias lta='eza --tree \
        --all \
        --level=2 \
        --icons=always \
        --git-ignore \
        --group-directories-first'

  # Directory sizes (slower because sizes are computed)
  alias lS='eza -lh \
        --total-size \
        --group \
        --header \
        --icons=always \
        --classify \
        --group-directories-first'

  # Git-focused view
  alias lg='eza -lah \
        --git \
        --git-ignore \
        --icons=always \
        --header'

  # Sort by newest first
  alias lm='eza -lh \
        --sort=modified \
        --reverse \
        --icons=always \
        --group \
        --git \
        --header'

  # Sort by size
  alias lx='eza -lh \
        --sort=size \
        --reverse \
        --icons=always \
        --group \
        --header'
fi

# ------------------------------------------------------------------------------
# bat (Modern cat)
# ------------------------------------------------------------------------------
if command -v bat >/dev/null; then
  alias cat="bat --paging=never"
  alias less="bat"
  alias more="bat"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ------------------------------------------------------------------------------
# Modern coreutils (procs, dust, duf, sd)
# ------------------------------------------------------------------------------
if command -v procs >/dev/null 2>&1; then
  alias ips='procs'
fi

if command -v dust >/dev/null 2>&1; then
  alias idu='dust'
fi

if command -v duf >/dev/null 2>&1; then
  alias idf='duf'
fi

if command -v sd >/dev/null 2>&1; then
  alias ised='sd'
fi
