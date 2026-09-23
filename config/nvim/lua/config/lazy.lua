-- ~/.config/nvim/lua/config/lazy.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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
		-- LazyVim core + its bundled plugin defaults
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
		-- NOTE: the snacks_picker extra is enabled via lazyvim.json — no
		-- separate import here (importing it in both places is redundant,
		-- LazyVim auto-imports enabled extras before our `plugins`).
		-- our own overrides / additions
		{ import = "plugins" },
	},
	defaults = {
		autocmds = true, -- keep LazyVim's default autocmds
		keymaps = true, -- keep LazyVim's default keymaps (ours layer on top)
	},
	install = { colorscheme = { "solarized-osaka", "tokyonight", "habamax" } },
	checker = { enabled = true }, -- auto-check for plugin updates
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
