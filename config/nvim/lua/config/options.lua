-- ~/.config/nvim/lua/config/options.lua
-- Only settings that DIFFER from LazyVim's defaults live here. Anything
-- LazyVim already sets (autowrite, undofile, number, splitright, …)
-- was removed so this file shows what is actually customised.

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Unused remote-plugin providers: skips probing them at startup and removes
-- the matching :checkhealth errors/warnings. Re-enable one if a plugin needs it.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Language-server preferences (read by LazyVim extras)
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_php_lsp = "intelephense"

-- vim-illuminate's LSP path reads this global (not the plugin `delay` opt), and
-- defaults to 17ms. Match the extra's 200ms so references settle after the
-- cursor stops instead of flashing on every move.
vim.g.Illuminate_delay = 200

local opt = vim.opt

-- UI
opt.winbar = "" -- incline.nvim floats the filename pill instead
opt.conceallevel = 2 -- hide markdown markup unless the cursor is on the line
opt.showtabline = 0 -- no tab/buffer bar; use the buffer picker (<leader>,)

-- Keyboard-only workflow: no mouse in any mode (no click-to-position, wheel
-- scrolling, drag-select or right-click menus). Neovim also stops asking the
-- terminal for mouse reports, so kitty's own selection still works normally.
opt.mouse = ""
vim.o.winborder = "rounded" -- Neovim 0.11+: rounded borders on every float
opt.fillchars:append({ eob = " " }) -- no ~ down empty lines
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.jumpoptions = "stack,view" -- <C-o> pops predictably across files/windows

-- Clipboard: LazyVim deliberately leaves this empty over SSH (no provider,
-- and `unnamedplus` makes every yank/put hit the OSC52 path). Keep that.
vim.schedule(function()
	opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
end)

-- Indentation (per-filetype 2-space overrides live in autocmds.lua)
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

-- Rotate lsp.log once it passes 20 MB so it can't grow unbounded.
local log = vim.lsp.log.get_filename()
local stat = vim.uv.fs_stat(log)
if stat and stat.size > 20 * 1024 * 1024 then
	os.rename(log, log .. ".old")
end
