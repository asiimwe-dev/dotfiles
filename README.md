# dotfiles

A snapshot of the configuration files and tool settings for this machine:
**Fedora + KDE Plasma 6 (Wayland) + kitty + tmux + Neovim**.

This repo is a **copy**, not a live source. The real files stay where they are in
`$HOME`; nothing here is symlinked yet. Use `./sync.sh` to refresh the snapshot
and the "Restoring" section below to put it on another machine.

---

## Layout

`config/` mirrors `~/.config/`, `home/` mirrors `$HOME` (loose dotfiles).

| Here | Lives at |
| --- | --- |
| `config/nvim/` | `~/.config/nvim/` |
| `config/kitty/` | `~/.config/kitty/` |
| `config/tmux/` | `~/.config/tmux/` (config + `scripts/`, no plugin clones) |
| `config/zsh/` | `~/.config/zsh/` |
| `config/yazi/` | `~/.config/yazi/` |
| `config/btop/btop.conf` | `~/.config/btop/btop.conf` |
| `config/environment.d/` | `~/.config/environment.d/` |
| `config/fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` |
| `config/gh/config.yml` | `~/.config/gh/config.yml` (settings only) |
| `config/gtk-3.0/`, `config/gtk-4.0/` | matching `~/.config/` dirs (theme colours, not asset caches) |
| `config/htop/htoprc` | `~/.config/htop/htoprc` |
| `config/mise/config.toml` | `~/.config/mise/config.toml` |
| `config/mpv/` | `~/.config/mpv/` |
| `config/opencode/` | `~/.config/opencode/` (UI config only) |
| `config/starship.toml` | `~/.config/starship.toml` |
| `config/systemd/user/tmux.service` | `~/.config/systemd/user/tmux.service` |
| `home/.zshrc`, `.zshenv`, `.zprofile` | `~/` |
| `home/.bashrc`, `.bash_profile`, `.bash_logout`, `.profile` | `~/` |
| `home/.gitconfig`, `.vimrc`, `.gtkrc-2.0` | `~/` |

## What is in here

- **Neovim** — LazyVim setup with `lazy-lock.json`, Java project generator, AI
  config, Error Lens-style inline errors and warnings (`<leader>uv` cycles
  verbosity), diagnostic/reference highlight tuning.
- **kitty** — PlemolJP Console NF, glass/frosted look, top tab dock, custom
  keybinds, Solarized Osaka theme (`current-theme.conf`).
- **tmux** — prefix `M-a`, top glass bar, fzf productivity suite,
  resurrect/continuum, and the status scripts:
  - `scripts/status-net.sh` — Wi-Fi SSID + VPN name (NM + tunnel fallback)
  - `scripts/status-sys.sh` — CPU/RAM straight from `/proc`
- **zsh** — framework-free modular config (aliases, functions, fzf, starship,
  vendored oh-my-zsh libs, fzf-git helpers).
- **Tool settings** — starship prompt, btop, htop, yazi, mpv, mise version pins,
  gh, opencode UI, GTK colours, fontconfig, tmux systemd user unit.

## Deliberately excluded

| Excluded | Why |
| --- | --- |
| `~/.config/tmux/plugins/`, `~/.local/share/nvim/`, `~/.local/share/zsh/plugins/` | installed by TPM / LazyVim / git, not hand-written |
| `~/.config/opencode/service.json` | contains a generated password |
| `~/.config/gh/hosts.yml` | auth data |
| `~/.config/Code/`, `BraveSoftware/`, `GitKraken/`, `libreoffice/`, … | browser/editor state, gigabytes |
| KDE `*rc` files (`kwinrc`, `kdeglobals`, `plasma-org…appletsrc`, …) | auto-generated, machine-specific IDs |
| `~/.vim/undo/`, `~/.vim/plugged/` | undo history + plugin clones |
| `*.bak`, `*.Dkhtdh`, asset caches, `node_modules/` | local noise |
| `~/.config/nvim/.git/` | nvim keeps its own history; this is a copy |

## Restoring on a new machine

```sh
git clone <this-repo> ~/Dev/dotfiles
cd ~/Dev/dotfiles

# configs (keeps backup of anything overwritten)
rsync -a --backup --suffix=.pre-dotfiles config/ ~/.config/
rsync -a home/ ~/
```

Then reinstall the parts that are never committed:

```sh
# tmux plugins (TPM bootstraps itself; then prefix + I inside tmux)
tmux start-server

# zsh plugins (not vendored)
mkdir -p ~/.local/share/zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ~/.local/share/zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    ~/.local/share/zsh/plugins/zsh-syntax-highlighting

# Neovim: first launch installs from lazy-lock.json
nvim --headless "+Lazy! sync" +qa
```

## Refreshing this snapshot

```sh
./sync.sh          # copy current $HOME configs into the repo
./sync.sh -n       # dry run: show what would change
```

The live files are always the source of truth; the repo follows them.
