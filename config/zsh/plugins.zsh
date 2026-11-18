# ==============================================================================
# PLUGINS & COMPLETIONS — framework-free (oh-my-zsh removed 2026-10-07)
#
# What used to be `source $ZSH/oh-my-zsh.sh` (0.11-0.12s + a ~1s compinit
# rebuild once/day) is now: one compinit + the vendored OMZ lib files that
# were actually used + the four plugins this setup depends on.
#
# Vendored files live in ~/.config/zsh/vendor/ (copied from oh-my-zsh):
#   functions, completion, key-bindings, directories, grep, history, misc,
#   theme-and-appearance, sudo.plugin, colored-man-pages.plugin
# The two git-tracked plugins moved to ~/.local/share/zsh/plugins/ so they
# can still be updated with `git pull`.
# ==============================================================================

# Cache dir used by vendored lib files (grep aliases, appearance probes,
# completion dump).
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

# Behavior flags consumed by the vendored files (were set in the old plugins.zsh)
COMPLETION_WAITING_DOTS=true
HYPHEN_INSENSITIVE=true

# ------------------------------------------------------------------------------
# Completions — fast path: trust a dump younger than 24h (-C skips the audit).
# Stale/missing dump: rebuild (once/day, ~0.4-0.9s) and keep a zcompiled copy.
# ------------------------------------------------------------------------------
autoload -Uz compinit
_zcompdump="$ZSH_CACHE_DIR/zcompdump"
if [[ -e "$_zcompdump" && -z "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -i -d "$_zcompdump"
fi
if [[ ! "$_zcompdump.zwc" -nt "$_zcompdump" ]]; then
  zcompile "$_zcompdump" 2>/dev/null
fi
unset _zcompdump

# ------------------------------------------------------------------------------
# Vendored oh-my-zsh lib files (loaded in the same order OMZ used: libs,
# then plugins). functions.zsh first — misc.zsh needs its env_default.
# ------------------------------------------------------------------------------
_omz_vendor="$HOME/.config/zsh/vendor"
source "$_omz_vendor/functions.zsh"              # env_default, take, urlencode...
source "$_omz_vendor/completion.zsh"             # menu-select, case/hyphen match, waiting dots, bashcompinit
source "$_omz_vendor/key-bindings.zsh"           # Home/End/Del, history search
source "$_omz_vendor/directories.zsh"            # ..., -, 1-9, md/rd (uses compdef -> after compinit)
source "$_omz_vendor/grep.zsh"                   # grep color aliases
source "$_omz_vendor/history.zsh"                # hist_verify etc.
source "$_omz_vendor/misc.zsh"                   # paste magic, multios, _='sudo '
source "$_omz_vendor/theme-and-appearance.zsh"   # diff --color, LS_COLORS (probes cached 1 day)

# ------------------------------------------------------------------------------
# Plugins — identical behavior to what oh-my-zsh loaded before
# ------------------------------------------------------------------------------
source "$_omz_vendor/sudo.plugin.zsh"                        # ESC-ESC sudo toggle
source "$_omz_vendor/colored-man-pages.plugin.zsh"
source "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
# zsh-syntax-highlighting is deliberately NOT sourced here: it must load
# LAST, so ~/.zshrc sources it after fzf/aliases/starship (see .zshrc).

unset _omz_vendor

# The only oh-my-zsh git alias that was ever used (history check);
# gs/ga/gc/gp/gl are defined in aliases.zsh.
alias gd='git diff'
