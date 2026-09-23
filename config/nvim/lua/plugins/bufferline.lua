return {
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		},
		config = function()
			local colors = require("solarized-osaka.colors").setup()

			local active_bg = colors.yellow500
			local active_fg = colors.base04
			local inactive_bg = "NONE"
			local inactive_fg = colors.base01
			local modified_color = colors.orange500
			local error_color = colors.red500
			local warning_color = colors.yellow500
			local info_color = colors.blue500
			local hint_color = colors.cyan500

			require("bufferline").setup({
				options = {
					mode = "buffers",
					style_preset = require("bufferline").style_preset.minimal,
					themable = true,

					-- Floating capsules
					separator_style = { "", "" },
					always_show_bufferline = true,
					show_buffer_close_icons = false,
					show_close_icon = false,
					show_tab_indicators = true,
					color_icons = true,
					show_buffer_icons = true,
					show_duplicate_prefix = true,

					numbers = "ordinal",

					indicator = {
						style = "none",
						icon = "▎",
					},

					hover = {
						enabled = true,
						delay = 150,
						reveal = { "close" },
					},

					max_name_length = 22,
					max_prefix_length = 15,
					truncate_names = true,
					tab_size = 18,
					enforce_regular_tabs = false,

					diagnostics = "nvim_lsp",
					diagnostics_update_on_event = true,
					diagnostics_indicator = function(count, level, diagnostics_dict, context)
						if context.buffer:current() then
							return ""
						end
						local icons = {
							error = "󰅚 ",
							warning = "󰀪 ",
							info = "󰋽 ",
							hint = "󰌶 ",
						}
						return " " .. (icons[level] or "󰀦 ") .. count
					end,

					offsets = {
						{
							filetype = "neo-tree",
							text = "󰙅  Explorer",
							text_align = "left",
							highlight = "Directory",
							separator = true,
						},
						{
							filetype = "NvimTree",
							text = "󰙅  Explorer",
							text_align = "left",
							highlight = "Directory",
							separator = true,
						},
					},

					name_formatter = function(buf)
						return " " .. buf.name .. " "
					end,

					modified_icon = "●",
					sort_by = "insert_after_current",
				},

				highlights = {
					fill = { bg = "NONE" },

					-- Inactive
					background = { fg = inactive_fg, bg = inactive_bg },
					buffer_visible = { fg = inactive_fg, bg = inactive_bg },

					-- Active (Osaka yellow pill)
					buffer_selected = {
						fg = active_fg,
						bg = active_bg,
						bold = true,
						italic = false,
					},

					-- Numbers
					numbers = { fg = inactive_fg, bg = inactive_bg },
					numbers_visible = { fg = inactive_fg, bg = inactive_bg },
					numbers_selected = { fg = active_fg, bg = active_bg, bold = true },

					-- Indicator
					indicator_selected = { fg = active_bg, bg = active_bg },
					indicator_visible = { fg = inactive_bg, bg = inactive_bg },

					-- Diagnostics base
					diagnostic = { fg = inactive_fg, bg = inactive_bg },
					diagnostic_visible = { fg = inactive_fg, bg = inactive_bg },
					diagnostic_selected = { fg = active_fg, bg = active_bg, bold = true },

					-- Error
					error = { fg = error_color, bg = inactive_bg },
					error_visible = { fg = error_color, bg = inactive_bg },
					error_selected = { fg = active_fg, bg = active_bg, bold = true },
					error_diagnostic = { fg = error_color, bg = inactive_bg },
					error_diagnostic_visible = { fg = error_color, bg = inactive_bg },
					error_diagnostic_selected = { fg = active_fg, bg = active_bg },

					-- Warning
					warning = { fg = warning_color, bg = inactive_bg },
					warning_visible = { fg = warning_color, bg = inactive_bg },
					warning_selected = { fg = active_fg, bg = active_bg, bold = true },
					warning_diagnostic = { fg = warning_color, bg = inactive_bg },
					warning_diagnostic_visible = { fg = warning_color, bg = inactive_bg },
					warning_diagnostic_selected = { fg = active_fg, bg = active_bg },

					-- Info / Hint
					info = { fg = info_color, bg = inactive_bg },
					info_visible = { fg = info_color, bg = inactive_bg },
					info_selected = { fg = active_fg, bg = active_bg },
					info_diagnostic = { fg = info_color, bg = inactive_bg },
					info_diagnostic_selected = { fg = active_fg, bg = active_bg },

					hint = { fg = hint_color, bg = inactive_bg },
					hint_visible = { fg = hint_color, bg = inactive_bg },
					hint_selected = { fg = active_fg, bg = active_bg },
					hint_diagnostic = { fg = hint_color, bg = inactive_bg },
					hint_diagnostic_selected = { fg = active_fg, bg = active_bg },

					-- Modified
					modified = { fg = modified_color, bg = inactive_bg },
					modified_visible = { fg = modified_color, bg = inactive_bg },
					modified_selected = { fg = active_fg, bg = active_bg },

					-- Transparent separators → floating capsules
					separator = { fg = "NONE", bg = "NONE" },
					separator_visible = { fg = "NONE", bg = "NONE" },
					separator_selected = { fg = "NONE", bg = "NONE" },

					-- Close button
					close_button = { fg = inactive_fg, bg = inactive_bg },
					close_button_visible = { fg = inactive_fg, bg = inactive_bg },
					close_button_selected = { fg = active_fg, bg = active_bg },

					-- Duplicate
					duplicate = { fg = inactive_fg, bg = inactive_bg, italic = true },
					duplicate_selected = { fg = active_fg, bg = active_bg, italic = true },
					duplicate_visible = { fg = inactive_fg, bg = inactive_bg, italic = true },
				},
			})

			-- Kill the residual teal that comes from TabLine / TabLineFill
			-- (Neovim combines these with the bufferline highlights)
			local function clear_tabline_bg()
				vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE", nocombine = true })
				vim.api.nvim_set_hl(0, "TabLine", { fg = inactive_fg, bg = "NONE", nocombine = true })
				-- Keep the active pill looking correct
				vim.api.nvim_set_hl(0, "TabLineSel", {
					fg = active_fg,
					bg = active_bg,
					bold = true,
					nocombine = true,
				})
			end

			clear_tabline_bg()

			-- Re-apply after any colorscheme change so the theme cannot re-introduce the teal
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("BufferlineTransparent", { clear = true }),
				callback = clear_tabline_bg,
			})
		end,
	},
}
