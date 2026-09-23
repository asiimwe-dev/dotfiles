# Dotfiles

Personal, portable developer environment configuration: shell, editor, terminal,
and modern CLI tools — designed to be installed and reused on any Linux machine.

A **full reference** for every configured tool (including **all default keymaps**
and every **custom keymap** you might want to know about) lives in
[`docs/dotfiles.md`](docs/dotfiles.md).

## Features

- **Zsh** — modular config (`plugins`, `env`, `path`, `tools`, `fzf`, `aliases`,
  `functions`, `options`, `starship`), powered by Starship prompt kitty visuals.
- **Neovim** — LazyVim-based setup with a custom "hyper" dashboard, Java/Flutter
  tooling, Molten (Jupyter notebooks), AI completion, and a glassy Solarized
  Osaka theme.
- **Kitty** — GPU terminal with a glassy Solarized Osaka theme (transparency,
  rounded corners, Nerd Font).
- **Yazi** — blazing-fast file manager with git status, full borders, and
  drag/piper/ouch plugins.
- **Git / gh** — sensible defaults with `delta` as pager and `gh` credential
  helper.
- Plus: **tmux** (sessionizer + vim navigation), **btop**, **glow**, **mise**
  (go/java/node), and **opencode** MCP/plugin setup.

## Requirements

The `bootstrap.sh` script installs all of them automatically (see below). The
tools the configs actually touch:

| Tool           | Purpose                                 | Notes                                    |
| -------------- | --------------------------------------- | ---------------------------------------- |
| `zsh`          | Shell                                   | Required                                 |
| `oh-my-zsh`    | Zsh framework (the `plugins` module)    | Installed by bootstrap.sh                |
| `starship`     | Fast prompt                             | Currency: prompt glow                    |
| `fzf`          | Fuzzy finder (Ctrl-R, Ctrl-T, `f*` fns) | Plus bundled `fzf-git` helper            |
| `fd`           | Fast finder (fzf backend, `fv()` fn)    | The `fd-find` package on Debian/Ubuntu   |
| `bat`          | Modern `cat` (`cat`/`less` aliases)     | Preview engine for fzf                   |
| `eza`          | Modern `ls` (`ls`/`ll`/`lt` aliases)    | Nerd-font icons for the tree             |
| `ripgrep`      | Grep backend (`fzf`, LazyVim picker)    | Recommended                              |
| `zoxide`       | Smarter `cd` + tmux project switcher    | `cd` replacer (works on its own)         |
| `delta`        | Git pager + diff                        | The `git-delta` package on Debian/Ubuntu |
| `kitty`        | Terminal emulator                       | Optional, needed for `icat` alias        |
| `tmux`         | Terminal multiplexer                    | Depends on the `z`(oxide) sessionizer    |
| `lazygit`      | Git TUI (tmux `<prefix>+G`, `fgl()`)    | Optional                                 |
| `yazi`         | File manager                            | Optional (plugins installed separately)  |
| `nvim` ≥ 0.10  | Editor (LazyVim, top picker)            | Optional                                 |
| `btop`         | System monitor (`top` alias)            | Optional                                 |
| `glow`         | Markdown renderer (`info` previews)     | Optional                                 |
| `mise`         | Runtime manager (go/java/node)          | Optional (official installer fallback)   |
| `gh`           | GitHub CLI (git credential helper)      | Feeds `hosts.yml` sanitized identity     |
| `tldr`         | Simplified man pages (`info` alias)     | Optional                                 |
| `wl-clipboard` | Wayland clipboard (`tmux` copy mode)    | Switch to `xclip` on X11                 |
| `dolphin`      | KDE file manager (`open` alias)         | Optional (KDE)                           |
| Nerd Font      | Icons/ligatures everywhere              | JetBrainsMono Nerd Font tin              |

> Missing tools degrade gracefully: most aliases/functions are guarded with
> `command -v` checks so the shell still loads if a tool isn't installed.

## Quick start

```bash
git clone https://github.com/asiimwe-dev/dotfiles.git ~/Dev/dotfiles
cd ~/Dev/dotfiles

# 1. Install every required tool (uses dnf/apt/pacman/brew; then Nerd Font)
./bootstrap.sh --full --fonts

# 2. Link the configs into your home
./install.sh

# 3. First-run setup per tool — see "First-time setup per tool" below
nvim                   # bootstraps LazyVim plugins on first launch
tmux new -s test       # press <prefix>+I to install tmux plugins
mise install           # installs go/java/node from config.toml
```

### bootstrap.sh

`bootstrap.sh` detects your package manager (`dnf` / `apt` / `pacman` / `brew`)
and installs everything. It never touches your existing configs — it only
installs packages.

- `./bootstrap.sh --full` — core shell tools + terminal/editor tools (default)
- `./bootstrap.sh --core` — just the core shell tools (zsh, starship, fzf, …)
- `./bootstrap.sh --fonts` — also download JetBrainsMono Nerd Font
- `./bootstrap.sh --dry-run` — show the exact commands without running them
- `./bootstrap.sh --help`

Post-install fallbacks handled automatically:

- **mise** where the package manager doesn't ship it → official installer
- **yazi** where missing → `cargo install yazi-fm yazi-cli`
- **oh-my-zsh** → cloned into `~/.oh-my-zsh` (needed by the zsh `plugins` module)

Any package that fails still reports a clear `[!]` warning so the run survives.

### Installing the tools manually

If you prefer to install by hand (or bootstrap.sh can't detect your distro):

```bash
# Fedora / RHEL (dnf)
sudo dnf install -y zsh git curl starship fzf fd-find bat eza zoxide \
  git-delta ripgrep tmux kitty neovim btop glow gh lazygit tldr \
  dolphin wl-clipboard mise

# Ubuntu / Debian (apt)
sudo apt install -y zsh git curl starship fzf fd-find bat eza zoxide \
  git-delta ripgrep tmux kitty neovim btop gh lazygit tldr dolphin \
  wl-clipboard
# + glow and yazi: see "Tools that need special handling" below.

# Arch (pacman)
sudo pacman -Sy --noconfirm zsh git curl starship fzf fd bat eza zoxide \
  git-delta ripgrep tmux kitty neovim btop glow gh lazygit tldr dolphin \
  wl-clipboard mise yazi

# macOS (homebrew)
brew install zsh git curl starship fzf fd bat eza zoxide git-delta ripgrep \
  tmux kitty neovim btop glow gh lazygit tldr wl-clipboard mise
```

#### Tools that need special handling

- **oh-my-zsh** — `git clone https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh`
  (bootstrap.sh does this if missing).
- **mise** — not on Debian/Ubuntu repos. `curl https://mise.run | sh`, then add
  `mise activate zsh` — already in `config/zsh/tools.zsh`.
- **glow** — not on Debian/Ubuntu. Grab the `.deb` from
  <https://github.com/charmbracelet/glow/releases>.
- **yazi** — not on Debian/Ubuntu repos. `cargo install --locked yazi-fm yazi-cli`
  or download from <https://github.com/sxyazi/yazi/releases>.
- **`fd` vs `fdfind`** — Debian/Ubuntu ship the binary as `fdfind`. If your
  shell says `fd: command not found`, symlink it:
  `sudo ln -s "$(command -v fdfind)" /usr/local/bin/fd`.
- **Nerd Font** — `./bootstrap.sh --fonts`, or download JetBrainsMono Nerd Font
  from <https://www.nerdfonts.com/font-downloads> and install into
  `~/.local/share/fonts/` then run `fc-cache -f`. Kitty must then be set to
  use it (see `config/kitty/kitty.conf`).

## install.sh

Links every config file into your home (symlinks by default):

```bash
cd ~/Dev/dotfiles
./install.sh
```

`install.sh` is safe to run repeatedly:

- **Dry run first**: `./install.sh --dry-run`
- **Back up first**: run `--dry-run`; the real run moves any existing target to
  `~/dotfiles-backups-<timestamp>/` before symlinking.
- **Copy instead of symlink**: `./install.sh --copy`
- **Help**: `./install.sh --help`

### What install.sh links

| Repo file                | Target                       |
| ------------------------ | ---------------------------- |
| `home/.zshrc`            | `~/.zshrc`                   |
| `home/.zprofile`         | `~/.zprofile`                |
| `home/.zshenv`           | `~/.zshenv`                  |
| `home/.gitconfig`        | `~/.gitconfig`               |
| `home/.vimrc`            | `~/.vimrc`                   |
| `config/starship.toml`   | `~/.config/starship.toml`    |
| `config/kitty/*`         | `~/.config/kitty/`           |
| `config/tmux/tmux.conf`  | `~/.config/tmux/tmux.conf`   |
| `config/yazi/*`          | `~/.config/yazi/`            |
| `config/btop/btop.conf`  | `~/.config/btop/btop.conf`   |
| `config/glow/glow.yml`   | `~/.config/glow/glow.yml`    |
| `config/mise/config.toml | `~/.config/mise/config.toml` |
| `config/opencode/*`      | `~/.config/opencode/`        |
| `config/gh/*`            | `~/.config/gh/`              |
| `config/nvim/*`          | `~/.config/nvim/`            |
| `config/zsh/*`           | `~/.config/zsh/`             |

Existing targets are backed up to `~/dotfiles-backups-<timestamp>/` before being
replaced. Uninstall with `./uninstall.sh` (restores nothing automatically, but
tells you where the backups are).

## First-time setup per tool

- **Zsh** — oh-my-zsh is installed by `bootstrap.sh` (or
  `git clone ... ~/.oh-my-zsh`). The plugins it loads (`git`, `sudo`,
  `colored-man-pages`, `zsh-autosuggestions`, `zsh-syntax-highlighting`) are
  enabled in `config/zsh/plugins.zsh`. The `fzf-git` helper is bundled at
  `config/zsh/fzf-git/fzf-git.sh`.
- **Starship** — the prompt config references `$USER`; no further setup.
- **Kitty** — the `current-theme.conf` imports `Solarized Osaka`; make sure your
  `kitty.conf` includes it (it does in this repo) and install a Nerd Font for
  the icons. Adjust `background_opacity` / `background_blur` to taste.
- **tmux** — install [TPM](https://github.com/tmux-plugins/tpm) and then press
  `prefix + I` inside a tmux session to install the plugins referenced by
  `tmux.conf`.
- **Yazi** — plugins (full-border, git, drag, piper, ouch) are declared in
  `config/yazi/package.toml`; install them with:
  ```bash
  cd ~/.config/yazi && ya pkg install
  ```
- **Neovim** — LazyVim bootstraps on first launch (`nvim`); `Lazy` will install
  all plugins automatically. Requires Neovim ≥ 0.10.
- **mise** — versions in `config/mise/config.toml` install on first use
  (`mise install`).

## Customize before publishing

Run `git grep -n "YOUR_\|yourname\|your@email\|<your-username>\|<user>"` and
replace the placeholders in `.gitconfig`, `gh/hosts.yml`,
`nvim/lua/plugins/dashboard.lua`, and this README with your own identity.

## Directory layout

```
dotfiles/
├── README.md
├── bootstrap.sh        # installs every required tool (dnf/apt/pacman/brew)
├── install.sh          # symlink installer (safe: backups + dry-run)
├── uninstall.sh        # removes symlinks created by install.sh
├── LICENSE             # MIT
├── docs/
│   └── dotfiles.md     # full reference: every tool, default AND custom keymap
├── home/               # dotfiles for $HOME
│   ├── .zshrc  .zprofile  .zshenv  .gitconfig  .vimrc
└── config/             # XDG config (→ ~/.config)
    ├── zsh/            # modular shell config (+ fzf-git helper)
    ├── kitty/  tmux/  yazi/  btop/  glow/  mise/  starship.toml
    ├── gh/  opencode/
    └── nvim/           # init.lua, lazyvim.json, lua/config, lua/plugins
```

## Keybindings at a glance

The concise per-tool cheat sheets — including **default** LazyVim/Kitty/tmux
keys — are in [`docs/dotfiles.md`](docs/dotfiles.md). Highlights:

- **Neovim (LazyVim)** — `<leader>` is Space. `<leader>ff` find files, `<leader>fg`
  grep, `<leader>pv` file explorer, `C-h/j/k/l` window nav, `<leader>h` no-highlight.
- **tmux** — `C-a` prefix (custom); `<prefix>h/j/k/l` vim-style panes, `<prefix>+`
  / `-` resize, `<prefix>+I` install plugins.
- **Kitty** — `C-Enter` new window, `C-S-Enter` resize, `C- →/←` select tab,
  `C-S-→/←` move tab, `C-F1..F8` focus window, `C-S-Up/Down` transparency.
- **Yazi** — `<C-a>` bulk rename, `<C-->` toggle sorting by size, `Space`
  select, `y` yank, `p` paste, `"`/`s`/`v` soft/hard/symlink.
- **Zsh** — `Ctrl+R` fzf history, `Ctrl+T` fzf files, `Alt+C` fzf cd,
  `C-l` clear. Custom aliases: `v` nvim, `gs/ga/gc/gp/gl` git, `tt`→ tmux
  project sessionizer (`t`), `i`/`install` dnf install, `cat` → bat.

## Uninstall

```bash
./uninstall.sh
```

Backups from the last install live in `~/dotfiles-backups-<timestamp>/`.

## Troubleshooting

- **Icons missing** → install a Nerd Font (JetBrainsMono Nerd Font) and set it
  as the terminal font; fonts for `eza` icons / `bat` themes come from the same
  font.
- **tmux plugins not loading** → run `<prefix> + I` after installing TPM.
- **nvim plugins not installed** → run `nvim` once with `Lazy` and check
  `:Lazy`.
- **Starship doesn't appear** → confirm `~/.zshrc` sources `starship.zsh`
  module and `starship` binary is on `$PATH`.

## License

[MIT](LICENSE) © Gilbert Asiimwe — feel free to fork and make it yours.
