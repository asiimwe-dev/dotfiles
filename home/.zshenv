export PATH="$PATH:$HOME/development/flutter/bin"

# ------------------------------------------------------------------------------
# flatpak shim — /etc/profile.d/flatpak.sh runs `flatpak --installations` on
# every interactive shell (~70-100ms fork per shell open). Answer that exact
# call from a cache refreshed at most once a day; forward every other
# invocation to the real binary. Function is defined before /etc/zshrc and
# /etc/zprofile run (both source profile.d), so it shadows them.
# ------------------------------------------------------------------------------
if [[ -x /usr/bin/flatpak ]]; then
  _flatpak_cache="${XDG_CACHE_HOME:-$HOME/.cache}/flatpak-installations"
  if [[ ! -s $_flatpak_cache || -n $_flatpak_cache(#qN.mh+24) ]]; then
    command /usr/bin/flatpak --installations >| "$_flatpak_cache" 2>/dev/null
  fi
  unset _flatpak_cache

  flatpak() {
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/flatpak-installations"
    if [[ "$#" -eq 1 && "$1" == "--installations" && -s "$cache" ]]; then
      print -r -- "$(<"$cache")"
    else
      command /usr/bin/flatpak "$@"
    fi
  }
fi
