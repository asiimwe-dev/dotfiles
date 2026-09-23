-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
	{
		"craftzdog/solarized-osaka.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			terminal_colors = true,
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
				sidebars = "dark",
				floats = "dark",
			},
			on_highlights = function(hl)
				hl.DiagnosticUnderlineError = { undercurl = true, sp = "#ff5555" }
				hl.DiagnosticUnderlineWarn = { undercurl = true, sp = "#f59e0b" }
				hl.DiagnosticUnderlineInfo = { undercurl = true, sp = "#38bdf8" }
				hl.DiagnosticUnderlineHint = { undercurl = true, sp = "#10b981" }
			end,
		},
		config = function(_, opts)
			require("solarized-osaka").setup(opts)
			vim.cmd([[colorscheme solarized-osaka]])
			require("config.line_number_hl").setup()
		end,
	},
}
