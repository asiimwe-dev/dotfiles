-- ~/.config/nvim/lua/config/lazy.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		-- LazyVim core + its bundled plugin defaults (extras come from lazyvim.json)
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		-- our own overrides / additions
		{ import = "plugins" },
	},
	-- (`defaults.autocmds` / `defaults.keymaps` were removed: they are not
	-- lazy.nvim options. LazyVim loads its own autocmds and keymaps itself.)
	defaults = { lazy = false, version = false },
	install = { colorscheme = { "solarized-osaka", "tokyonight", "habamax" } },
	checker = { enabled = true, notify = false }, -- check quietly; see :Lazy
	change_detection = { notify = false }, -- no "config changed" popups
	rocks = { enabled = false }, -- no plugin needs luarocks; avoids the hererocks health error
	performance = {
		rtp = {
			disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
		},
	},
})
