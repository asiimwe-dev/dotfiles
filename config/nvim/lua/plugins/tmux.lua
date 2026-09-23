-- ~/.config/nvim/lua/plugins/tmux.lua
return {
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate Left (Tmux/Nvim)" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate Down (Tmux/Nvim)" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate Up (Tmux/Nvim)" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate Right (Tmux/Nvim)" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate Previous (Tmux/Nvim)" },
		},
	},
}
