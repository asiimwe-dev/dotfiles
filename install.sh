#!/usr/bin/env bash
#
# install.sh — install these dotfiles by symlinking them into $HOME and
# ~/.config (XDG). Safe to re-run: existing targets are backed up once into
# ~/dotfiles-backups-<timestamp>/ before being linked.
#
# Usage:
#   ./install.sh             link everything
#   ./install.sh --dry-run   show what would happen without touching anything
#   ./install.sh --copy      copy files instead of symlinking
#   ./install.sh --help      show this help
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
COPY_MODE=0
BACKUP_DIR=""

# ---------------------------------------------------------------------------
# path mapping: "repo/relative/path" -> "abs/target"
# ---------------------------------------------------------------------------
declare -a LINKS=(
  "home/.zshrc|$HOME/.zshrc"
  "home/.zprofile|$HOME/.zprofile"
  "home/.zshenv|$HOME/.zshenv"
  "home/.gitconfig|$HOME/.gitconfig"
  "home/.vimrc|$HOME/.vimrc"
  "config/starship.toml|$HOME/.config/starship.toml"
  "config/zsh|$HOME/.config/zsh"
  "config/kitty|$HOME/.config/kitty"
  "config/tmux|$HOME/.config/tmux"
  "config/yazi|$HOME/.config/yazi"
  "config/btop|$HOME/.config/btop"
  "config/glow|$HOME/.config/glow"
  "config/mise|$HOME/.config/mise"
  "config/opencode|$HOME/.config/opencode"
  "config/gh|$HOME/.config/gh"
  "config/nvim|$HOME/.config/nvim"
)

say()  { printf '%s\n' "$*"; }
warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m[+] %s\033[0m\n' "$*"; }
info() { printf '\033[36m[.] %s\033[0m\n' "$*"; }
die()  { printf '\033[31m[✗] %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --copy)    COPY_MODE=1 ;;
    --help|-h) usage ;;
    *) die "unknown argument: $arg (try --help)" ;;
  esac
done

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
[[ -d "$DOTFILES/home" ]] || die "$DOTFILES/home not found"
[[ -d "$DOTFILES/config" ]] || die "$DOTFILES/config not found"

if (( COPY_MODE )); then
  info "Using COPY mode (no symlinks)."
else
  info "Using SYMLINK mode."
fi

if (( DRY_RUN )); then
  info "DRY RUN — nothing will be changed."
fi

# ---------------------------------------------------------------------------
# Backup existing targets (only once, only when actually installing)
# ---------------------------------------------------------------------------
backup_target() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  [[ -n "$BACKUP_DIR" ]] && return 0           # backed up earlier this run

  BACKUP_DIR="$HOME/dotfiles-backups-$(date +%Y%m%d-%H%M%S)"
  if (( DRY_RUN )); then
    info "backup dir would be: $BACKUP_DIR"
    return 0
  fi
  mkdir -p "$BACKUP_DIR"
  if [[ -d "$target" && ! -L "$target" ]]; then
    mv "$target" "$BACKUP_DIR/$(basename "$target")"
  else
    mv "$target" "$BACKUP_DIR/$(basename "$target")"
  fi
}

# ---------------------------------------------------------------------------
# Install a single entry
# ---------------------------------------------------------------------------
install_link() {
  local src_rel="$1"
  local target="$2"
  local src="$DOTFILES/$src_rel"

  [[ -e "$src" ]] || { warn "skipping missing source: $src_rel"; return; }

  if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
    ok "already linked: $target"
    return
  fi

  backup_target "$target"

  mkdir -p "$(dirname "$target")" 2>/dev/null || true

  if (( DRY_RUN )); then
    if (( COPY_MODE )); then
      info "would copy: $src_rel -> $target"
    else
      info "would link: $src_rel -> $target"
    fi
    return
  fi

  rm -rf "$target" 2>/dev/null || true
  if (( COPY_MODE )); then
    cp -r "$src" "$target"
    ok "copied: $src_rel"
  else
    ln -s "$src" "$target"
    ok "linked: $src_rel"
  fi
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
for entry in "${LINKS[@]}"; do
  src_rel="${entry%%|*}"
  target="${entry##*|}"
  install_link "$src_rel" "$target"
done

say ""
if (( DRY_RUN )); then
  info "Dry run finished. Re-run without --dry-run to install."
else
  ok "Install complete."
  [[ -n "$BACKUP_DIR" ]] && info "Backups of pre-existing files: $BACKUP_DIR"
  say ""
  say "Tip: $HOME/.config/gh and $HOME/.gitconfig contain placeholders —"
  say "     set your real Git identity and gh user after installing."
fi