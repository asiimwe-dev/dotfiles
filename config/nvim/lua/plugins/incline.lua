return {
	{
		"b0o/incline.nvim",
		event = { "BufReadPost", "BufNewFile" },
		priority = 1200,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			local helpers = require("incline.helpers")
			local devicons = require("nvim-web-devicons")

			-- Shared palette (matches your lualine)
			local bg_base = "#02151e"
			local bg_alt = "#052630"
			local teal = "#2dd4bf"
			local yellow = "#fbbf24"
			local muted = "#586e75"
			local sky = "#38bdf8"

			return {
				window = {
					padding = 0,
					-- vertical = 1 creates a 1-line gap from the top of the Neovim pane,
					-- floating Incline cleanly inside the buffer area away from tmux
					margin = { horizontal = 2, vertical = 1 },
					placement = { vertical = "top", horizontal = "right" },
					winhighlight = {
						active = { Normal = "None" },
						inactive = { Normal = "None" },
					},
				},
				render = function(props)
					if not vim.api.nvim_buf_is_valid(props.buf) then
						return {}
					end

					local bufname = vim.api.nvim_buf_get_name(props.buf)
					local filename = vim.fn.fnamemodify(bufname, ":t")
					if filename == "" then
						filename = "[No Name]"
					end

					local ft_icon, ft_color = devicons.get_icon_color(filename)
					local modified = vim.bo[props.buf].modified
					local readonly = vim.bo[props.buf].readonly

					-- Active vs inactive treatment
					local is_active = props.focused
					local bg = is_active and bg_alt or bg_base
					local fg = is_active and teal or muted
					local icon_bg = ft_color or (is_active and sky or muted)

					return {
						-- Left rounded cap
						{ "", guifg = icon_bg },

						-- Filetype icon badge
						ft_icon and {
							" " .. ft_icon .. " ",
							guibg = icon_bg,
							guifg = helpers.contrast_color(icon_bg),
						} or "",

						-- Filename
						{
							" " .. filename,
							gui = modified and "bold,italic" or "bold",
							guifg = fg,
							guibg = bg,
						},

						-- Modified indicator
						modified and {
							" [+]",
							guifg = yellow,
							guibg = bg,
							gui = "bold",
						} or "",

						-- Readonly indicator
						readonly and not modified and {
							" 󰌾",
							guifg = muted,
							guibg = bg,
						} or "",

						-- Trailing space + right cap
						{ " ", guibg = bg },
						{ "", guifg = bg },
					}
				end,
			}
		end,
	},
}
