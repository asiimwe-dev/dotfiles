-- ~/.config/nvim/lua/plugins/picker.lua
-- Finder keymaps on Snacks.picker (LazyVim's default picker, active via the
-- snacks_picker extra). This file adds our own keymaps and layout tuning on
-- top of it. "folke/snacks.nvim" itself needs no registration here — it's
-- already active through LazyVim core + the extra (see plugins/ui.lua for
-- its other roles).
--
-- Key deletions below remove the snacks *git* pickers that come from the
-- snacks_picker extra: LazyVim's git workflows have been moved to lazygit
-- (see config/keymaps.lua and plugins/git.lua), so gd/gD/gs/gS/fg no longer
-- belong in the finder.
return {
	{
		"folke/snacks.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			picker = {
				-- Display: filename shown before the truncated path, matching
				-- fzf-lua's old `files.formatter = "path.filename_first"`.
				formatters = {
					file = { filename_first = true },
				},
				-- Layout sizing is done in config() below, not here.
			},
		},
		config = function(_, opts)
			-- Snacks' base config auto-switches between the "default"
			-- preset (horizontal split, preview on the right) and "vertical"
			-- (stacked, preview at the bottom) based on window width. We keep
			-- that auto-switching but enlarge both named presets it picks
			-- between, in place — same technique as "make my preferred
			-- preset bigger" elsewhere.
			local layouts = require("snacks.picker.config.layouts")
			layouts.default = vim.tbl_deep_extend("force", layouts.default, {
				layout = { width = 0.95, height = 0.9 },
			})
			layouts.vertical = vim.tbl_deep_extend("force", layouts.vertical, {
				layout = { width = 0.9, height = 0.9 },
			})

			require("snacks").setup(opts)
		end,
		keys = {
			-- git workflows live in lazygit now: drop the snacks git pickers
			{ "<leader>gd", false }, -- Git Diff (hunks)
			{ "<leader>gD", false }, -- Git Diff (origin)
			{ "<leader>gs", false }, -- Git Status
			{ "<leader>gS", false }, -- Git Stash
			{ "<leader>fg", false }, -- Find Files (git-files)
			{
				";f",
				function()
					Snacks.picker.files({ hidden = true })
				end,
				desc = "Find Files",
			},
			{
				";r",
				function()
					Snacks.picker.grep()
				end,
				desc = "Live Grep",
			},
			{
				";e",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "Diagnostics (workspace)",
			},
			{
				";j",
				function()
					Snacks.picker.jumps()
				end,
				desc = "Jump List",
			},
			{
				";m",
				function()
					Snacks.picker.marks()
				end,
				desc = "Marks",
			},
			{
				"\\\\",
				function()
					Snacks.picker.buffers()
				end,
				desc = "Open Buffers",
			},
		},
	},
}