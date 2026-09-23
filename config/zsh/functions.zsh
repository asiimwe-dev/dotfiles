mkcd() {
  if [[ -z "$1" ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}
# update lazygit
update-lazygit() {
  echo "Fetching latest lazygit version..."
  local LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')

  echo "Downloading version ${LAZYGIT_VERSION}..."
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm /tmp/lazygit /tmp/lazygit.tar.gz

  echo "Successfully updated to ${LAZYGIT_VERSION}!"
}
# Interactive Git Log Browser (View commit history & diffs)
fgl() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % git show --color=always %) | less -R" \
      --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always %"
}

# Interactive Git Branch Switcher
fgb() {
  local branches branch
  branches=$(git branch --all | grep -v '/HEAD') &&
    branch=$(echo "$branches" | fzf +m --tiebreak=index) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/origin/##")
}

# Interactive Git Stash Viewer
fgs() {
  local stash
  stash=$(git stash list | fzf -m --reverse) &&
    git stash show -p $(echo "$stash" | cut -d: -f1)
}

# Find file and open in Neovim/Vim
fv() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --style=numbers --color=always {}')
  [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
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
