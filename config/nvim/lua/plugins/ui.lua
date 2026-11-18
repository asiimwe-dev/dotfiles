-- ~/.config/nvim/lua/plugins/ui.lua
-- General editor UI/UX plugins. LSP-specific settings (including inlay
-- hints, which used to live here) now live in plugins/lsp.lua alongside
-- the rest of the LSP config.
local P = require("config.palette")

return {
	-- Snacks: smooth-scroll off (it fights the <C-d>zz mappings). The Snacks
	-- notifier is off too: nvim-notify + noice own notifications, and having
	-- both made it unpredictable which one vim.notify ended up pointing at.
	-- (Indent guides are a LazyVim default and need no entry here.)
	{
		"folke/snacks.nvim",
		opts = {
			scroll = { enabled = false },
			notifier = { enabled = false },
			indent = { animate = { enabled = false } }, -- static guides, no scope animation
		},
	},

	-- Beautiful floating notification cards
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 2500,
			stages = "fade_in_slide_out",
			render = "compact", -- clean, less padding
			max_width = 58,
			minimum_width = 24,
			top_down = true,
			background_colour = P.bg_base, -- required for transparent fade
			fps = 30,
			icons = {
				ERROR = "󰅚 ",
				WARN = "󰀪 ",
				INFO = "󰋽 ",
				DEBUG = " ",
				TRACE = "✎ ",
			},
		},
	},

	-- Noice.nvim: floating LSP hover/signature popups, command line UI, etc.
	{
		"folke/noice.nvim",
		opts = {
			lsp = {
				-- (lsp.override removed: LazyVim already sets the correct keys;
				--  the old "vim.lsp.util.styled_parts" entry was not a real hook.)
				hover = {
					enabled = true,
					silent = true,
				},
				signature = {
					enabled = true,
					-- No popup while typing; press <C-k> in insert mode when you want it.
					auto_open = { enabled = false },
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = true,
				lsp_doc_border = true,
			},
		},
	},

	-- dressing.nvim is superseded by Snacks.input / Snacks.picker's ui_select
	-- (both enabled by LazyVim); keeping it made the winner load-order dependent.
	{ "stevearc/dressing.nvim", enabled = false },

	-- Reference highlights: stay out of the way. Don't paint the token under
	-- the cursor and don't bother when the symbol occurs once. Combined with
	-- vim.g.Illuminate_delay (config/options.lua) this stops the "hover
	-- underline" twitch on every cursor move.
	{
		"RRethy/vim-illuminate",
		opts = {
			under_cursor = false,
			min_count_to_highlight = 2,
		},
	},

	-- Sticky scope header: cap it at two lines so it never eats the screen.
	{ "nvim-treesitter/nvim-treesitter-context", opts = { max_lines = 2 } },

	-- Buffer bar is permanently hidden (showtabline = 0), so don't load it.
	{ "akinsho/bufferline.nvim", enabled = false },
}
