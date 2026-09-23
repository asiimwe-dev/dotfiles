-- ~/.config/nvim/lua/plugins/dashboard.lua
-- Professional 'hyper' theme setup tailored for solarized-osaka (glassy terminal tuned)
--
-- NOTE: this runs alongside Snacks' own dashboard module, which is
-- explicitly disabled below rather than removed as a dependency — Snacks
-- itself stays installed for its other roles in this config (indent
-- guides, terminal, lazygit shortcut, the picker). The "Production-Ready
-- Fix" block further down exists specifically because dashboard-nvim's
-- buffer filetype ("dashboard") collided with an entry already in
-- lualine's blacklist (originally there for Snacks' own dashboard). That
-- fix is correct as written; just documenting why it's needed at all.

local header_ascii = [[
 ██████╗  ██╗  ██╗        ██████╗  ███████╗  ██████╗  ████████╗
██╔════╝  ██║  ██║        ██╔══██╗ ██╔════╝  ██╔══██╗ ╚══██╔══╝
██║  ███╗ ██║  ██║        ██████╔╝ █████╗    ██████╔╝    ██║   
██║   ██║ ██║  ██║        ██╔══██╗ ██╔══╝    ██╔══██╗    ██║   
╚██████╔╝ ██║  ███████╗   ██████╔╝ ███████╗  ██║  ██║    ██║   
 ╚═════╝  ╚═╝  ╚══════╝   ╚═════╝  ╚══════╝  ╚═╝  ╚═╝    ╚═╝   
                        ⚡ yourname ⚡
           󰇮 your@email.com  •  󰏲 +000 000 000 000
]]

-- Note: replace the header above with your own name/username/contact info.

return {
	-- 1. Disable built-in Snacks dashboard to prevent screen collisions
	{
		"folke/snacks.nvim",
		opts = {
			dashboard = { enabled = false },
		},
	},

	-- 2. Configure nvimdev/dashboard-nvim with 'hyper' theme
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { { "nvim-tree/nvim-web-devicons" } },
		config = function()
			local augroup = vim.api.nvim_create_augroup("DashboardHighlights", { clear = true })

			-- Bulletproof highlights: Re-apply if the colorscheme reloads
			local function set_dashboard_highlights()
				vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#38bdf8", bold = true }) -- Electric Sky Blue
				vim.api.nvim_set_hl(0, "DashboardFooter", { fg = "#2dd4bf", italic = true }) -- Vibrant Mint Cyan
				vim.api.nvim_set_hl(0, "DashboardProject", { fg = "#fbbf24", bold = true }) -- Bright Amber Gold
				vim.api.nvim_set_hl(0, "DashboardProjectTitle", { fg = "#fbbf24", bold = true })
				vim.api.nvim_set_hl(0, "DashboardProjectTitleIcon", { fg = "#fbbf24" })
				vim.api.nvim_set_hl(0, "DashboardProjectIcon", { fg = "#38bdf8" })
				vim.api.nvim_set_hl(0, "DashboardMruTitle", { fg = "#2dd4bf", bold = true })
				vim.api.nvim_set_hl(0, "DashboardMruIcon", { fg = "#2dd4bf" })
				vim.api.nvim_set_hl(0, "DashboardFiles", { fg = "#94a3b8" })
				vim.api.nvim_set_hl(0, "DashboardShortCut", { fg = "#f472b6", bold = true })
			end

			-- Set them instantly on load
			set_dashboard_highlights()

			-- Hook them to survive colorscheme changes
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				pattern = "*",
				callback = set_dashboard_highlights,
			})

			require("dashboard").setup({
				theme = "hyper",

				-- TOP-LEVEL: Prevents dashboard-nvim from hiding UI elements.
				hide = {
					statusline = false,
					tabline = false,
					winbar = false,
				},

				config = {
					header = vim.split(header_ascii, "\n"),

					shortcut = {
						{
							icon = "󰍉 ",
							desc = "Find File",
							group = "Function",
							action = function()
								Snacks.picker.files()
							end,
							key = "f",
						},
						{
							icon = "󰈔 ",
							desc = "New File",
							group = "DiagnosticOk",
							action = "ene | startinsert",
							key = "n",
						},
						{
							icon = "󰉋 ",
							desc = "Projects",
							group = "Statement",
							action = function()
								-- Prefer Snacks, fall back to LazyVim pick if needed
								if Snacks and Snacks.picker and Snacks.picker.projects then
									Snacks.picker.projects()
								else
									LazyVim.pick("projects")()
								end
							end,
							key = "p",
						},
						{
							icon = "󰈞 ",
							desc = "Find Text",
							group = "String",
							action = function()
								Snacks.picker.grep()
							end,
							key = "g",
						},
						{
							icon = " ",
							desc = "Config",
							group = "Special",
							action = function()
								LazyVim.pick.config_files()()
							end,
							key = "c",
						},
						{
							icon = "󰦛 ",
							desc = "Restore Session",
							group = "Identifier",
							action = function()
								require("persistence").load()
							end,
							key = "s",
						},
						{
							icon = "󰏖 ",
							desc = "Lazy Extras",
							group = "@type",
							action = "LazyExtras",
							key = "x",
						},
						{
							icon = "󰒲 ",
							desc = "Lazy",
							group = "@label",
							action = "Lazy",
							key = "l",
						},
						{
							icon = "󰈆 ",
							desc = "Quit",
							group = "DiagnosticError",
							action = "qa",
							key = "q",
						},
					},

					-- Live Project Directory Panel
					project = {
						enable = true,
						limit = 4,
						icon = "󰏗 ",
						label = " Active Projects",
						action = function(path)
							if Snacks and Snacks.picker and Snacks.picker.files then
								Snacks.picker.files({ cwd = path })
							else
								LazyVim.pick("files", { cwd = path })()
							end
						end,
					},

					-- Most Recently Used files
					mru = {
						enable = true,
						limit = 6,
						icon = " ",
						label = " Recent Files",
						cwd_only = false,
					},

					-- Custom Quote Footer
					footer = {
						"",
						"“I am still learning.” — Michelangelo",
					},
				},
			})
		end,
	},

	-- 3. Production-Ready Fix: Tell Lualine it is allowed to draw on the dashboard
	{
		"nvim-lualine/lualine.nvim",
		optional = true,
		opts = function(_, opts)
			opts.options = opts.options or {}
			opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}

			-- Safely filter out "dashboard" from LazyVim's default Lualine blacklist
			if opts.options.disabled_filetypes.statusline then
				opts.options.disabled_filetypes.statusline = vim.tbl_filter(function(ft)
					return ft ~= "dashboard"
				end, opts.options.disabled_filetypes.statusline)
			end
		end,
	},
}
