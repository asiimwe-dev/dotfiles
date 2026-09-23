-- ~/.config/nvim/lua/config/options.lua
-- Core editor options. Autocmds and keymaps live in their own files —
-- this file is strictly `vim.o` / `vim.opt` / `vim.g` settings.

-- Leader Keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- UI Overrides
vim.opt.winbar = "" -- Hide standard winbar since incline.nvim floats status pills
vim.opt.conceallevel = 2 -- Hide markdown formatting markup unless cursor is on line
vim.opt.showtabline = 0
vim.o.winborder = "rounded" -- Rounded borders on floating windows
local fillchars = vim.opt.fillchars:get()
fillchars.eob = "~"
vim.opt.fillchars = fillchars

-- Fallback undercurl escape sequences for legacy terminals
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- setting up the python lsp to use basedpyright instead of pyright
vim.g.lazyvim_python_lsp = "basedpyright"
local opt = vim.opt

-- General Editor Settings
opt.autowrite = true
opt.clipboard = "unnamedplus"
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true
opt.cursorline = true
opt.cursorlineopt = "both"
-- Push the pre-jump window position onto the jumplist (Vim 9 behavior) so
-- <C-o> pops predictably across files/windows; keep LazyVim's "view" too.
opt.jumpoptions = "stack,view"
opt.mouse = "a"
opt.undofile = true
opt.undolevels = 10000

-- Line Numbers & Column
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"

-- Tabs & Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Search Settings
opt.ignorecase = true
opt.smartcase = true

-- Window Splits (complements the <leader>w split/nav keymaps in keymaps.lua)
opt.splitbelow = true
opt.splitright = true

-- Scrolling Context
opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor
opt.sidescrolloff = 8

-- Display & Terminal Colors
opt.termguicolors = true
opt.wrap = false
