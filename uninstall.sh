#!/usr/bin/env bash
#
# uninstall.sh — remove the symlinks/copies installed by install.sh.
# Backups from the last install live in ~/dotfiles-backups-<timestamp>/.
#
# Usage:
#   ./uninstall.sh             remove all managed targets
#   ./uninstall.sh --dry-run   show what would be removed
#   ./uninstall.sh --help      show this help
#
set -euo pipefail

DRY_RUN=0

declare -a TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.zshenv"
  "$HOME/.gitconfig"
  "$HOME/.vimrc"
  "$HOME/.config/starship.toml"
  "$HOME/.config/zsh"
  "$HOME/.config/kitty"
  "$HOME/.config/tmux"
  "$HOME/.config/yazi"
  "$HOME/.config/btop"
  "$HOME/.config/glow"
  "$HOME/.config/mise"
  "$HOME/.config/opencode"
  "$HOME/.config/gh"
  "$HOME/.config/nvim"
)

say()  { printf '%s\n' "$*"; }
info() { printf '\033[36m[.] %s\033[0m\n' "$*"; }
die()  { printf '\033[31m[✗] %s\033[0m\n' "$*" >&2; exit 1; }

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $arg (try --help)" ;;
  esac
done

(( DRY_RUN )) && info "DRY RUN — nothing will be changed."

if [[ -d "$HOME/dotfiles-backups" ]]; then
  info "Tip: backups live in $HOME/dotfiles-backups*/"
fi

for target in "${TARGETS[@]}"; do
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    continue
  fi
  if (( DRY_RUN )); then
    info "would remove: $target"
    continue
  fi
  rm -rf "$target"
  printf '\033[32m[-] removed: %s\033[0m\n' "$target"
done

say ""
say "Done. Your original configs (if any) were backed up by install.sh to"
say "$HOME/dotfiles-backups-<timestamp>/ — restore them if needed."