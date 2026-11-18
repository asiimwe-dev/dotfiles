-- ~/.config/nvim/lua/config/autocmds.lua
-- All autocmds live here. Options belong in options.lua.
--
-- Removed in the audit:
--   * VimEnter session restore — LazyVim loads this file at VeryLazy when
--     nvim starts with no args, i.e. AFTER VimEnter, so it never fired. The
--     dashboard's `s` shortcut restores the session for the current cwd.
--   * vim.highlight.on_yank — deprecated, and LazyVim already highlights yanks.
local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- (The blanket "no diagnostics in markdown" autocmd was removed: markdownlint
-- is already disabled in plugins/formatting.lua, and disabling every
-- diagnostic namespace would silently break any future markdown LSP.)

-- Ecosystem-standard 2-space indentation (prettier/most style guides) so what
-- you type already matches what the formatter will produce on save.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = {
		"dart",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"yaml",
		"html",
		"css",
		"scss",
		"less",
		"vue",
		"svelte",
		"graphql",
		"java",
	},
	callback = function(ev)
		local bo = vim.bo[ev.buf]
		bo.shiftwidth = 2
		bo.tabstop = 2
		bo.softtabstop = 2
	end,
})
