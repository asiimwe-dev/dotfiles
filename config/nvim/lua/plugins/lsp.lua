-- ~/.config/nvim/lua/plugins/lsp.lua
-- Consolidated LSP configuration. Previously this was split across
-- python.lua, sql.lua, and part of ui.lua — three separate files all
-- patching `opts` onto the same "neovim/nvim-lspconfig" plugin. Merged here
-- since they're one concern; language-specific formatter/linter config
-- still lives in formatting.lua, and treesitter/mason install lists stay
-- in polyglot.lua.
return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = true,
				virtual_text = {
					severity = { min = vim.diagnostic.severity.ERROR },
				},
				float = {
					border = "rounded",
					source = true,
				},
			},

			-- Inline type/parameter hints globally (moved from ui.lua)
			inlay_hints = {
				enabled = true,
			},

			servers = {
				pyright = { enabled = false },

				-- Python — basedpyright (actively maintained pyright fork).
				--
				-- NOISE REDUCTION: out of the box, basedpyright is noticeably
				-- more opinionated than vanilla pyright and will happily
				-- flag "reportUnknownMemberType", "reportAny", etc. even in
				-- "standard" mode. Those are silenced below via
				-- diagnosticSeverityOverrides, keeping the diagnostics that
				-- actually matter (undefined names, real type mismatches,
				-- unused imports) while dropping the ones that just add
				-- visual noise without much day-to-day value.
				--
				-- If it's ever too quiet or too loud, tune the table below,
				-- or hit <leader>tp on a Python buffer to toggle all
				-- diagnostics off/on entirely (see config/autocmds.lua).
				basedpyright = {
					settings = {
						basedpyright = {
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "openFilesOnly",
								autoImportCompletions = true,
								typeCheckingMode = "standard", -- not "strict" — strict is a lot of noise
								diagnosticSeverityOverrides = {
									-- silence the "Unknown*" family — technically-correct
									-- but low-signal in untyped/partially-typed codebases
									reportMissingTypeStubs = "none",
									reportUnknownMemberType = "none",
									reportUnknownArgumentType = "none",
									reportUnknownVariableType = "none",
									reportUnknownParameterType = "none",
									reportUnknownLambdaType = "none",
									-- silence a couple of the more pedantic/strict-leaning checks
									reportUnusedCallResult = "none",
									reportAny = "none",
									reportImplicitOverride = "none",
									-- downgrade (not silence) — worth knowing about, not worth
									-- an error-level squiggle
									reportUninitializedInstanceVariable = "warning",
								},
							},
						},
					},
				},

				-- SQL
				sqls = {},
			},
		},
	},
}
