# Dotfiles & Developer Tooling Reference

A complete reference to every CLI / developer tool configured on this machine.

> **System:** Fedora (Linux) · KDE Plasma 6 (Wayland) · user `Gilbert Asiimwe`
> **Visual identity:** everything uses a _Solarized Osaka_ / "glassy neon" palette rendered through a Nerd Font (JetBrainsMono Nerd Font).
> **Convention used below:** ✅ = stock/default keymap (documented for completeness) · ✏️ = custom keymap defined in this dotfiles.

---

## 0. Tool Inventory & Config Paths

| Tool                      | Config file(s)                                                                 | Purpose                                |
| ------------------------- | ------------------------------------------------------------------------------ | -------------------------------------- |
| Zsh                       | `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.config/zsh/*.zsh`                  | Interactive shell                      |
| Oh My Zsh                 | `~/.oh-my-zsh/`                                                                | Zsh framework + plugins                |
| Starship                  | `~/.config/starship.toml`, `~/.config/zsh/starship.zsh`                        | Prompt                                 |
| Zoxide                    | (through `~/.config/zsh/tools.zsh`)                                            | Smart `cd`                             |
| Kitty                     | `~/.config/kitty/kitty.conf`, `current-theme.conf`                             | Terminal emulator                      |
| Tmux                      | `~/.config/tmux/tmux.conf` + `plugins/` (TPM)                                  | Terminal multiplexer                   |
| Yazi                      | `~/.config/yazi/{yazi,keymap,theme,package}.toml`, `init.lua`                  | File manager (TUI)                     |
| fzf / fd / bat / eza / rg | `~/.config/zsh/fzf.zsh`, `~/.config/zsh/aliases.zsh`, `~/.config/zsh/fzf-git/` | Fuzzy finder + modern CLI replacements |
| Neovim (LazyVim)          | `~/.config/nvim/`                                                              | Editor                                 |
| Vim (legacy)              | `~/.vimrc`                                                                     | Fallback editor config                 |
| Git + Delta               | `~/.gitconfig`                                                                 | VCS + diff pager                       |
| GitHub CLI (gh)           | `~/.config/gh/config.yml`                                                      | GitHub workflows                       |
| Lazygit                   | `~/.config/lazygit/config.yml` (empty → defaults)                              | Git TUI                                |
| gitui                     | `~/.config/gitui/` (empty)                                                     | Git TUI (unused)                       |
| btop                      | `~/.config/btop/btop.conf`                                                     | System monitor                         |
| glow                      | `~/.config/glow/glow.yml`                                                      | Markdown TUI renderer                  |
| tldr                      | — (`~/.local/bin/tldr`)                                                        | Simplified man pages                   |
| mise                      | `~/.config/mise/config.toml`                                                   | Runtime version manager                |
| opencode                  | `~/.config/opencode/opencode.jsonc`                                            | AI coding CLI (integrated into Neovim) |

---

## 1. Zsh

**Files:** `~/.zshrc` sources `$ZSH_CONFIG=$HOME/.config/zsh/` (modular):
`plugins.zsh` → `env.zsh` → `path.zsh` → `tools.zsh` → `fzf.zsh` → `aliases.zsh` → `functions.zsh` → `options.zsh` → `starship.zsh` (order approx.)

### 1.1 Env & Path

`env.zsh`:

| Variable            | Value                                                                  |
| ------------------- | ---------------------------------------------------------------------- |
| `EDITOR` / `VISUAL` | `nvim`                                                                 |
| `CHROME_EXECUTABLE` | `/usr/bin/brave-browser`                                               |
| `GNIREHTET_APK`     | `$HOME/Downloads/gnirehtet-linux/gnirehtet-rust-linux64/gnirehtet.apk` |

`path.zsh` prepends: `~/.local/bin`, `~/development/flutter/bin`, `~/.pub-cache/bin`, `~/.cargo/bin`, `~/go/bin` (`typeset -U path` dedupes).

### 1.2 Shell Options (`options.zsh`)

| Option                                                        | Effect                              |
| ------------------------------------------------------------- | ----------------------------------- |
| `HISTSIZE=10000`, `SAVEHIST=10000`, `HISTFILE=~/.zsh_history` | Large shared history                |
| `setopt HIST_IGNORE_ALL_DUPS`                                 | No duplicate history entries        |
| `setopt HIST_REDUCE_BLANKS`                                   | Collapse blank runs in history      |
| `setopt SHARE_HISTORY`                                        | History shared across sessions      |
| `setopt AUTO_CD`                                              | Type a dir name to `cd` into it     |
| `setopt HIST_IGNORE_SPACE`                                    | Leading-space commands not recorded |

### 1.3 Aliases (`aliases.zsh`)

**General**

| Alias           | Command                                        |
| --------------- | ---------------------------------------------- |
| `c`             | `clear`                                        |
| `e`             | `exit`                                         |
| `r`             | `reset`                                        |
| `icat`          | `kitty +kitten icat` (inline image cat)        |
| `zshconfig`     | `$EDITOR ~/.zshrc`                             |
| `reload`        | `source ~/.zshrc`                              |
| `lab`           | `ssh <user>@<host>` (example: personal VM/Lab) |
| `open`          | `dolphin` (KDE file manager)                   |
| `top`           | `btop`                                         |
| `pkglist`       | `dnf list --installed \| fzf`                  |
| `tls`           | `tmux ls`                                      |
| `t`             | `tmux`                                         |
| `info`          | `tldr`                                         |
| `upgrade`       | `sudo dnf upgrade -y`                          |
| `i` / `install` | `sudo dnf install `                            |

**Neovim** — `v` → `nvim`

**Git**

| Alias | Command                                |
| ----- | -------------------------------------- |
| `gs`  | `git status`                           |
| `ga`  | `git add .`                            |
| `gc`  | `git commit -m`                        |
| `gp`  | `git push`                             |
| `gl`  | `git log --oneline --graph --decorate` |

**Flutter**

| Alias     | Command           |
| --------- | ----------------- |
| `f`       | `flutter`         |
| `fget`    | `flutter pub get` |
| `fr`      | `flutter run`     |
| `fdoctor` | `flutter doctor`  |

**eza (`ls` family)** — all pass `--icons=always` & `--group-directories-first` by default:

| Alias | Command                                                   |
| ----- | --------------------------------------------------------- |
| `ls`  | `eza --icons=always --group-directories-first`            |
| `ll`  | `eza -lh --group --git --git-ignore --header --classify`  |
| `la`  | `eza -lah --group --git --git-ignore --header --classify` |
| `lt`  | `eza --tree --level=2 --git-ignore`                       |
| `lta` | `eza --tree --all --level=2 --git-ignore`                 |
| `lS`  | `eza -lh --total-size --group --header --classify`        |
| `lg`  | `eza -lah --git --git-ignore --header` (git-only view)    |
| `lm`  | `eza -lh --sort=modified --reverse` (newest first)        |
| `lx`  | `eza -lh --sort=size --reverse`                           |

**bat** — `cat`/`less`/`more` → `bat`; `MANPAGER` renders man pages through bat (`col -bx | bat -l man -p`).

**Yazi**

| Alias | Command           |
| ----- | ----------------- |
| `fm`  | `y` (current dir) |
| `yh`  | `y ~`             |
| `yd`  | `y ~/Dev`         |
| `yc`  | `y ~/.config`     |

### 1.4 Functions (`functions.zsh`)

| Function           | Purpose                                                              |
| ------------------ | -------------------------------------------------------------------- |
| `mkcd <dir>`       | `mkdir -p` then `cd`                                                 |
| `fgl`              | Interactive git log browser (fzf + live diff preview via `git show`) |
| `fgb`              | Interactive git branch switcher (fzf checkout)                       |
| `fgs`              | Interactive git stash viewer (`git stash show -p`)                   |
| `fv`               | fzf file finder (fd) → open selection in `nvim`                      |
| `bhead [N] [file]` | `head` through bat (default 10 lines)                                |
| `btail [N] [file]` | `tail` through bat (default 10 lines)                                |

### 1.5 Hook: Automatic Tmux Sessionizer

`auto_tmux_project()` (in `aliases.zsh`) — fired on `chpwd` and at shell start:

- Skips if already inside tmux.
- If CWD is a project (`.git`, `pubspec.yaml`, `package.json`, `Cargo.toml`, `go.mod`, `CMakeLists.txt`, `docker-compose.yml`, `Dockerfile`):
  - **Attaches** to an existing tmux session named after the dir, or
  - **Creates** a session (sanitized name), and if Docker is present opens Window 2 named `docker` already running `docker compose logs -f`.

### 1.6 Keymaps

**Zsh built-in line-editor defaults (vim keys not enabled — emacs mode):**

| Key                 | Action                             |
| ------------------- | ---------------------------------- |
| `Ctrl-A` / `Ctrl-E` | Move to line start / end           |
| `Ctrl-U` / `Ctrl-K` | Kill to line start / end           |
| `Ctrl-W`            | Delete word backward               |
| `Ctrl-Y`            | Yank killed text                   |
| `Ctrl-R`            | Reverse incremental history search |
| `Ctrl-S`            | Forward search                     |
| `Ctrl-L`            | Clear screen                       |
| `Ctrl-D`            | Delete char (or EOF)               |
| `Alt-B` / `Alt-F`   | Move word backward / forward       |
| `Alt-D`             | Delete word forward                |

**Fzf (via `source <(fzf --zsh)` in `fzf.zsh`):**

| Key                       | Action                                                                       |
| ------------------------- | ---------------------------------------------------------------------------- |
| `Ctrl-T`                  | Insert file paths (fd-backed, bat preview)                                   |
| `Ctrl-R`                  | History search (echo preview)                                                |
| `Alt-C`                   | `cd` into selected dir (eza tree preview)                                    |
| `Alt-T`                   | File widget (✏️ bound in `tools.zsh` to dodge kitty's `Ctrl-T` tab shortcut) |
| `Tab / Shift-Tab` (fzf)   | Multi-select                                                                 |
| `Ctrl-?` / `Ctrl-/` (fzf) | Toggle preview                                                               |

**fzf-git (josean shell bindings, `~/.config/zsh/fzf-git/fzf-git.sh`):**
All start with `Ctrl-G` then:

| Key               | Action                                                        |
| ----------------- | ------------------------------------------------------------- |
| `Ctrl-G Ctrl-F`   | Files (git ls-files)                                          |
| `Ctrl-G Ctrl-B`   | Branches → `git checkout`                                     |
| `Ctrl-G Ctrl-T`   | Tags                                                          |
| `Ctrl-G Ctrl-R`   | Remotes                                                       |
| `Ctrl-G Ctrl-H`   | Commit hashes                                                 |
| `Ctrl-G Ctrl-S`   | Stashes                                                       |
| `Ctrl-G Ctrl-L`   | Reflog                                                        |
| `Ctrl-G Ctrl-W`   | Worktrees                                                     |
| `Ctrl-G Ctrl-E`   | Each reference                                                |
| `Ctrl-G ?`        | Show help                                                     |
| `Tab / Shift-Tab` | Multi-select (diffs across selected files)                    |
| `Ctrl-/`          | Toggle preview                                                |
| `Ctrl-O`          | Open file/branch/commit/browse in browser (`gh`/`git browse`) |
| `Alt-E`           | Open selected file in `$EDITOR`                               |

**zsh-autosuggestions (✅ plugin defaults):**

| Key                        | Action                     |
| -------------------------- | -------------------------- |
| `Ctrl-F` / `End` / `Right` | Accept full suggestion     |
| `Ctrl-G`                   | Accept partial suggestion  |
| `Alt-F`                    | Accept & move to next word |

**oh-my-zsh `sudo` plugin (✅):** press `Esc Esc` to prepend `sudo` to current command.

**zsh-syntax-highlighting** custom styles (`tools.zsh`): valid paths bold `#7aa2f7`, separators `#7dcfff`, unknown tokens dim `#565f89`, `-`/`--` options purple `#bb9af7`, autcd bold blue.

### 1.7 misce / ssh-agent

`tools.zsh` also: starts `ssh-agent` + adds `~/.ssh/id_ed25519` when no agent socket is present, and `eval "$(mise activate zsh)"`.

---

## 2. Oh My Zsh

**Config:** `~/.config/zsh/plugins.zsh` → `ZSH="$HOME/.oh-my-zsh"`, `ZSH_THEME=""` (empty — Starship renders the prompt; powerlevel10k kept but **disabled**), `COMPLETION_WAITING_DOTS=true`, `HYPHEN_INSENSITIVE=true`.

**Plugins enabled:** `git`, `sudo`, `colored-man-pages`, `zsh-autosuggestions`, `zsh-syntax-highlighting`.

**Git plugin aliases (✅ stock, the useful subset):**

| Alias  | Command                           | Alias    | Command                        |
| ------ | --------------------------------- | -------- | ------------------------------ |
| `g`    | `git`                             | `gst`    | `git status`                   |
| `ga`   | `git add`                         | `gaa`    | `git add --all`                |
| `gap`  | `git add -p`                      | `gc!`    | `git commit --amend`           |
| `gca`  | `git commit -a`                   | `gcm`    | `git commit -m`                |
| `gcam` | `git commit -am`                  | `gd`     | `git diff`                     |
| `gcaa` | `git commit -a --amend`           | `gds`    | `git diff --staged`            |
| `gb`   | `git branch`                      | `gba`    | `git branch -a`                |
| `gco`  | `git checkout`                    | `gcb`    | `git checkout -b`              |
| `gl`   | `git pull`                        | `glg`    | `git log --stat`               |
| `glgg` | `git log --graph`                 | `glog`   | `git log --oneline --decorate` |
| `gm`   | `git merge`                       | `grb`    | `git rebase`                   |
| `grh`  | `git reset HEAD`                  | `grs`    | `git restore`                  |
| `gst`  | `git status`                      | `gss`    | `git status -s`                |
| `gsh`  | `git show`                        | `gsta`   | `git stash push`               |
| `gstp` | `git stash pop`                   | `gstl`   | `git stash list`               |
| `gsw`  | `git switch`                      | `gswc`   | `git switch -c`                |
| `gt`   | `git ls-tree -r --name-only HEAD` | `git rm` | …full `git` completion         |

---

## 3. Starship Prompt

**Files:** `~/.config/starship.toml`, `~/.config/zsh/starship.zsh`.
**Palette:** `solarized_osaka` — bg container `#052630`, accent colors `2dd4bf`/`38bdf8`/`c084fc`/`ff5370`/`4ade80`/`fbbf24`/`f97316`.

**Prompt layout (left):** `username` (only when showing user) → `hostname` (ssh only) → `os` → `directory` (truncation 3, substitutions like `~/Projects`, `.config`) → `readonly` marker → git (`branch`/`state`/`status`/`metrics`) → `sudo` → `jobs` → language modules (C, Java, Ruby, PHP, Zig, Lua, Node, Bun, Python, Rust, Go) → `package` → `docker_context` → `kubernetes` → `aws` → newline → `character` (❯).

**Right prompt:** `memory_usage` (≥75% shown) · `cmd_duration` (≥2 s) · `status` (nonzero only) · `time` (12h).

**Zsh integration hooks (`starship.zsh`):**

- `ZLE_RPROMPT_INDENT=0` removes the right-prompt margin.
- `precmd` hook writes window title (`~`) preserving `$?`.
- **Transient prompt (toggleable, persistent):** default keeps the full prompt (cmd duration, memory, time, dir/git/package info) visible on every finished line. `starship-transient` opts into collapsing executed prompts to a cyan `❯`; `starship-full` restores the full prompt; `starship-reset` clears persisted state back to the default. The choice is stored in `~/.local/state/starship.transient` (`XDG_STATE_HOME`), so it survives terminal restarts until you toggle it again. `STARSHIP_TRANSIENT=1` in the environment sets an opt-in baseline.
- `eval "$(starship init zsh)"` runs after Oh My Zsh.

---

## 4. Kitty Terminal

**Files:** `~/.config/kitty/kitty.conf`, `~/.config/kitty/current-theme.conf` (`Solarized Osaka`).

**Look & feel:** JetBrainsMono Nerd Font 14.0, ligatures never, `cell_height 110%`, thick-sparse undercurls (LSP), background opacity 0.95 with dynamic blur, 6px padding, powerline top tab bar with Nerd icons, scrolled interactive scrollbar (`#7aa2f7`), animated cursor trail (`#7aa2f7`, threshold 1 → every `hjkl` animates), 50k-line scrollback rendered through `nvim` as pager, deep shell integration on, remote control via unix socket `@kitty`, layouts `splits,tall,grid,stack`, `focus_follows_mouse no`, `copy_on_select yes`, bell to notification unfocused, mouse hides on keypress.

### 4.1 Custom keymaps (✏️)

**Clipboard / font / opacity**

| Key                                    | Action                           |
| -------------------------------------- | -------------------------------- |
| `Ctrl+Shift+C`                         | Copy to clipboard                |
| `Ctrl+Shift+V`                         | Paste from clipboard             |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+Backspace` | Font size +1 / −1 / reset        |
| `Ctrl+Shift+=` / `Ctrl+Shift+-`        | Background opacity +0.05 / −0.05 |
| `Ctrl+Shift+0`                         | Reset background opacity         |

**Windows & splits**

| Key                | Action                                              |
| ------------------ | --------------------------------------------------- |
| `Alt+S`            | Split window (hsplit), keep cwd                     |
| `Alt+V`            | Split window (vsplit), keep cwd                     |
| `Alt+Enter`        | New window, keep cwd                                |
| `Alt+Q`            | Close window                                        |
| `Alt+Z`            | Toggle layout `stack` (zoom)                        |
| `Ctrl+Alt+H/J/K/L` | Move focus to neighboring window left/down/up/right |
| `Alt+Shift+H/L`    | Resize window narrower / wider (5)                  |
| `Alt+Shift+K/J`    | Resize window taller / shorter (5)                  |
| `Alt+N`            | Next layout                                         |

**Tabs**

| Key                           | Action                   |
| ----------------------------- | ------------------------ |
| `Ctrl+T`                      | New tab with current cwd |
| `Ctrl+Shift+T`                | New tab                  |
| `Ctrl+Shift+W`                | Close window             |
| `Alt+,` / `Alt+.`             | Previous / next tab      |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab      |
| `Ctrl+Shift+N`                | New OS window            |
| `Alt+1..9`                    | Goto tab 1–9             |

**Developer launchers (open in cwd)**

| Key            | Action           |
| -------------- | ---------------- |
| `Ctrl+Shift+G` | Launch `lazygit` |
| `Ctrl+Shift+B` | Launch `btop`    |
| `Ctrl+Shift+H` | Launch `htop`    |
| `Ctrl+Shift+E` | Launch `nvim`    |

**Kitten hints** (press `Ctrl+Shift+P` then the letter)

| Key                | Action                                 |
| ------------------ | -------------------------------------- |
| `Ctrl+Shift+P` `f` | Hints over file paths (pipe to stdout) |
| `…` `u`            | Hints over URLs (open)                 |
| `…` `l`            | Hints over lines                       |
| `…` `w`            | Hints over words                       |
| `…` `h`            | Hints over hashes                      |

**Broadcast / scrollback / reload**

| Key            | Action                          |
| -------------- | ------------------------------- |
| `Ctrl+Shift+X` | Toggle broadcast to all windows |
| `Ctrl+Shift+F` | Show scrollback (in nvim pager) |
| `Ctrl+Shift+R` | Reload kitty config live        |

### 4.2 Stock kitty keymaps (✅, not overridden — still active)

| Key                             | Action                                                                                              |
| ------------------------------- | --------------------------------------------------------------------------------------------------- |
| `Ctrl+Shift+Up/Down/Left/Right` | Move focus between windows                                                                          |
| `Ctrl+Shift+Enter`              | New window (same layout)                                                                            |
| `Ctrl+Shift+U`                  | Unicode input (kitten)                                                                              |
| `Ctrl+Shift+H`                  | Kitten hints for paths (replaced by `p` prefix above is ✏️; the base hint kitten remains reachable) |
| `Ctrl+Shift+Home`               | Scrollback to top                                                                                   |
| `Ctrl+Shift+PageUp/PageDown`    | Scroll line / page                                                                                  |
| `Ctrl+Shift+Q`                  | Quit kitty (not remapped)                                                                           |
| `Ctrl+Shift+D`                  | Close tab                                                                                           |
| `Ctrl+Shift+E`                  | Edit kitty config (kitten)                                                                          |

> Run `kitty +kitten` / `Ctrl+Shift+?` inside kitty to dump the full live key-map table — this config only replaces the keys listed in 4.1.

---

## 5. Tmux

**File:** `~/.config/tmux/tmux.conf` · **Plugins:** TPM, `tmux-resurrect`, `tmux-continuum`, `tmux-sensible`, `vim-tmux-navigator`, `tmux-open`, `extrakto`.

**Core settings:** default-shell `/bin/zsh`; prefix **`Ctrl-a`** (`Ctrl-b` unbound); `escape-time 1`; `history-limit 100000`; mouse on; `allow-passthrough on` (kitty images/OSC52); vi status/copy keys; `base-index 1`, `pane-base-index 1`, `renumber-windows on`; win titles synced with kitty (`set-titles`); extended-keys + terminal overrides for kitty undercurls/RGB; copy-command `wl-copy` (Wayland clipboard); `focus-events on`.

### 5.1 Prefix = `Ctrl-a`

**Core (✅ + ✏️ overrides shown)**

| Binding          | Action                                             |
| ---------------- | -------------------------------------------------- |
| `Ctrl-a`         | Send literal prefix (✅)                           |
| `Ctrl-a r`       | ✏️ Reload `tmux.conf` + popup toast                |
| `Ctrl-a Ctrl-s`  | ✏️ Save workspace (resurrect) + toast              |
| `Ctrl-a Ctrl-r`  | ✏️ Restore workspace + toast                       |
| `Ctrl-a y`       | ✏️ Toggle `synchronize-panes` + toast              |
| `Ctrl-a c`       | ✏️ New window (in current dir)                     |
| `Ctrl-a \|`      | ✏️ Split horizontally (current dir) — replaces `%` |
| `Ctrl-a -`       | ✏️ Split vertically (current dir) — replaces `"`   |
| `Ctrl-a H/J/K/L` | Resize pane L5 / D5 / U5 / R5 (repeatable)         |
| `Ctrl-a z`       | Zoom pane (✅)                                     |
| `Ctrl-a x`       | ✏️ Kill-pane with confirm                          |
| `Ctrl-a X`       | ✏️ Kill-window with confirm                        |
| `Ctrl-a <` / `>` | ✏️ Swap window left/right (repeatable)             |
| `Ctrl-a S`       | ✏️ Swap with named window                          |
| `Ctrl-a s`       | ✏️ Session picker (`choose-tree`)                  |
| `Ctrl-a N`       | ✏️ New named session (current dir)                 |
| `Ctrl-a f`       | ✏️ Fuzzy sessionizer (zoxide+fzf popup)            |
| `Ctrl-a g`       | ✏️ Floating scratchpad popup (85%)                 |
| `Ctrl-a G`       | ✏️ Floating lazygit popup (90%)                    |
| `Ctrl-a d`       | Detach (✅)                                        |
| `Ctrl-a [`       | Copy-mode (✅)                                     |
| `Ctrl-a ?`       | List keys (✅)                                     |

**Window selection without prefix — `Alt+1..9`, `Alt+0`** (✏️, prefix-free `-n`): jump straight to window 1–10.

### 5.2 Vim-aware pane navigation (✏️)

| Key                         | Action                                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------------------- |
| `Ctrl-h/j/k/l` (no prefix)  | If a vim/nvim/fzf process fills the pane → forward the key to it; else move focus (smart `is_vim` check) |
| `Ctrl-h/j/k/l` in copy-mode | Move pane focus                                                                                          |

### 5.3 Copy-mode (vi) keymaps (✏️)

| Key                                                                                                         | Action                      |
| ----------------------------------------------------------------------------------------------------------- | --------------------------- |
| `v`                                                                                                         | Begin selection             |
| `Ctrl-v`                                                                                                    | Rectangle (block) toggle    |
| `y`                                                                                                         | Copy selection → `wl-copy`  |
| `Y`                                                                                                         | Copy & cancel → `wl-copy`   |
| `Enter`                                                                                                     | Copy & cancel → `wl-copy`   |
| `MouseDragEnd`                                                                                              | Mouse-drag copy → `wl-copy` |
| ✅ additionally: `h/j/k/l`, `w/b`, `0/$`, `g/G`, `PageUp/Down`, `/` search, `q` exit etc. (tmux vi default) |

### 5.4 Plugins

**vim-tmux-navigator (✅/✏️ active via `-n` binds above)** — seamless `Ctrl-h/j/k/l` across nvim↔tmux because the plugin's own binds replaced by the `is_vim` ones; inside nvim the plugin's `<c-w>`-style integration is in §9.

**tmux-resurrect:** ✏️ `Ctrl-a Ctrl-s` save, `Ctrl-a Ctrl-r` restore; `@resurrect-capture-pane-contents on`; processes `docker "docker compose" psql mysql btop ssh "flutter run"`.

**tmux-continuum:** auto-save every **15 min** (`@continuum-save-interval '15'`), **auto-restore off** (`@continuum-restore 'off'`).

**tmux-open (✅ default):** in copy-mode `o` opens the selected path/URL in the OS handler; `Shift+o` opens in editor/browser per selection type.

**extrakto (✏️ config):** `@extrakto_key 'e'` → in copy-mode `e` pops a vertical 12-line fuzzy picker of words/paths/IPs from visible pane; `Ctrl-m` copies choice to clipboard.

### 5.5 Status bar

Top-positioned glassy bar: left session pill (turns amber `#fbbf24` while prefix pressed, `ZOOM` pill when zoomed), active window = teal pill with auto-named path (`#I  dfolder`), inactive = muted container, right status shows `SYNC` alert + host (`#H`) + CPU (top) + RAM (free). Automatic window renaming to `basename(pane_current_path)`.

---

## 6. Yazi

**Files:** `~/.config/yazi/{yazi.toml, keymap.toml, theme.toml, package.toml, init.lua}`. Plugins: `full-border`, `git`, `piper`, `ouch`, `drag`.

**Manager defaults:** hidden files off (`✏️` toggled with `.`), natural sort, size linemode, `scrolloff 5`, mouse = click/scroll/**drag**; preview cache `~/.cache/yazi`; openers — `edit` = `nvim %s` (block), `open` = `xdg-open`, `play_video` = `vlc`, `play_audio` = `elisa`; md preview via `piper`+`glow`, archives via `ouch`, git status via `git` plugin.

### 6.1 Custom keymaps (✏️ `keymap.toml`, prepended — overriding/augmenting defaults)

| Key                 | Action                                                         |
| ------------------- | -------------------------------------------------------------- |
| `!`                 | Open `$SHELL` in current dir (block)                           |
| `e`                 | Open hovered file in Neovim                                    |
| `.`                 | Toggle hidden files                                            |
| `R`                 | Refresh                                                        |
| `g p`               | Jump to `~/Dev` (projects)                                     |
| `Ctrl-e` / `Ctrl-y` | Scroll preview down / up 5 units                               |
| `C`                 | Compress/extract with `ouch` plugin                            |
| `d` / `D`           | Trash / permanently delete (kept explicit, ✅ already default) |
| `s g`               | Content search via ripgrep                                     |
| `s f`               | Filename search via fd                                         |
| `Ctrl-n`            | Drag selected files (drag plugin)                              |

### 6.2 Stock keymaps (✅ default preset — unchanged ones remain active)

**Motion & selection**

| Key                                      | Action                          |
| ---------------------------------------- | ------------------------------- |
| `j/k` or `↓/↑`                           | Next / previous file            |
| `g g` / `G` (or `Home`/`End`)            | Top / bottom                    |
| `Ctrl-u` / `Ctrl-d`                      | Up / down half page             |
| `Ctrl-b` / `Ctrl-f`                      | Up / down one page              |
| `S-PageUp/S-PageDown`, `PageUp/PageDown` | Half / full page                |
| `h` / `l` (or `←/→`)                     | Leave / enter directory         |
| `H` / `L`                                | Back / forward history          |
| `Space`                                  | Toggle selection (sticky)       |
| `Ctrl-a`                                 | Select all                      |
| `Ctrl-r`                                 | Invert selection                |
| `v` / `V`                                | Visual mode / visual unset mode |
| `Tab`                                    | Spot hovered file               |
| `K` / `J`                                | Seek preview up / down          |

**Operations**

| Key                    | Action                                         |
| ---------------------- | ---------------------------------------------- |
| `o` / `Enter`          | Open selected files                            |
| `O` / `Shift+Enter`    | Open interactively                             |
| `y`/`x`/`p`/`P`        | Yank (copy) / cut / paste / paste-force        |
| `-` / `_`              | Symlink absolute / relative link               |
| `Ctrl--`               | Hardlink                                       |
| `Y` / `X`              | Cancel yank                                    |
| `d` / `D`              | Trash / permanent delete                       |
| `a` / `A`              | Create file(s) (run by path) / bulk create     |
| `r`                    | Rename                                         |
| `;` / `:`              | Shell (non-block) / shell (block, interactive) |
| `s` / `S`              | Search files by name (fd) / by content (rg)    |
| `Ctrl-s`               | Cancel ongoing search                          |
| `z` / `Z`              | Jump via fzf / zoxide plugins                  |
| `w`                    | Task manager                                   |
| `Ctrl-a`… (list multi) | (see above)                                    |

**Linemode (`m` prefix)**

| Key                                           | Action                                            |
| --------------------------------------------- | ------------------------------------------------- |
| `m s` / `m p` / `m b` / `m m` / `m o` / `m n` | Size / permissions / btime / mtime / owner / none |

**Copy (`c` prefix)**

| Key                                           | Action                                                      |
| --------------------------------------------- | ----------------------------------------------------------- |
| `c c` / `c C` / `c d` / `c D` / `c f` / `c n` | Path / URL / dirpath / dirurl / filename / name-without-ext |

**Filter / find / sort**

| Key                                 | Action                                                                            |
| ----------------------------------- | --------------------------------------------------------------------------------- |
| `f`                                 | Filter (smart)                                                                    |
| `/` / `?`                           | Find next / previous                                                              |
| `n` / `N`                           | Next / previous found                                                             |
| `, m/M, b/B, e/E, a/A, n/N, s/S, r` | Sort by mtime/btime/extension/alphabetical/natural/size/random, `Shift` = reverse |

**Goto (`g` prefix)**

| Key                                   | Action                                                      |
| ------------------------------------- | ----------------------------------------------------------- |
| `g h` / `g c` / `g d` / `g t` / `g f` | Home / `~/.config` / `~/Downloads` / trash / follow symlink |
| `g Space`                             | Jump interactively                                          |
| `g p` (✏️)                            | `~/Dev`                                                     |

**Tabs & tasks**

| Key           | Action                        |
| ------------- | ----------------------------- |
| `t t` / `t r` | New tab in CWD / rename tab   |
| `1–9`         | Goto tab 1–9                  |
| `[` / `]`     | Previous / next tab           |
| `{` / `}`     | Swap with previous / next tab |

**Popups (tasks/spot/pick/input/confirm/cmp/help)** — all share vim-style motion (`j/k`), `Esc`/`Ctrl-c` cancel, `Enter` submit; input box supports `h/l/w/b/W/e/E/0/$` `Ctrl-u/k/w` kill/delete, `y/p/P` cut-and-insert / paste, `Ctrl-r` redo, `u/U` case, `k/j/Ctrl-p/Ctrl-n` history recall; completion menu uses `Alt-j/k`, `Ctrl-p/n`, `Tab` submit; confirm uses `y/n`.

**Yazi exit integration:** the `y()` shell function (`tools.zsh`) writes cwd to a temp file so quitting Yazi `cd`s your shell exactly where the cursor was.

---

## 7. fzf · fd · bat · eza · zoxide · rg

**Files:** `~/.config/zsh/fzf.zsh`, `~/.config/zsh/fzf-git/fzf-git.sh`, `~/.config/zsh/aliases.zsh`, `~/.config/zsh/tools.zsh`.

### 7.1 fzf (`fzf.zsh`)

- `FZF_DEFAULT_COMMAND`: `fd --type f --hidden --follow --exclude .git`
- `FZF_ALT_C_COMMAND`: `fd --type d …`; `FZF_CTRL_T_COMMAND` = file command.
- `FZF_DEFAULT_OPTS`: Solarized-Osaka colors, rounded border, prompt `󰁔` , pointer `󰅂`, marker `󰄬`, `--height 50% --layout=reverse --info=inline`.
- Previews: `Ctrl-T` → `bat` (fallback `eza --tree`); `Alt-C` → `eza --tree`; `Ctrl-R` → plain echo preview.
- `**<Tab>` completion uses `fd` (`_fzf_compgen_path/dir`).

### 7.2 fd · zoxide · rg (no keymaps — CLI)

- `fd` powers fzf + `fv`; `rg` powers `fgl` previews and Yazi `s g`.
- `zoxide init zsh --cmd cd` → **`cd` is now smart**: `cd foo` fuzzy-matches dirs, `cd ..`/`cd /abs` work as before, `cd -` travels history; powers tmux sessionizer ‑§5.1.

### 7.3 bat

`cat`/`less`/`more` aliases + `MANPAGER` + `bhead`/`btail`; fzf previews use `bat --style=numbers`. Theme inherits Solarized (dark) in fzf previews.

---

## 8. Neovim (LazyVim)

**Layout:** `~/.config/nvim/init.lua` → `lua/config/lazy.lua` (bootstrap lazy.nvim, import `LazyVim/LazyVim` + local `plugins/`). `lazyvim.json` enables extras (git: ai.copilot; coding: mini-comment, mini-snippets, mini-surround, yanky; dap.core; editor: dial, illuminate, inc-rename, overseer, snacks_picker; formatting.prettier; lang: clangd/dart/elixir/go/java/json/markdown/php/python/sql/tailwind/toml/typescript/typescript.vtsls/yaml; test.core; treesitter-context; util: dot/mini-hipatterns/project). Colorscheme **solarized-osaka** (transparent).

**Core options:** `mapleader = " "`, `maplocalleader = "\"`, `clipboard=unnamedplus`, `relativenumber`, `scrolloff 8`, `undofile`, `smartcase`, split positions, rounded winborder, `winbar` hidden (incline floats the filename), `showtabline 0`.

> **Operating conventions:** no bufferline bar is visible (intentional — `Shift+H/L` still cycle buffers, `\\` opens the buffer list). All git _workflows_ go through **lazygit**; gitsigns stays for gutter/hunk/blame only. AI engines start **off** and are opt-in.

### 8.1 Custom keymaps (✏️ — `lua/config/keymaps.lua`)

**AI engine controls** (see also 8.4)

| Key           | Action                  |
| ------------- | ----------------------- |
| `<leader>aic` | Switch AI to Copilot    |
| `<leader>ain` | Switch AI to NeoCodeium |
| `<leader>aio` | Switch AI off           |
| `<leader>ait` | Cycle engine            |
| `<leader>ais` | Show engine status      |
| `<M-l>` (i)   | Accept full suggestion  |
| `<M-w>` (i)   | Accept word             |
| `<M-a>` (i)   | Accept line             |
| `<C-]>` (i)   | Dismiss suggestion      |

**Window navigation & splitting (`s` prefix — flash moved to `ns`, see 8.4)**

| Key                    | Action                                |
| ---------------------- | ------------------------------------- |
| `s s`                  | Horizontal split                      |
| `s v`                  | Vertical split                        |
| `s h/j/k/l`            | Move to left/below/above/right window |
| `s c` / `s q`          | Close / quit window                   |
| `<C-d>` / `<C-u>`      | Scroll half-page + center (`zz`)      |
| `<C-Up> / <C-Down>`    | Increase / decrease height (+2)       |
| `<C-Left> / <C-Right>` | Decrease / increase width (−2/+2)     |
| `<A-j>` / `<A-k>`      | Move line(s) down / up (n & v)        |

**Buffers**

| Key               | Action                      |
| ----------------- | --------------------------- |
| `<S-h>` / `<S-l>` | Previous / next buffer      |
| `<leader>bb`      | Switch to last buffer       |
| `\\`              | Buffer list picker (Snacks) |

**History / marks**

| Key          | Action                        |
| ------------ | ----------------------------- |
| `<leader>hj` | Clear jump list (all windows) |
| `<leader>hm` | Clear all marks               |

**Editor**

| Key                   | Action                              |
| --------------------- | ----------------------------------- |
| `<leader>aa`          | Select all (`gg<S-v>G`)             |
| `jk` / `jj` (i)       | Exit insert mode                    |
| `<A-d>` (n,i)         | Line diagnostics float              |
| `<leader>tp` (python) | Toggle Python diagnostics in buffer |

**Git (`<leader>g*` → lazygit workflows)**

| Key                                                              | Action                         |
| ---------------------------------------------------------------- | ------------------------------ |
| `<leader>gl`                                                     | Git log (repo root) in lazygit |
| `<leader>gL`                                                     | Git log (cwd) in lazygit       |
| `<leader>gf`                                                     | Git file log in lazygit        |
| ✏️ (removed `<leader>gd/gD/gs/gS/fg/gb` — lazygit replaced them) |

**Java automation** (module `config/java_creator.lua`)

| Key / cmd         | Action                         |
| ----------------- | ------------------------------ |
| `:JavaNew`        | New project or new file (menu) |
| `:JavaNewProject` | Scaffold project               |
| `:JavaNewFile`    | New class/interface/enum…      |
| `:JavaRun`        | Compile & run project          |
| `<leader>jn`      | JavaNew                        |
| `<leader>jr`      | JavaRun                        |

**Web preview**

| Key                   | Action                         |
| --------------------- | ------------------------------ |
| `<leader>Pu`          | Open dev server URL in browser |
| (see 8.4 live-server) | static preview tier            |

### 8.2 LazyVim stock keymaps (✅ — all active unless overridden above)

**Core**

| Key                                               | Action                                                                  |
| ------------------------------------------------- | ----------------------------------------------------------------------- |
| `j/k`, `<Up>/<Down>`                              | Smart gj/gk (better up/down)                                            |
| `<C-h/j/k/l>`                                     | Window navigation                                                       |
| `<C-Up/Down/Left/Right>`                          | Window resize (✏️ re-mapped same in custom)                             |
| `<A-j>` / `<A-k>`                                 | Move line down / up                                                     |
| `<S-h>` / `<S-l>`, `[b` / `]b`                    | Prev / next buffer                                                      |
| `<leader>bb`, `<leader>`                          | Other buffer                                                            |
| `<leader>bd` / `<leader>bo` / `<leader>bi`        | Delete buffer / other buffers / invisible buffers                       |
| `<leader>bD`                                      | Delete buffer & window                                                  |
| `<Esc>` (i,n,s)                                   | Clear search & stop snippet                                             |
| `<leader>ur`                                      | Redraw / clear hlsearch / diff update                                   |
| `n` / `N`                                         | Next / prev search result (with `zv`)                                   |
| `,` `.` `;` (i)                                   | Undo break-points                                                       |
| `<C-s>`                                           | Save file                                                               |
| `<leader>K`                                       | Keywordprg                                                              |
| `<` / `>` (v)                                     | Better indenting                                                        |
| `gco` / `gcO`                                     | Add comment below / above                                               |
| `<leader>l`                                       | Lazy plugin manager                                                     |
| `<leader>fn`                                      | New file                                                                |
| `<leader>xl` / `<leader>xq`                       | Location list / quickfix list                                           |
| `[q` / `]q`                                       | Prev / next quickfix                                                    |
| `<leader>cf`                                      | Format (forced)                                                         |
| `<leader>cd`                                      | Line diagnostics (float)                                                |
| `]d`/`[d`, `]e`/`[e`, `]w`/`[w`                   | Next/prev diagnostic (all / error / warn)                               |
| `<leader>q q`                                     | Quit all                                                                |
| `<leader>ui` / `<leader>uI`                       | Inspect pos / inspect tree                                              |
| `<leader>L`                                       | LazyVim changelog                                                       |
| `<leader>fT` / `<leader>ft`                       | Terminal (cwd / root)                                                   |
| `<c-/>` / `<c-_>`                                 | Toggle terminal focus                                                   |
| `<leader>-` / `<leader>\|`                        | Split below / right                                                     |
| `<leader>wd`                                      | Delete window                                                           |
| `<leader>wm` / `<leader>uz`                       | Zoom / zen mode                                                         |
| `<leader><tab>` (followed by `l/o/f/<tab>/]/d/[`) | Last tab / close other tabs / first / new / next / close / previous tab |
| `<localleader>r` (lua)                            | Run current buffer (Snacks debug)                                       |

**Toggle options (`<leader>u…`)**

| Key                              | Action                                                        |
| -------------------------------- | ------------------------------------------------------------- |
| `uf` / `uF`                      | Format on save: off / on                                      |
| `us` / `uw` / `uL` / `ud` / `ul` | Spelling / wrap / relative number / diagnostics / line number |
| `uc` / `uA` / `uT`               | Conceal / tabline / treesitter                                |
| `ub` / `uD` / `ua` / `ug` / `uS` | Dark background / dim / animate / indent / scroll             |
| `uh`                             | Inlay hints                                                   |
| `uG`                             | Gitsigns (signs toggle)                                       |
| `dpp` / `dph`                    | Profiler / profiler highlights                                |

**Git (✅ active except overridden)**

| Key                             | Action                                                                                                                        |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `<leader>gg` / `<leader>gG`     | Lazygit (root / cwd)                                                                                                          |
| `<leader>gL`/`gb`/`gf`/`gl`     | Git log cwd / blame line / file history / log root (✏️ `gl`/`gL`/`gf` now open lazygit)                                       |
| `<leader>gB` / `<leader>gY`     | Git browse open / copy URL                                                                                                    |
| `]h` / `[h` (gitsigns)          | Next / prev hunk                                                                                                              |
| `]H` / `[H`                     | Last / first hunk                                                                                                             |
| `<leader>ghs/r/S/u/R/p/b/B/d/D` | Stage hunk / reset hunk / stage buffer / undo stage / reset buffer / preview hunk / blame line / blame buffer / diff / diff ~ |
| `ih` (o,x)                      | Select hunk                                                                                                                   |

**Picker (Snacks) & which-key**

| Key                          | Action                      |
| ---------------------------- | --------------------------- |
| `<leader><space>`            | Find files                  |
| `<leader>sf`                 | Find files                  |
| `<leader>sg`                 | Live grep                   |
| `<leader>sr`                 | Search & replace (grug-far) |
| `<leader>sh`                 | Search highlight            |
| `<leader>sc`                 | Search buffer               |
| `<leader>sd`                 | Diagnostics                 |
| `<leader>sk`                 | Keymaps                     |
| `<leader>sS`                 | With-overlap grep           |
| `<leader>sw`                 | Word                        |
| `<leader>ss`                 | Word (all)                  |
| `<leader>sb`                 | Buffers                     |
| `<leader>so`                 | Options                     |
| `<leader>gc`                 | Get recent project          |
| `<leader><space>`, `u`, `d`… | (which-key popups)          |

**Which-key groups (✅):** `<leader><tab>` tabs · `a` ✏️ ai · `b` buffers/window · `c` code · `d` debug · `dp/…` ✏️ java/profiler · `e` ✏️ · lazy config files · `f` file/find · `F` ✏️ flutter · `g` git · `gh` hunks · `h` ✏️ history · `j` ✏️ java · `M` ✏️ molten · `o` overseer · `P` ✏️ web-preview · `q` quit/session · `r` refactor · `s` search · `t` test · `u` ui · `x` diagnostics/quickfix · `[` prev-* · `]` next-*.

**Flash (✅ stock → ✏️ remapped `ns`)**

| Key         | Action                           |
| ----------- | -------------------------------- |
| `ns`        | Flash jump (custom trigger)      |
| `S`         | Flash treesitter select          |
| `r` / `R`   | Remote flash / treesitter search |
| `<c-s>`     | Toggle flash search              |
| `<c-space>` | Treesitter incremental selection |

### 8.3 Plugin keymaps from local specs (✏️)

**dial.nvim (`plugins/dial.lua`) — language-aware increment/decrement**

| Key                 | Action                                     |
| ------------------- | ------------------------------------------ |
| `<C-a>` / `<C-x>`   | Increment / decrement (n,v)                |
| `g<C-a>` / `g<C-x>` | Increment / decrement with gn motion (n,v) |

Augends configured: number bases, dates, semver, booleans, `let`/`const`, `and`/`or`, `yes/no`, `on/off`, ordinals, weekdays, months, camel↔snake↔Pascal↔SCREAMING case, quotes `"`↔`'`, brackets `(`↔`[`↔`{`, markdown headers, checkboxes, hex colors per filetype.

**yanky.nvim (`plugins/yanky.lua`)**

| Key               | Action                           |
| ----------------- | -------------------------------- |
| `<leader>p`       | Open yank history                |
| `p` / `P`         | Put after / before (yanky)       |
| `<c-p>` / `<c-n>` | Cycle forward / backward in ring |

**refactoring.nvim** — `<leader>r` (visual) pick extraction refactor.

**opencode.nvim (`plugins/opencode.lua`)**

| Key          | Action                                    |
| ------------ | ----------------------------------------- |
| `<leader>oa` | Ask with `@this` context                  |
| `<leader>oq` | Ask (plain)                               |
| `<leader>os` | Select AI session                         |
| `<leader>ot` | Toggle terminal (right dock)              |
| `<leader>on` | New session                               |
| `<leader>oi` | Interrupt session                         |
| `go` / `goo` | Operator: append range / line to OpenCode |

**flutter-tools.nvim (`plugins/flutter.lua`)**

| Key                                      | Action                                                       |
| ---------------------------------------- | ------------------------------------------------------------ |
| `<leader>Fr` / `Fq` / `FR` / `Fl`        | Run / quit / hot restart / hot reload                        |
| `<leader>Fd` / `Fe` / `FL` / `Ft` / `Fo` | Devices / emulators / log toggle / DevTools / outline toggle |

**Molten / notebooks (`plugins/molten.lua`)**

| Key                                                                  | Action                                                                                                            |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `<leader>Mi` / `MI`                                                  | Init kernel / info                                                                                                |
| `<leader>Me` (n)                                                     | Evaluate operator (motion)                                                                                        |
| `<leader>Me` (v)                                                     | Evaluate visual selection                                                                                         |
| `<leader>Ml` / `Mr` / `Md` / `Mh` / `Mo` / `Mx` / `MR` / `Mn` / `Mp` | Eval line / re-eval cell / delete cell / hide output / enter output / interrupt / restart / next cell / prev cell |
| `<leader>MN`                                                         | New notebook (`:PyNotebookNew`)                                                                                   |

**live-server.nvim (`plugins/live-server.lua`)**

| Key                                                    | Action                                                             |
| ------------------------------------------------------ | ------------------------------------------------------------------ |
| `<leader>Ps` / `Po` / `Pr` / `Pt` / `Pi` / `PS` / `PA` | Start / open / reload / toggle live / status / stop one / stop all |

**vim-tmux-navigator (`plugins/tmux.lua`)** — `<c-h/j/k/l>` navigate tmux panes (integrates with §5.2), `<c-\>` previous.

### 8.4 Completion & AI (blink.cmp + copilot/neocodeium)

- Completion engine **blink.cmp** (LazyVim default, **enter** preset): `Tab`/`Shift-Tab` cycle, `Enter` accept, `<C-n>/<C-p>` move, `<C-e>` close; `auto_brackets` on after function completion (✏️ `plugins/coding.lua`). ✅ default blink keymaps apply.
- Neovim built-in completions remain: `<C-x><C-o>`, `<C-n>/<C-p>` word completion, `<C-x>C-f` files etc. (Vim defaults).
- Copilot.lua / Neocodeium: **engines start off**; privacy-gated (1 MB, secret/credential filename & filetype blocklist); ✏️ unified accept keys set in 8.1 (`<M-l>/<M-w>/<M-a>`, `<M-]>`/`<M-[>` next/prev suggestion ✅ copilot default, `<C-]>` dismiss).

### 8.5 Dashboard (`plugins/dashboard.lua`, ✏️ "hyper" theme)

`f` find file · `n` new file · `p` projects · `g` find text · `c` config files · `s` restore session · `x` lazy extras · `l` lazy · `q` quit. 🅿 Panel also lists active projects & recent files.

### 8.6 Legacy Vim (`~/.vimrc`)

vim-plug plugins: fzf/fzf.vim, vim-commentary, vim-surround, vim-gitgutter, lightline (wombat). **Leader = Space.** Keymaps: `jj`/`jk` ⟶ `Esc`; `<Leader><Space>` nohlsearch; `<C-h/j/k/l>` window nav; `<Leader>bn/bp/bd` buffers; `<Leader>e` netrw `Lexplore 25`; `<Leader>f` `:Files`; `<Leader>b` `:Buffers`. Per-filetype indent autocmds; trailing-whitespace strip on save; restore cursor position; persistent undo.

---

## 9. Git Toolchain

### 9.1 Git + Delta (`~/.gitconfig`)

`user.name` = Asiimwe Gilbert, GitHub noreply email; `editor=nvim`; `pager=delta`; offline `interactive.diffFilter=delta --color-only`; `init.defaultBranch=main`; `pull.rebase=true`; **gh as credential helper** for github.com & gist.github.com. **Delta:** `side-by-side=true`, `navigate=true`, `line-numbers=true` (✅ delta default keys also apply: `n`/`N` jump, `+/-` zoom, `Ctrl+Up/Down` scroll, `q` quit).

### 9.2 GitHub CLI (`~/.config/gh/config.yml`)

`git_protocol: https`, `editor: code` (VS Code for gh templates), alias **`co → pr checkout`**. Credential helper wires gh into git (9.1). Key commands: `gh pr create`, `gh pr checkout`/`gh co`, `gh issue list/new`, `gh repo clone`, `gh browse` (used by fzf-git `Ctrl-O` + nvim `<leader>gB`).

### 9.3 Lazygit (`~/.config/lazygit/config.yml` — empty ⇒ **all stock keymaps active**)

| Key                 | Action                                        |
| ------------------- | --------------------------------------------- |
| `1–5`               | Files / Branches / Commits / Stash / … panels |
| `j/k` / `PgUp/PgDn` | Navigate                                      |
| `enter`             | Open / log panel                              |
| `space`             | Stage file / line                             |
| `a`                 | Stage all                                     |
| `c`                 | Commit                                        |
| `C`                 | Commit editor                                 |
| `m`                 | Amend                                         |
| `P`                 | Push                                          |
| `p`                 | Pull                                          |
| `b`                 | Checkout branch                               |
| `n`                 | New branch                                    |
| `d`                 | Delete (confirm)                              |
| `v`                 | Paste (stash)                                 |
| `/`                 | Filter in panel                               |
| `x`                 | Menu / custom commands                        |
| `[` / `]`           | Prev / next tab                               |
| `:`                 | Command log                                   |
| `?`                 | Keybindings reference                         |
| `q` / `<esc>`       | Quit selected popup / quit                    |

### 9.4 gitui (`~/.config/gitui/` — empty, unused)

Defaults only if invoked. No active customization.

---

## 10. btop

**File:** `~/.config/btop/btop.conf` — `vim_keys = false`, themed 256/truecolor.

**Default keymaps (✅):**

| Key                 | Action                       |
| ------------------- | ---------------------------- |
| `↑/↓` / mouse wheel | Move selection               |
| `F1` / `?`          | Help & keybindings reference |
| `F2` / `m`          | Options menu                 |
| `q`                 | Quit                         |
| `e`                 | Edit config file             |
| `p`                 | Pause all updates            |
| `f`                 | Filter/process search box    |
| `t`                 | Tree mode on/off             |
| `x`                 | Kill/signal selected process |
| `+` / `-`           | Zoom graph scale             |
| `1…`                | Focus specific box           |
| `Tab/shift`         | Box navigation               |

---

## 11. glow & tldr

- **glow** (`~/.config/glow/glow.yml`): style `auto`, width 80, mouse off, no pager. ✅ TUI keys: arrows/`PgUp/PgDn`+`j/k/h/l` scroll, ``/`<`/`>` navigate word/styled, `1–9` / `#!/#?` heading jumps, `/ ?` search↔back, `p` percentages, `n/N` next/prev match (in search), `v` toggle Vim manner, `s` select, `Enter` open URL/file, `ESC` quit, `q` quit, `?` help.
- **tldr** — `info <cmd>` = `tldr <cmd>`; no keymaps (text program).

---

## 12. mise

**File:** `~/.config/mise/config.toml` → tools:

| Tool   | Version                |
| ------ | ---------------------- |
| `go`   | 1.26.5                 |
| `java` | temurin-25.0.3+9.0.LTS |
| `node` | 24.18.0                |

`mise activate zsh` hooks into PATH per directory/mise.toml. No keymaps (CLI). Useful: `mise ls`, `mise install`, `mise use`, `mise exec`.

---

## 13. opencode

**Config:** `~/.config/opencode/opencode.jsonc` (schema only). The real integration lives inside Neovim (`plugins/opencode.lua`, §8.3): `<leader>oa/oq/os/ot/on/oi` + `go` operator; server runs in a right-dock terminal, autoread on, widened curl probe timeout. CLI: `opencode` (TUI: arrows/enter, `/` commands, `esc`/`q`).

---

## 14. Cross-Tool Quick Reference

**Fuzzy everything:** zsh `Ctrl-R` history · `Alt-C` cd · `Ctrl-T` file insert · `Ctrl-G *` fzf-git · tmux `Ctrl-a f` session · nvim `<leader><space>` files / `<leader>sg` grep · yazi `s f`/`s g`.

**Git at a glance:** zsh `gs/ga/gc/gp/gl` + fzf-git (`Ctrl-G Ctrl-B` checkout, `Ctrl-G Ctrl-H` commit) + tmux `Ctrl-a G` lazygit + nvim `<leader>gl` lazygit log / `]h[` hunks.

**Jump maps:** kitty `Ctrl-Alt-H/J/K/L` panes ↔ tmux `Ctrl-h/j/k/l` ↔ nvim `<C-h/j/k/l>` & `s h/j/k/l` ↔ yazi `h/l`, `H/L`.

**Splitting:** kitty `Alt+S/V` · tmux `Ctrl-a | / -` · nvim `ss` / `sv` / `<leader>-` / `<leader>\|`.

**Toggle hidden files:** yazi `.` ✏️ · eza `la` · fzf `fd --hidden`.

**Terminal launchers:** kitty `Ctrl-Shift-G/B/H/E` → lazygit/btop/htop/nvim.

**AI (Neovim):** `<leader>aic/ain/aio/ait/ais`, accept `<M-l>/<M-w>/<M-a>`, `<C-]>` dismiss.

> ℹ️ Every stock keymap listed above comes from the tool's shipped defaults. When both a ✅ default and a ✏️ custom map target the same key, the ✏️ custom one wins (documented per section).
