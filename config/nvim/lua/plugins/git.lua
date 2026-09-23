-- ~/.config/nvim/lua/plugins/git.lua
-- gitsigns stays purely as an in-editor git decorator: gutter signs, hunk
-- stage/reset/blame, and the lualine branch/diff counts. All git
-- *workflows* (log, history, status, stash, diff review) go through
-- lazygit instead — see the <leader>g* keymaps in config/keymaps.lua.
--
-- No `on_attach` here: the hunk/stage/blame keymaps (]h [h <leader>gh* ih)
-- already come from LazyVim's stock gitsigns spec
-- (lazyvim/plugins/editor.lua). Re-declaring a subset was pure
-- duplication; only the sign glyph overrides are custom.
return {
	{
		"lewis6991/gitsigns.nvim",
		event = "LazyFile",
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
		},
	},
}