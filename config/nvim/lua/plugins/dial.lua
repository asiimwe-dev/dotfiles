-- ~/.config/nvim/lua/plugins/dial.lua
-- Full-power dial.nvim config for LazyVim

local M = {}

---@param increment boolean
---@param g? boolean
function M.dial(increment, g)
	local mode = vim.fn.mode(true)
	local is_visual = mode == "v" or mode == "V" or mode == "\22"
	local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
	local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
	return require("dial.map")[func](group)
end

return {
	"monaqa/dial.nvim",
  -- stylua: ignore
  keys = {
    { "<C-a>",  function() return M.dial(true) end,      expr = true, desc = "Increment", mode = { "n", "v" } },
    { "<C-x>",  function() return M.dial(false) end,     expr = true, desc = "Decrement", mode = { "n", "v" } },
    { "g<C-a>", function() return M.dial(true, true) end,  expr = true, desc = "Increment", mode = { "n", "v" } },
    { "g<C-x>", function() return M.dial(false, true) end, expr = true, desc = "Decrement", mode = { "n", "v" } },
  },

	opts = function()
		local augend = require("dial.augend")

		------------------------------------------------------------------
		-- Reusable custom constants
		------------------------------------------------------------------
		local logical_alias = augend.constant.new({
			elements = { "&&", "||" },
			word = false,
			cyclic = true,
		})

		local bool = augend.constant.new({
			elements = { "true", "false" },
			word = true,
			cyclic = true,
		})

		local Bool = augend.constant.new({
			elements = { "True", "False" },
			word = true,
			cyclic = true,
		})

		local let_const = augend.constant.new({
			elements = { "let", "const" },
			word = true,
			cyclic = true,
		})

		local and_or = augend.constant.new({
			elements = { "and", "or" },
			word = true,
			cyclic = true,
		})

		local yes_no = augend.constant.new({
			elements = { "yes", "no" },
			word = true,
			cyclic = true,
		})

		local on_off = augend.constant.new({
			elements = { "on", "off" },
			word = true,
			cyclic = true,
		})

		local ordinal_numbers = augend.constant.new({
			elements = {
				"first",
				"second",
				"third",
				"fourth",
				"fifth",
				"sixth",
				"seventh",
				"eighth",
				"ninth",
				"tenth",
			},
			word = false,
			cyclic = true,
		})

		local weekdays = augend.constant.new({
			elements = {
				"Monday",
				"Tuesday",
				"Wednesday",
				"Thursday",
				"Friday",
				"Saturday",
				"Sunday",
			},
			word = true,
			cyclic = true,
		})

		local weekdays_short = augend.constant.new({
			elements = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
			word = true,
			cyclic = true,
		})

		local months = augend.constant.new({
			elements = {
				"January",
				"February",
				"March",
				"April",
				"May",
				"June",
				"July",
				"August",
				"September",
				"October",
				"November",
				"December",
			},
			word = true,
			cyclic = true,
		})

		local months_short = augend.constant.new({
			elements = {
				"Jan",
				"Feb",
				"Mar",
				"Apr",
				"May",
				"Jun",
				"Jul",
				"Aug",
				"Sep",
				"Oct",
				"Nov",
				"Dec",
			},
			word = true,
			cyclic = true,
		})

		------------------------------------------------------------------
		-- Groups
		------------------------------------------------------------------
		return {
			dials_by_ft = {
				-- Web / JS ecosystem
				javascript = "typescript",
				javascriptreact = "typescript",
				typescript = "typescript",
				typescriptreact = "typescript",
				vue = "vue",
				svelte = "typescript",
				astro = "typescript",

				-- Styles
				css = "css",
				scss = "css",
				sass = "css",
				less = "css",

				-- Data / config
				json = "json",
				jsonc = "json",
				yaml = "yaml",
				yml = "yaml",
				toml = "default",

				-- Languages
				python = "python",
				lua = "lua",
				go = "go",
				rust = "rust",
				c = "c",
				cpp = "c",
				java = "java",
				kotlin = "java",
				ruby = "ruby",
				php = "php",
				sh = "shell",
				bash = "shell",
				zsh = "shell",
				fish = "shell",

				-- Markup / docs
				markdown = "markdown",
				md = "markdown",
				org = "markdown",
				norg = "markdown",

				-- Other
				sql = "sql",
				graphql = "default",
			},

			groups = {
				------------------------------------------------------------------
				-- DEFAULT – used by any unmapped filetype + as base for others
				------------------------------------------------------------------
				default = {
					-- Numbers
					augend.integer.alias.decimal, -- 0, 1, 2, …
					augend.integer.alias.decimal_int, -- …, -2, -1, 0, 1, 2, …
					augend.integer.alias.hex, -- 0x1a, 0xff, …
					augend.integer.alias.octal, -- 0o755
					augend.integer.alias.binary, -- 0b1010

					-- Dates & time
					augend.date.alias["%Y-%m-%d"], -- 2024-08-13
					augend.date.alias["%Y/%m/%d"], -- 2024/08/13
					augend.date.alias["%m/%d/%Y"], -- 08/13/2024
					augend.date.alias["%d/%m/%Y"], -- 13/08/2024
					augend.date.alias["%m/%d"], -- 08/13
					augend.date.alias["%H:%M:%S"], -- 14:30:00
					augend.date.alias["%H:%M"], -- 14:30

					-- Booleans & common toggles
					bool,
					Bool,
					yes_no,
					on_off,
					logical_alias, -- && ↔ ||

					-- Versioning
					augend.semver.alias.semver, -- 1.2.3

					-- Natural language
					ordinal_numbers,
					weekdays,
					weekdays_short,
					months,
					months_short,

					-- Case cycling (camelCase ↔ snake_case ↔ …)
					augend.case.new({
						types = { "camelCase", "snake_case", "PascalCase", "SCREAMING_SNAKE_CASE" },
						cyclic = true,
					}),

					-- Quotes & brackets
					augend.paren.alias.quote, -- " ↔ '
					augend.paren.alias.brackets, -- ( ↔ [ ↔ {
				},

				------------------------------------------------------------------
				-- TYPESCRIPT / JAVASCRIPT / VUE / SVELTE / ASTRO
				------------------------------------------------------------------
				typescript = {
					let_const, -- let ↔ const
					bool,
					logical_alias,
					-- (rest comes from default via list_extend below)
				},

				vue = {
					let_const,
					bool,
					logical_alias,
					augend.hexcolor.new({ case = "lower" }),
					augend.hexcolor.new({ case = "upper" }),
				},

				------------------------------------------------------------------
				-- CSS / SCSS / SASS / LESS
				------------------------------------------------------------------
				css = {
					augend.hexcolor.new({ case = "lower" }),
					augend.hexcolor.new({ case = "upper" }),
					-- numbers & colors are the main win here
				},

				------------------------------------------------------------------
				-- JSON
				------------------------------------------------------------------
				json = {
					augend.semver.alias.semver,
					bool,
				},

				------------------------------------------------------------------
				-- YAML
				------------------------------------------------------------------
				yaml = {
					bool,
					Bool,
					yes_no,
					on_off,
				},

				------------------------------------------------------------------
				-- PYTHON
				------------------------------------------------------------------
				python = {
					Bool, -- True ↔ False (Python style)
					bool, -- true ↔ false (still useful)
					and_or, -- and ↔ or
				},

				------------------------------------------------------------------
				-- LUA
				------------------------------------------------------------------
				lua = {
					and_or, -- and ↔ or
					bool,
				},

				------------------------------------------------------------------
				-- GO
				------------------------------------------------------------------
				go = {
					bool,
					-- Go uses true/false, no capitalised version
				},

				------------------------------------------------------------------
				-- RUST
				------------------------------------------------------------------
				rust = {
					bool,
					-- true/false only
				},

				------------------------------------------------------------------
				-- C / C++
				------------------------------------------------------------------
				c = {
					bool,
					-- true/false (C++) / often macros in C
				},

				------------------------------------------------------------------
				-- JAVA / KOTLIN
				------------------------------------------------------------------
				java = {
					bool,
					Bool, -- sometimes True/False in docs
				},

				------------------------------------------------------------------
				-- RUBY
				------------------------------------------------------------------
				ruby = {
					bool,
					Bool,
					and_or, -- and / or are valid
					yes_no,
				},

				------------------------------------------------------------------
				-- PHP
				------------------------------------------------------------------
				php = {
					bool,
				},

				------------------------------------------------------------------
				-- SHELL
				------------------------------------------------------------------
				shell = {
					bool,
					yes_no,
					on_off,
				},

				------------------------------------------------------------------
				-- MARKDOWN / ORG / NORG
				------------------------------------------------------------------
				markdown = {
					augend.misc.alias.markdown_header, -- # → ## → ### …
					bool,
					yes_no,
					on_off,
					-- checkbox style
					augend.constant.new({
						elements = { "[ ]", "[x]", "[X]" },
						word = false,
						cyclic = true,
					}),
				},

				------------------------------------------------------------------
				-- SQL
				------------------------------------------------------------------
				sql = {
					bool,
					-- true/false, and sometimes YES/NO
					yes_no,
				},
			},
		}
	end,

	config = function(_, opts)
		-- Make every language group also inherit the powerful default set
		for name, group in pairs(opts.groups) do
			if name ~= "default" then
				vim.list_extend(group, opts.groups.default)
			end
		end

		require("dial.config").augends:register_group(opts.groups)
		vim.g.dials_by_ft = opts.dials_by_ft
	end,
}
