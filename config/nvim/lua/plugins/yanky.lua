return {
	"gbprod/yanky.nvim",
	opts = {
		ring = { history_length = 100, storage = "shada" },
		highlight = { timer = 150 },
	},
	keys = {
		-- Search paste history visually
		{ "<leader>p", "<cmd>YankyRingHistory<cr>", desc = "Open Yank History" },
		{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
		{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
		{ "<c-p>", "<Plug>(YankyCycleForward)", desc = "Cycle Forward in Yank Ring" },
		{ "<c-n>", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward in Yank Ring" },
	},
}
