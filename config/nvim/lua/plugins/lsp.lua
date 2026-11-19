-- ~/.config/nvim/lua/plugins/lsp.lua
-- LSP configuration. Servers listed in `servers` are installed by LazyVim via
-- Mason automatically — no separate mason-lspconfig list is needed (the old
-- one in polyglot.lua duplicated extras and installed servers that were
-- explicitly disabled, e.g. ts_ls next to vtsls).
local diagnostics = require("config.diagnostics")

return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = false, -- true re-runs analysis on every keystroke
				-- ERROR sorts last (HINT -> ERROR), so on a mixed line the
				-- inline message is the error and warnings land in "+N".
				severity_sort = true,
				-- Error Lens: errors *and* warnings inline. The icons, prefix
				-- (+N) and inline noise filter live in config/diagnostics.lua;
				-- `get` is a resolver so <leader>uv can change the level without
				-- LazyVim's own diagnostics config overwriting it.
				virtual_text = diagnostics.get,
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
