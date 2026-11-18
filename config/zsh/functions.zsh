mkcd() {
  if [[ -z "$1" ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}

# Update lazygit (portable across Linux/macOS and arch; prefers brew when present)
update-lazygit() {
  local arch os version

  if command -v brew >/dev/null 2>&1; then
    echo "Updating lazygit via Homebrew..."
    brew upgrade lazygit
    return $?
  fi

  case "$(uname -s)" in
    Linux)  os=Linux ;;
    Darwin) os=Darwin ;;
    *) echo "update-lazygit only supports Linux/macOS." >&2; return 1 ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)  arch=x86_64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "update-lazygit: unsupported arch: $(uname -m)" >&2; return 1 ;;
  esac

  version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')

  if [[ -z "$version" ]]; then
    echo "Could not determine the latest lazygit version." >&2
    return 1
  fi

  echo "Downloading lazygit ${version} for ${os}/${arch}..."
  curl -fSL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_${os}_${arch}.tar.gz" | tar xzf - -C /tmp lazygit

  mkdir -p "$HOME/.local/bin"
  install -m755 /tmp/lazygit "$HOME/.local/bin/lazygit"
  rm -f /tmp/lazygit

  echo "Successfully updated to ${version}!"
}

# Interactive Git Log Browser (View commit history & diffs)
fgl() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % git show --color=always %) | less -R" \
      --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always %" \
      || return 0
}

# Interactive Git Branch Switcher
fgb() {
  local branches branch target
  branches=$(git branch --all | grep -v '/HEAD') || return 0
  branch=$(echo "$branches" | fzf +m --tiebreak=index) || return 0
  [[ -n "$branch" ]] || return 0
  target=$(echo "$branch" | sed 's/.* //; s#remotes/origin/##')
  git switch "$target" 2>/dev/null || git checkout "$target"
}

# Interactive Git Stash Viewer
fgs() {
  local stash
  stash=$(git stash list | fzf -m --reverse) || return 0
  [[ -n "$stash" ]] || return 0
  git stash show -p "$(echo "$stash" | cut -d: -f1)"
}

# Find file and open in Neovim/Vim
fv() {
  local file
  file=$(fd --type f --hidden --exclude .git 2>/dev/null | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null') || return 0
  [[ -n "$file" ]] || return 0
  ${EDITOR:-nvim} "$file"
}

if command -v bat >/dev/null; then

  bhead() {
    if [[ "$1" == -* ]] || [[ ! -t 0 ]]; then
      command head "$@"
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
      local lines="$1"
      shift
      bat --line-range ":$lines" "$@"
    else
      bat --line-range ":10" "$@"
    fi
  }

  btail() {
    if [[ "$1" == -* ]] || [[ ! -t 0 ]]; then
      command tail "$@"
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
      local lines="$1"
      shift
      bat --line-range "-$lines:" "$@"
    else
      bat --line-range "-10:" "$@"
    fi
  }

  alias head="bhead"
  alias tail="btail"

fi

# ------------------------------------------------------------------------------
# AUTOMATIC TMUX PROJECT SESSIONIZER (DYNAMIC RENAMING ENABLED)
# ------------------------------------------------------------------------------
auto_tmux_project() {
  # Skip if already inside tmux or in a non-interactive shell
  [[ -n "$TMUX" ]] && return

  local is_compose=0
  if [[ -f compose.yaml || -f compose.yml || -f podman-compose.yml || -f docker-compose.yml || -f docker-compose.yaml ]]; then
    is_compose=1
  fi

  local is_container=0
  if [[ -f Containerfile || -f Dockerfile ]]; then
    is_container=1
  fi

  # Check if current directory is a recognized project
  if [[ -e .git || -f pubspec.yaml || -f package.json || -f Cargo.toml || -f go.mod || -f CMakeLists.txt || $is_compose -eq 1 || $is_container -eq 1 ]]; then
    local session_name
    # Strip spaces, dots, and colons to ensure a valid tmux session name
    session_name=$(basename "$PWD" | tr '.: ' '___')

    # Attach to existing session or launch a new provisioned workspace
    if tmux has-session -t "$session_name" 2>/dev/null; then
      exec tmux attach-session -t "$session_name"
    else
      # Create new session letting Window 1 auto-rename dynamically based on directory/process
      tmux new-session -d -s "$session_name" -c "$PWD"

      # If Compose or Container exists, auto-provision Window 2
      if (( is_compose )); then
        tmux new-window -t "$session_name":2 -n "podman-compose" -c "$PWD"
        local compose_cmd="podman compose"
        command -v podman-compose >/dev/null 2>&1 && compose_cmd="podman-compose"
        tmux send-keys -t "$session_name":2 "$compose_cmd logs -f" C-m
      elif (( is_container )); then
        tmux new-window -t "$session_name":2 -n "podman" -c "$PWD"
      fi

      # Focus window 1 and replace current shell
      tmux select-window -t "$session_name":1
      exec tmux attach-session -t "$session_name"
    fi
  fi
}

# Run hook on directory changes (cd, z, etc.)
autoload -Uz add-zsh-hook
add-zsh-hook chpwd auto_tmux_project

# Run check on fresh terminal startup (if Kitty opens directly in a project folder)
auto_tmux_project