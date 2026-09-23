#!/usr/bin/env bash
#
# bootstrap.sh — install every tool these dotfiles expect, using the host's
# package manager (dnf / apt / pacman / brew).
#
# Usage:
#   ./bootstrap.sh --full      core + terminal/editor tools (default)
#   ./bootstrap.sh --core      only core shell tools
#   ./bootstrap.sh --fonts     also install the JetBrainsMono Nerd Font
#   ./bootstrap.sh --dry-run   print the commands without running them
#   ./bootstrap.sh --help      show this help
#
# Afterwards: run ./install.sh to link the configs, then read the
# "First-time setup per tool" section of README.md (oh-my-zsh plugins, TPM,
# yazi plugins, LazyVim bootstrap, mise install).
#
set -euo pipefail

MODE="full"
INSTALL_FONTS=0
DRY_RUN=0

say()   { printf '%s\n' "$*"; }
warn()  { printf '\033[33m[!]\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m[+] %s\033[0m\n' "$*"; }
info()  { printf '\033[36m[.] %s\033[0m\n' "$*"; }
die()   { printf '\033[31m[✗] %s\033[0m\n' "$*" >&2; exit 1; }

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

for arg in "$@"; do
  case "$arg" in
    --core)    MODE="core" ;;
    --full)    MODE="full" ;;
    --fonts)   INSTALL_FONTS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage ;;
    *) die "unknown argument: $arg (try --help)" ;;
  esac
done

# ---------------------------------------------------------------------------
# 1. Detect the package manager and root runner
# ---------------------------------------------------------------------------
PM=""
declare -a INSTALL_CMD=()
declare -a CORE=()
declare -a EXTRA=()

if command -v dnf >/dev/null 2>&1; then
  PM=dnf
  INSTALL_CMD=(sudo dnf install -y)
  CORE=(zsh git curl starship fzf fd-find bat eza zoxide git-delta ripgrep)
  EXTRA=(tmux kitty neovim btop glow gh lazygit tldr dolphin wl-clipboard mise yazi)
elif command -v apt-get >/dev/null 2>&1; then
  PM=apt
  INSTALL_CMD=(sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y)
  CORE=(zsh git curl starship fzf fd-find bat eza zoxide git-delta ripgrep)
  EXTRA=(tmux kitty neovim btop gh lazygit tldr dolphin wl-clipboard mise)
elif command -v pacman >/dev/null 2>&1; then
  PM=pacman
  INSTALL_CMD=(sudo pacman -Sy --noconfirm --needed)
  CORE=(zsh git curl starship fzf fd bat eza zoxide git-delta ripgrep)
  EXTRA=(tmux kitty neovim btop glow gh lazygit tldr dolphin wl-clipboard mise yazi)
elif command -v brew >/dev/null 2>&1; then
  PM=brew
  INSTALL_CMD=(brew install)
  CORE=(zsh git curl starship fzf fd bat eza zoxide git-delta ripgrep)
  EXTRA=(tmux kitty neovim btop glow gh lazygit tldr wl-clipboard mise)
else
  die "No supported package manager found (dnf/apt/pacman/brew). Install the tools manually — see README.md."
fi

info "Detected package manager: $PM"

# ---------------------------------------------------------------------------
# 2. Install packages
# ---------------------------------------------------------------------------
needs() {
  command -v "$1" >/dev/null 2>&1
}

install_pkgs() {
  local label="$1"; shift
  [[ $# -eq 0 ]] && return 0

  say ""
  say "==> $label: ${*}"
  if (( DRY_RUN )); then
    info "would run: ${INSTALL_CMD[*]} $*"
    return 0
  fi
  if ! "${INSTALL_CMD[@]}" "$@"; then
    warn "package install had errors — check the messages above."
  fi
}

[[ "$MODE" == "full" || "$MODE" == "core" ]] || die "unknown mode: $MODE"

install_pkgs "core tools" "${CORE[@]}"
[[ "$MODE" == "full" ]] && install_pkgs "terminal & editor tools" "${EXTRA[@]}"

# ---------------------------------------------------------------------------
# 3. Post-install fallbacks: mise, yazi, oh-my-zsh
# ---------------------------------------------------------------------------
if (( ! DRY_RUN )); then
  if ! needs mise && [[ "$MODE" == "full" ]]; then
    say ""
    info "mise not available via $PM — installing the official binary installer."
    curl -fsSL https://mise.run | sh || warn "mise install failed; see https://mise.jdx.dev/getting-started.html"
  fi

  if ! needs yazi && [[ "$MODE" == "full" ]]; then
    if needs cargo; then
      say ""
      info "yazi not available via $PM — installing via cargo."
      cargo install --locked yazi-fm yazi-cli || \
        warn "yazi install failed; see https://yazi-rs.github.io/docs/installation/"
    else
      warn "yazi is not installed. Install it from https://yazi-rs.github.io/docs/installation/"
    fi
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    say ""
    info "Installing oh-my-zsh (framework for the zsh plugins module)."
    if needs git; then
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || \
        warn "oh-my-zsh clone failed; retry: git clone https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 4. Optional: Nerd Font
# ---------------------------------------------------------------------------
if (( INSTALL_FONTS )); then
  say ""
  info "Installing JetBrainsMono Nerd Font into ~/.local/share/fonts."
  FONTDIR="$HOME/.local/share/fonts"
  TMPFONT="$(mktemp --suffix=.tar.xz)"
  if (( DRY_RUN )); then
    info "would download JetBrainsMono.tar.xz and extract to $FONTDIR"
    rm -f "$TMPFONT"
  else
    mkdir -p "$FONTDIR"
    if curl -fsSL -o "$TMPFONT" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        && tar -xf "$TMPFONT" -C "$FONTDIR" 2>/dev/null; then
      rm -f "$TMPFONT"
      command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONTDIR" >/dev/null 2>&1 || true
      ok "Nerd Font installed. Set it as the font in kitty.conf (~/.config/kitty/kitty.conf)."
    else
      rm -f "$TMPFONT"
      warn "Nerd Font download/extract failed; grab it manually from https://www.nerdfonts.com/font-downloads"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
say ""
if (( DRY_RUN )); then
  info "Dry run finished. Re-run without --dry-run to install."
else
  ok "bootstrap complete."
  say ""
  say "Next steps:"
  say "  1. ./install.sh                      # link the configs"
  say "  2. nvim (first launch bootstraps LazyVim plugins)"
  say "  3. tmux, then press <prefix>+I      # install tmux plugins (TPM)"
  say "  4. cd ~/.config/yazi && ya pkg install   # yazi plugins (full mode)"
  say "  5. mise install                     # installs go/java/node from config.toml"
  say "  6. Replace the identity placeholders in ~/.gitconfig and ~/.config/gh/hosts.yml"
fi