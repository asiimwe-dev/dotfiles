-- ~/.config/nvim/lua/plugins/ui.lua
-- General editor UI/UX plugins. LSP-specific settings (including inlay
-- hints, which used to live here) now live in plugins/lsp.lua alongside
-- the rest of the LSP config.
return {
	-- Indent guides (smooth scroll left disabled — see notes below if you
	-- want it back)
	{
		"folke/snacks.nvim",
		opts = {
			scroll = { enabled = false },
			indent = { enabled = true },
		},
	},

	-- Adjust notification popup duration
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 10000, -- 10 seconds
			render = "compact",
		},
	},

	-- Noice.nvim: floating LSP hover/signature popups, command line UI, etc.
	{
		"folke/noice.nvim",
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.styled_parts"] = true,
				},
				hover = {
					enabled = true,
					silent = true,
				},
				signature = {
					enabled = true,
					auto_open = {
						enabled = true,
						trigger = true,
						delay = 100,
					},
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

	-- Rounded borders on LazyVim's input/select popups
	-- NOTE: `select.backend` used to list "telescope" first; telescope.nvim
	-- was removed from this config, superseded by Snacks.picker (LazyVim's
	-- own default — see plugins/picker.lua), so this just uses the builtin
	-- backend directly. Snacks.nvim doesn't ship its own vim.ui.select
	-- replacement, so there's no competing backend to reconcile here.
	{
		"stevearc/dressing.nvim",
		opts = {
			input = {
				border = "rounded",
			},
			select = {
				backend = { "builtin" },
				builtin = {
					border = "rounded",
				},
			},
		},
	},
}
