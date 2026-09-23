-- ~/.config/nvim/lua/plugins/formatting.lua
-- NOTE: treesitter parsers for every filetype formatted here
-- are ensured in plugins/polyglot.lua.
return {
	{
		"stevearc/conform.nvim",
		opts = {
			-- Default options applied across all format actions
			default_format_opts = {
				lsp_format = "fallback",
			},

			-- Error handling & user notifications
			notify_on_error = true,
			notify_no_formatters = false,

			formatters_by_ft = {
				-- Lua & Shell Scripting
				lua = { "stylua" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },

				-- JavaScript / TypeScript family
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },

				-- Web components & styling
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				scss = { "prettierd", "prettier", stop_after_first = true },
				less = { "prettierd", "prettier", stop_after_first = true },

				-- Modern frameworks
				vue = { "prettierd", "prettier", stop_after_first = true },
				svelte = { "prettierd", "prettier", stop_after_first = true },

				-- Data, Markup & Config
				json = { "prettierd", "prettier", stop_after_first = true },
				jsonc = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
				graphql = { "prettierd", "prettier", stop_after_first = true },
				toml = { "taplo" },
				sql = { "sql_formatter" },

				-- Python
				python = { "ruff_organize_imports", "ruff_format" },

				-- Systems & Compiled
				c = { "clang-format" },
				cpp = { "clang-format" },
				go = { "goimports", "gofmt" },
				rust = { "rustfmt" },
				zig = { "zigfmt" },

				-- Mobile, JVM & Web Backend
				dart = { "dart_format" },
				java = { "google-java-format" },
				kotlin = { "ktlint" },
				swift = { "swiftformat" },
				php = { "php_cs_fixer" },
				ruby = { "rubocop" },
				elixir = { "mix" },

				-- General fallback for unlisted filetypes
				["_"] = { "trim_whitespace" },
			},
		},
	},
	-- Disable markdownlint / diagnostics for markdown
	{
		"mfussenegger/nvim-lint",
		event = "BufReadPost",
		opts = {
			linters_by_ft = {
				markdown = {},
			},
		},
	},
}
