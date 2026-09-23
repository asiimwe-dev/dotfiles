-- ~/.config/nvim/lua/plugins/refactoring.lua
return {
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup()
		end,
		keys = {
			-- In Visual Mode, press <leader>r to pick an extraction action
			{
				"<leader>r",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v",
				desc = "Refactor Selection",
			},
		},
	},
}
