alias c="clear"
alias e="exit"
alias r="reset"
alias icat="kitty +kitten icat"
alias zshconfig="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc"
# alias lab="ssh user@192.168.x.x"  # Example: personal VM/Lab host
alias open="dolphin"
alias top="btop"
alias pkglist="dnf list --installed | fzf"
alias tls="tmux ls"
alias t="tmux"
alias info="tldr"

# Neovim
alias v="nvim"
# alias vim="nvim"

# Git
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

# Update and Install package
alias upgrade='sudo dnf5 upgrade --refresh && sudo dnf5 clean all && sudo dnf5 autoremove'
alias i="sudo dnf install "
alias install="sudo dnf install "

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
# AUTOMATIC TMUX PROJECT SESSIONIZER (DYNAMIC RENAMING ENABLED)
# ------------------------------------------------------------------------------
auto_tmux_project() {
  # Skip if already inside tmux or in a non-interactive shell
  [[ -n "$TMUX" ]] && return

  # Check if current directory is a recognized project
  if [[ -d .git || -f pubspec.yaml || -f package.json || -f Cargo.toml || -f go.mod || -f CMakeLists.txt || -f docker-compose.yml || -f Dockerfile ]]; then
    local session_name
    # Strip spaces, dots, and colons to ensure a valid tmux session name
    session_name=$(basename "$PWD" | tr '.: ' '___')

    # Attach to existing session or launch a new provisioned workspace
    if tmux has-session -t "$session_name" 2>/dev/null; then
      exec tmux attach-session -t "$session_name"
    else
      # Create new session letting Window 1 auto-rename dynamically based on directory/process
      tmux new-session -d -s "$session_name" -c "$PWD"

      # If Docker or Compose exists, auto-provision Window 2 for logs
      if [[ -f docker-compose.yml || -f Dockerfile ]]; then
        tmux new-window -t "$session_name":2 -n "docker" -c "$PWD"
        if [[ -f docker-compose.yml ]]; then
          tmux send-keys -t "$session_name":2 "docker compose logs -f" C-m
        fi
      fi

      # Focus window 1 and replace current shell
      tmux select-window -t "$session_name":1
      exec tmux attach-session -t "$session_name"
    fi
  fi
}

# Run hook on directory changes (cd, z, etc.)
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_tmux_project

# Run check on fresh terminal startup (if Kitty opens directly in a project folder)
auto_tmux_project

# ------------------------------------------------------------------------------
# bat (Modern cat)
# ------------------------------------------------------------------------------
if command -v bat >/dev/null; then
  alias cat="bat --paging=never"
  alias less="bat"
  alias more="bat"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
