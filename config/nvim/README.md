# Neovim config

LazyVim-based, Neovim **0.11+** (the config refuses to start on older versions).

```
init.lua                 version guard → config.lazy
lua/config/              options, keymaps, autocmds, palette, ai (Copilot), java_creator, line_number_hl
lua/plugins/             one file per concern (lsp, formatting, ui, lualine, incline, dashboard, …)
scripts/smoke-test.sh    headless boot + stylua check (also run by CI)
lazyvim.json             enabled LazyVim extras
```

## Conventions

- **Colours** live in `lua/config/palette.lua` only.
- **Options** in `options.lua` are only those that differ from LazyVim defaults.
- Anything that `require`s a plugin module inside a spec must be inside an
  `opts = function(_, opts)` — plain tables are evaluated before the plugin exists.
- Avoid prefix mappings on high-frequency keys (`s`, `n`, `;`, `j`): they make
  Neovim wait `timeoutlen` on every press.

## First run on a new machine

```sh
nvim --headless "+Lazy! restore" +qa   # install exactly what lazy-lock.json pins
nvim                                   # then :Copilot auth once, :checkhealth
```

After pulling this audit's changes on an existing machine run `:Lazy clean`
then `:Lazy sync`, and commit the updated `lazy-lock.json`.

## Key changes vs. the previous config

| Removed | Use instead |
|---|---|
| `ss sv sh sj sk sl sc sq` | `<C-h/j/k/l>` (tmux-navigator), `<leader>-` / `<leader>\|` splits, `<leader>wd` close |
| `ns` (flash) | flash's default `s` is back |
| `;f ;r ;e ;j ;m`, `\\` | `<leader>ff` `<leader>sg` `<leader>sd` `<leader>sj` `<leader>sm` `<leader>,` |
| `jj` / `jk` mappings | better-escape.nvim (same keys, no delay) |
| bufferline, dressing.nvim, Snacks notifier, `ai.copilot` extra | incline pill, Snacks.input/picker, nvim-notify + noice, `config/ai.lua` |
| `:JavaNewFile` | `:JavaNew` |
