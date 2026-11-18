-- ~/.config/nvim/lua/plugins/picker.lua
-- Snacks.picker tweaks (picker is enabled via the snacks_picker extra).
--
-- The old `;f ;r ;e ;j ;m` and `\\` keys were removed: `;` is Vim's
-- "repeat f/t" motion, and defining `;x` mappings made every plain `;` wait
-- out timeoutlen. LazyVim's own keys cover the same ground:
--   <leader>ff / <leader><space>  files        <leader>sg  live grep
--   <leader>sd                    diagnostics  <leader>sj  jumps
--   <leader>sm                    marks        <leader>,   buffers
return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
				-- filename first, truncated path after
				formatters = { file = { filename_first = true } },
			})

			-- Enlarge the two layout presets Snacks auto-switches between
			-- (default = wide, vertical = narrow). Done here rather than in
			-- a `config` override so LazyVim's own snacks setup stays intact.
			local ok, layouts = pcall(require, "snacks.picker.config.layouts")
			if ok then
				layouts.default = vim.tbl_deep_extend("force", layouts.default, {
					layout = { width = 0.95, height = 0.9 },
				})
				layouts.vertical = vim.tbl_deep_extend("force", layouts.vertical, {
					layout = { width = 0.9, height = 0.9 },
				})
			end
		end,
		keys = {
			-- git workflows live in lazygit: drop the snacks git pickers
			{ "<leader>gd", false }, -- Git Diff (hunks)
			{ "<leader>gD", false }, -- Git Diff (origin)
			{ "<leader>gs", false }, -- Git Status
			{ "<leader>gS", false }, -- Git Stash
			{ "<leader>fg", false }, -- Find Files (git-files)
			-- Snacks notifier is disabled (ui.lua); history lives in noice
			{ "<leader>n", "<cmd>Noice history<cr>", desc = "Notification History" },
		},
	},
}
