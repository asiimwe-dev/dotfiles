-- ~/.config/nvim/lua/plugins/which-key.lua
return {
	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				{ "<leader>F", group = "flutter" },
				{ "<leader>a", group = "ai" },
				{ "<leader>h", group = "history" },
				{ "<leader>j", group = "java" },
				{ "<leader>P", group = "web-preview" },
				{ "<leader>M", group = "Molten/Notebooks" },
			},
		},
	},
}
