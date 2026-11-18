-- ~/.config/nvim/lua/plugins/git.lua
return {
	{
		"lewis6991/gitsigns.nvim",
		event = "LazyFile",
		opts = {
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			sign_priority = 6,

			signs = {
				add = { text = "●" },
				change = { text = "◆" },
				delete = { text = "▼" },
				topdelete = { text = "▲" },
				changedelete = { text = "◇" },
				untracked = { text = "○" },
			},

			signs_staged = {
				add = { text = "●" },
				change = { text = "◆" },
				delete = { text = "▼" },
				topdelete = { text = "▲" },
				changedelete = { text = "◇" },
			},
		},
		-- sign colours come from the colorscheme's GitSigns* highlight groups
	},
}
