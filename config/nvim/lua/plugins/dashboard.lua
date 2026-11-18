-- ~/.config/nvim/lua/plugins/dashboard.lua
-- Snacks dashboard, tuned for solarized-osaka + kitty.
--
-- Personal contact details were removed from the header on purpose: this
-- folder is a git repo and dotfiles tend to get published.

local P = require("config.palette")

-- Pad every line to the same display width so per-line centering can't shear the art.
local function pad_block(s)
	local lines = vim.split(s, "\n", { trimempty = true })
	local w = 0
	for _, l in ipairs(lines) do
		w = math.max(w, vim.fn.strdisplaywidth(l))
	end
	for i, l in ipairs(lines) do
		lines[i] = l .. string.rep(" ", w - vim.fn.strdisplaywidth(l))
	end
	return table.concat(lines, "\n")
end

-- Tagline lives in its own section below, so a wide glyph can't shift the art.
local header = pad_block([[
 ██████╗  ██╗  ██╗        ██████╗  ███████╗  ██████╗  ████████╗
██╔════╝  ██║  ██║        ██╔══██╗ ██╔════╝  ██╔══██╗ ╚══██╔══╝
██║  ███╗ ██║  ██║        ██████╔╝ █████╗    ██████╔╝    ██║
██║   ██║ ██║  ██║        ██╔══██╗ ██╔══╝    ██╔══██╗    ██║
╚██████╔╝ ██║  ███████╗   ██████╔╝ ███████╗  ██║  ██║    ██║
 ╚═════╝  ╚═╝  ╚══════╝   ╚═════╝  ╚══════╝  ╚═╝  ╚═╝    ╚═╝
]])

local function set_hl()
	local hl = vim.api.nvim_set_hl
	hl(0, "SnacksDashboardHeader", { fg = P.sky, bold = true })
	hl(0, "SnacksDashboardFooter", { fg = P.teal, italic = true })
	hl(0, "SnacksDashboardTitle", { fg = P.yellow, bold = true })
	hl(0, "SnacksDashboardIcon", { fg = P.sky })
	hl(0, "SnacksDashboardKey", { fg = P.pink, bold = true })
	hl(0, "SnacksDashboardDesc", { fg = P.slate })
	hl(0, "SnacksDashboardFile", { fg = P.slate })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("DashboardHighlights", { clear = true }),
	callback = set_hl,
})
set_hl()

return {
	"folke/snacks.nvim",
	opts = {
		dashboard = {
			enabled = true,
			width = 72, -- must be >= the art's display width
			preset = {
				header = header,
				keys = {
					{
						icon = "󰍉 ",
						key = "f",
						desc = "Find File",
						action = function()
							Snacks.picker.files()
						end,
					},
					{ icon = "󰈔 ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = "󰉋 ",
						key = "p",
						desc = "Projects",
						action = function()
							Snacks.picker.projects()
						end,
					},
					{
						icon = "󰈞 ",
						key = "g",
						desc = "Find Text",
						action = function()
							Snacks.picker.grep()
						end,
					},
					{
						icon = "󱁤 ",
						key = "c",
						desc = "Config",
						action = function()
							LazyVim.pick.config_files()()
						end,
					},
					{ icon = "󰦛 ", key = "s", desc = "Restore Session", section = "session" },
					{ icon = "󰈆 ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = {
				{ section = "header", padding = 0 },
				{
					align = "center",
					padding = 1,
					text = { { "󱐋 asiimwe-dev 󱐋", hl = "SnacksDashboardFooter" } },
				},
				{ section = "keys", gap = 0, padding = 1 },
				{
					icon = " ",
					title = "Recent Files",
					section = "recent_files",
					indent = 2,
					padding = 1,
					limit = 5,
					enabled = function()
						return vim.o.lines >= 36
					end,
				},
				{
					icon = "󰏗 ",
					title = "Projects",
					section = "projects",
					indent = 2,
					padding = 1,
					limit = 4,
					enabled = function()
						return vim.o.lines >= 44
					end,
				},
				{ section = "startup" },
				{
					align = "center",
					padding = 0,
					text = { { "“I am still learning.” — Michelangelo", hl = "SnacksDashboardFooter" } },
				},
			},
		},
	},
}
