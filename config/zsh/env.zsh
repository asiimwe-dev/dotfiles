export EDITOR="nvim"
export VISUAL="nvim"

export CHROME_EXECUTABLE="/usr/bin/brave-origin-stable"

export GNIREHTET_APK="$HOME/Downloads/gnirehtet-linux/gnirehtet-rust-linux64/gnirehtet.apk"

export W3M_IMG_PATH='/usr/libexec/w3m/w3mimgdisplay'

export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
# Prefer the desktop/systemd SSH agent socket when one exists; tools.zsh only
# starts its own agent if this is still empty by the time it runs.
if [[ -z "$SSH_AUTH_SOCK" && -S "${XDG_RUNTIME_DIR:-$HOME/.local/state}/ssh-agent.socket" ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
fi

# Starship transient prompt. Default: full prompt stays visible (STARSHIP_TRANSIENT=0).
# Uncomment to opt into collapsing executed prompts to a cyan arrow by default:
# export STARSHIP_TRANSIENT=1
# NOTE: runtime toggles (starship-transient/starship-full/starship-reset) persist
# in ~/.local/state/starship.transient and override this baseline until reset.
