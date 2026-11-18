-- ~/.config/nvim/lua/plugins/lsp.lua
-- LSP configuration. Servers listed in `servers` are installed by LazyVim via
-- Mason automatically — no separate mason-lspconfig list is needed (the old
-- one in polyglot.lua duplicated extras and installed servers that were
-- explicitly disabled, e.g. ts_ls next to vtsls).
local sev = vim.diagnostic.severity

-- Nerd Font glyphs (Material Design Icons), by codepoint so they survive
-- copy/paste. Same set lualine uses for its diagnostic counters.
local diag_icons = {
	[sev.ERROR] = vim.fn.nr2char(0xf015a), -- nf-md-alert_circle
	[sev.WARN] = vim.fn.nr2char(0xf0026), -- nf-md-alert
	[sev.INFO] = vim.fn.nr2char(0xf02fc), -- nf-md-information
	[sev.HINT] = vim.fn.nr2char(0xf0335), -- nf-md-lightbulb
}

local function diag_icon(severity)
	return diag_icons[severity] or diag_icons[sev.ERROR]
end

return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = false, -- true re-runs analysis on every keystroke
				virtual_text = {
					severity = { min = sev.ERROR },
					spacing = 2,
					source = "if_many",
					-- Neovim renders one prefix per diagnostic on a line but only
					-- the last diagnostic's message. Emit the prefix only for that
					-- last item, so a line with several errors shows one icon
					-- instead of "●●●".
					prefix = function(d, i, total)
						if i ~= total then
							return ""
						end
						local icon = diag_icon(d.severity)
						return total > 1 and string.format("%s +%d", icon, total - 1) or icon
					end,
					-- Keep the line readable; the full message (with source and
					-- code) still opens in the <A-d> float.
					format = function(d)
						local msg = vim.trim((d.message:gsub("%s*\n%s*", " ")))
						local max = 90
						if vim.fn.strdisplaywidth(msg) > max then
							msg = vim.fn.strcharpart(msg, 0, max - 1) .. "…"
						end
						return msg
					end,
				},
				float = {
					border = "rounded",
					source = true,
					focusable = false,
				},
			},
			-- (inlay_hints = { enabled = true } removed: LazyVim default.)

			servers = {
				-- Python: LazyVim picks basedpyright from vim.g.lazyvim_python_lsp
				-- (options.lua) and disables pyright itself.
				--
				-- NOISE REDUCTION: basedpyright is more opinionated than vanilla
				-- pyright. "standard" mode plus the overrides below keeps real
				-- errors (undefined names, type mismatches, unused imports) and
				-- drops the low-signal "Unknown*" family. Tune freely; <leader>ud
				-- toggles all diagnostics.
				basedpyright = {
					settings = {
						basedpyright = {
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "openFilesOnly",
								autoImportCompletions = true,
								typeCheckingMode = "standard",
								diagnosticSeverityOverrides = {
									reportMissingTypeStubs = "none",
									reportUnknownMemberType = "none",
									reportUnknownArgumentType = "none",
									reportUnknownVariableType = "none",
									reportUnknownParameterType = "none",
									reportUnknownLambdaType = "none",
									reportUnusedCallResult = "none",
									reportAny = "none",
									reportImplicitOverride = "none",
									reportUninitializedInstanceVariable = "warning",
								},
							},
						},
					},
				},

				-- Web / infra servers (cssls, emmet, biome, tailwind tweaks live in plugins/web.lua)
				html = {},
				dockerls = {},

				-- SQL
				sqls = {},

				-- PHP – Intelephense (formatting owned by conform + php-cs-fixer)
				intelephense = {
					settings = {
						intelephense = {
							format = { enable = false },
							files = { maxSize = 5000000 },
						},
					},
				},
			},
		},
	},
}
