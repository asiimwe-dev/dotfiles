typeset -U path

path=(
  $HOME/.local/bin
  $HOME/development/flutter/bin
  $HOME/.pub-cache/bin
  $path
  $HOME/.cargo/bin
  $HOME/go/bin
)

export PATH
