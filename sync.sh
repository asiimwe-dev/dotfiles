#!/usr/bin/env bash
# Refresh the dotfiles snapshot from $HOME.
#
# The live configs are the source of truth; this script copies them into the
# repo. Safe to run repeatedly. Use `-n` for a dry run.
#
#   ./sync.sh        copy
#   ./sync.sh -n     dry run
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry=()
case ${1:-} in
    -n|--dry-run) dry=(--dry-run --itemize-changes) ;;
    "") ;;
    *) echo "usage: $0 [-n|--dry-run]" >&2; exit 2 ;;
esac

cfg=$HOME/.config

# Whole trees (excluded: plugin clones, caches, local backups)
rsync -a --delete "${dry[@]}" --exclude='.git/' \
    "$cfg/nvim/" "$repo/config/nvim/"
rsync -a --delete "${dry[@]}" --exclude='plugins/' --exclude='*.bak' \
    "$cfg/tmux/" "$repo/config/tmux/"
rsync -a --delete "${dry[@]}" "$cfg/zsh/" "$repo/config/zsh/"
rsync -a --delete "${dry[@]}" --exclude='.git/' \
    "$cfg/yazi/" "$repo/config/yazi/"

# Individual files
copy() {
    local src=$1 dest=$2
    [[ -e $src ]] || { echo "skip (missing): $src" >&2; return 0; }
    mkdir -p -- "$(dirname -- "$repo/$dest")"
    rsync -a "${dry[@]}" "$src" "$repo/$dest"
}

copy "$cfg/kitty/kitty.conf"                       config/kitty/kitty.conf
copy "$cfg/kitty/current-theme.conf"               config/kitty/current-theme.conf
copy "$cfg/btop/btop.conf"                         config/btop/btop.conf
copy "$cfg/environment.d/10-gtk3-titlebuttons.conf" config/environment.d/10-gtk3-titlebuttons.conf
copy "$cfg/fontconfig/fonts.conf"                  config/fontconfig/fonts.conf
copy "$cfg/gh/config.yml"                          config/gh/config.yml
copy "$cfg/gtk-3.0/colors.css"                     config/gtk-3.0/colors.css
copy "$cfg/gtk-3.0/gtk.css"                        config/gtk-3.0/gtk.css
copy "$cfg/gtk-3.0/settings.ini"                   config/gtk-3.0/settings.ini
copy "$cfg/gtk-4.0/colors.css"                     config/gtk-4.0/colors.css
copy "$cfg/htop/htoprc"                            config/htop/htoprc
copy "$cfg/mise/config.toml"                       config/mise/config.toml
copy "$cfg/mpv/input.conf"                         config/mpv/input.conf
copy "$cfg/mpv/mpv.conf"                           config/mpv/mpv.conf
copy "$cfg/opencode/cli.json"                      config/opencode/cli.json
copy "$cfg/opencode/opencode.jsonc"                config/opencode/opencode.jsonc
copy "$cfg/starship.toml"                          config/starship.toml
copy "$cfg/systemd/user/tmux.service"              config/systemd/user/tmux.service

for f in .zshrc .zshenv .zprofile .bashrc .bash_profile .bash_logout \
         .profile .gitconfig .vimrc .gtkrc-2.0; do
    copy "$HOME/$f" "home/$f"
done

# Never copy secrets, even if someone runs this from a different machine.
rm -f -- "$repo/config/opencode/service.json" "$repo/config/gh/hosts.yml"

if ((${#dry[@]})); then
    echo "dry run complete"
else
    echo "snapshot refreshed -> $repo"
fi
