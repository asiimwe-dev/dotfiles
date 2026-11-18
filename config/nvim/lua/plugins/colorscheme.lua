-- ~/.config/nvim/lua/plugins/colorscheme.lua
local P = require("config.palette")

return {
	-- Tell LazyVim which colorscheme to apply. Without this it loads tokyonight
	-- first and only then gets overridden by the plugin below.
	{ "LazyVim/LazyVim", opts = { colorscheme = "solarized-osaka" } },

	{
		"craftzdog/solarized-osaka.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			terminal_colors = true,
			styles = {
				comments = { italic = true },
				keywords = { italic = false }, -- comments stay italic; keywords upright
				functions = {},
				variables = {},
				sidebars = "dark",
				floats = "dark",
			},
			on_highlights = function(hl)
				-- Diagnostics undercurl (keep as-is)
				hl.DiagnosticUnderlineError = { undercurl = true, sp = P.red }
				hl.DiagnosticUnderlineWarn = { undercurl = true, sp = P.yellow }
				hl.DiagnosticUnderlineInfo = { undercurl = true, sp = P.sky }
				hl.DiagnosticUnderlineHint = { undercurl = true, sp = P.teal }

				-- Base diagnostic groups (floats, statusline integrations and
				-- anything linking to them) use the bright palette accents.
				hl.DiagnosticError = { fg = P.red }
				hl.DiagnosticWarn = { fg = P.yellow }
				hl.DiagnosticInfo = { fg = P.sky }
				hl.DiagnosticHint = { fg = P.teal }

				-- Gutter signs use the same accent as the inline text and
				-- undercurl (the colorscheme ships darker shades of its own).
				hl.DiagnosticSignError = { fg = P.red }
				hl.DiagnosticSignWarn = { fg = P.yellow }
				hl.DiagnosticSignInfo = { fg = P.sky }
				hl.DiagnosticSignHint = { fg = P.teal }

				-- Inline diagnostic text: coloured + italic on the normal
				-- background. The colorscheme ships tinted backgrounds here
				-- (red900/yellow900/…) which read as loud blocks; a diagnostic
				-- only needs to be legible, not shout.
				hl.DiagnosticVirtualTextError = { fg = P.red, bg = "NONE", italic = true }
				hl.DiagnosticVirtualTextWarn = { fg = P.yellow, bg = "NONE", italic = true }
				hl.DiagnosticVirtualTextInfo = { fg = P.sky, bg = "NONE", italic = true }
				hl.DiagnosticVirtualTextHint = { fg = P.teal, bg = "NONE", italic = true }

				-- Inlay hints: same treatment (colorscheme uses a violet block).
				hl.LspInlayHint = { fg = P.slate, bg = "NONE", italic = true }

				-- Reference highlights: a faint accent tint over the background
				-- instead of an underline, which read like a hover link. The
				-- tint is ~14% of the accent over bg_base (see palette.lua),
				-- so the role colour stays legible without becoming a block.
				hl.LspReferenceText = { bg = P.ref_text }
				hl.LspReferenceRead = { bg = P.ref_read }
				hl.LspReferenceWrite = { bg = P.ref_write }

				-- vim-illuminate (editor.illuminate extra) owns the highlights
				-- actually used for references; give them the same treatment.
				hl.IlluminatedWordText = { bg = P.ref_text }
				hl.IlluminatedWordRead = { bg = P.ref_read }
				hl.IlluminatedWordWrite = { bg = P.ref_write }

				-- ─────────────────────────────────────────────────────────────
				-- Modern transparent notifications – Solarized Osaka palette
				-- ─────────────────────────────────────────────────────────────

				-- Base transparent background for all notify windows
				hl.NotifyBackground = { bg = "NONE" }

				-- ERROR  → Coral / Rose
				hl.NotifyERRORBorder = { fg = P.red, bg = "NONE" }
				hl.NotifyERRORIcon = { fg = P.red, bg = "NONE" }
				hl.NotifyERRORTitle = { fg = P.red, bg = "NONE", bold = true }
				hl.NotifyERRORBody = { fg = P.soft, bg = "NONE" } -- soft white

				-- WARN   → Amber / Gold
				hl.NotifyWARNBorder = { fg = P.yellow, bg = "NONE" }
				hl.NotifyWARNIcon = { fg = P.yellow, bg = "NONE" }
				hl.NotifyWARNTitle = { fg = P.yellow, bg = "NONE", bold = true }
				hl.NotifyWARNBody = { fg = P.soft, bg = "NONE" }

				-- INFO   → Sky / Cyan
				hl.NotifyINFOBorder = { fg = P.sky, bg = "NONE" }
				hl.NotifyINFOIcon = { fg = P.sky, bg = "NONE" }
				hl.NotifyINFOTitle = { fg = P.sky, bg = "NONE", bold = true }
				hl.NotifyINFOBody = { fg = P.soft, bg = "NONE" }

				-- HINT / SUCCESS → Teal / Emerald
				hl.NotifyHINTBorder = { fg = P.teal, bg = "NONE" }
				hl.NotifyHINTIcon = { fg = P.teal, bg = "NONE" }
				hl.NotifyHINTTitle = { fg = P.teal, bg = "NONE", bold = true }
				hl.NotifyHINTBody = { fg = P.soft, bg = "NONE" }

				-- DEBUG / TRACE (subtle)
				hl.NotifyDEBUGBorder = { fg = P.slate, bg = "NONE" }
				hl.NotifyDEBUGIcon = { fg = P.slate, bg = "NONE" }
				hl.NotifyDEBUGTitle = { fg = P.slate, bg = "NONE", bold = true }
				hl.NotifyDEBUGBody = { fg = P.mist, bg = "NONE" }

				hl.NotifyTRACEBorder = { fg = P.violet, bg = "NONE" }
				hl.NotifyTRACEIcon = { fg = P.violet, bg = "NONE" }
				hl.NotifyTRACETitle = { fg = P.violet, bg = "NONE", bold = true }
				hl.NotifyTRACEBody = { fg = P.text, bg = "NONE" }

				-- Command-line messages (also transparent + bright)
				hl.ErrorMsg = { fg = P.red, bg = "NONE", bold = true }
				hl.WarningMsg = { fg = P.yellow, bg = "NONE", bold = true }
			end,
		},
		config = function(_, opts)
			require("solarized-osaka").setup(opts)
			vim.cmd([[colorscheme solarized-osaka]])
			require("config.line_number_hl").setup()
		end,
	},
}
