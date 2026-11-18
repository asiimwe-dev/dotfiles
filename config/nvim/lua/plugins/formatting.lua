-- ~/.config/nvim/lua/plugins/formatting.lua
-- conform.nvim formatters + the Mason packages they need.
--
-- IMPORTANT: anything that `require`s a plugin module (conform.util here)
-- must run inside an `opts = function` — a plain table is evaluated while
-- lazy.nvim is still reading specs, before the plugin is on the runtimepath.
return {
	-- Formatter binaries (LazyVim only installs stylua/shfmt + whatever extras bring)
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"clang-format",
				"google-java-format",
				"php-cs-fixer",
				"sql-formatter",
			})
		end,
	},

	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			local util = require("conform.util")
			local php_stub_dir = vim.fn.stdpath("config") .. "/php"

			opts.default_format_opts = vim.tbl_deep_extend("force", opts.default_format_opts or {}, {
				lsp_format = "fallback",
				timeout_ms = 5000, -- php-cs-fixer is slow; default 3s is often too tight
			})
			opts.notify_on_error = true
			opts.notify_no_formatters = false

			-- Per-project web formatting:
			--   * project has biome.json(c)  -> biome-check (see require_cwd below)
			--   * anything else              -> prettier. conform resolves the PROJECT's
			--     node_modules/.bin/prettier first (so prettier-plugin-tailwindcss etc.
			--     work) and falls back to Mason's. With no Prettier config it formats
			--     with Prettier defaults (formatting.prettier extra:
			--     lazyvim_prettier_needs_config = false).
			local prettier = { "prettier" }
			local biome_or_prettier = { "biome-check", "prettier", stop_after_first = true }
			opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
				-- Lua & shell
				lua = { "stylua" },
				sh = { "shfmt" },
				bash = { "shfmt" },

				-- JavaScript / TypeScript family, web, data, markup
				javascript = biome_or_prettier,
				typescript = biome_or_prettier,
				javascriptreact = biome_or_prettier,
				typescriptreact = biome_or_prettier,
				vue = biome_or_prettier,
				svelte = biome_or_prettier,
				json = biome_or_prettier,
				jsonc = biome_or_prettier,
				css = biome_or_prettier,
				graphql = biome_or_prettier,
				-- Biome doesn't format these: always Prettier
				html = prettier,
				scss = prettier,
				less = prettier,
				yaml = prettier,
				markdown = prettier, -- (replaces the markdown extra's markdownlint-cli2 formatter, as before)
				["markdown.mdx"] = prettier,
				toml = { "taplo" },
				sql = { "sql_formatter" },

				-- Python
				python = { "ruff_organize_imports", "ruff_format" },

				-- Systems & JVM & backend
				c = { "clang-format" },
				cpp = { "clang-format" },
				rust = { "rustfmt" },
				dart = { "dart_format" },
				java = { "google-java-format" },
				php = { "php_cs_fixer" },

				-- Fallback for everything not listed (zsh included)
				["_"] = { "trim_whitespace" },
			})
			-- (kotlin/swift/ruby/zig entries were dropped: nothing else in
			--  this config supports those languages.)

			opts.formatters = opts.formatters or {}

			-- conform's built-in biome-check does NOT set require_cwd: without this it
			-- would run with Biome's default rules in projects that have no biome.json.
			opts.formatters["biome-check"] = { require_cwd = true }
			opts.formatters.php_cs_fixer = {
				-- Prefer the project-local binary, then fall back to Mason's
				command = util.find_executable({
					"vendor/bin/php-cs-fixer",
					"tools/php-cs-fixer/vendor/bin/php-cs-fixer",
				}, "php-cs-fixer"),
				-- Respect the project's own .php-cs-fixer(.dist).php. Passing
				-- --rules on top of a config file would override it, so the
				-- PSR-12 rule set is only a fallback for projects without one.
				args = function(_, ctx)
					local cfg = vim.fs.find({ ".php-cs-fixer.php", ".php-cs-fixer.dist.php" }, {
						upward = true,
						path = ctx.dirname,
						limit = 1,
					})[1]
					local args = { "fix", "--using-cache=no" }
					if cfg then
						table.insert(args, "--config=" .. cfg)
					else
						table.insert(args, "--rules=@PSR12,no_extra_blank_lines")
					end
					table.insert(args, "$FILENAME")
					return args
				end,
				stdin = false,
				-- @auto rule sets read composer.json from the cwd. Use the project's
				-- own when it exists, otherwise a stub from this config so projects
				-- without Composer still format.
				cwd = function(self, ctx)
					return util.root_file({ "composer.json" })(self, ctx) or php_stub_dir
				end,
			}
		end,
	},

	-- No markdownlint in markdown buffers; phpcs uses the project's ruleset if
	-- there is one, otherwise PSR-12 (matches what php-cs-fixer formats to).
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.markdown = {}

			local phpcs = require("lint").linters.phpcs
			local global_ruleset = vim.fn.stdpath("config") .. "/php/phpcs.xml"
			phpcs.args = {
				"-q",
				"--report=json",
				function()
					local ruleset = vim.fs.find(
						{ "phpcs.xml", ".phpcs.xml", "phpcs.xml.dist", ".phpcs.xml.dist" },
						{ upward = true, path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) }
					)[1]
					return "--standard=" .. (ruleset or global_ruleset)
				end,
				"-",
			}
		end,
	},
}
