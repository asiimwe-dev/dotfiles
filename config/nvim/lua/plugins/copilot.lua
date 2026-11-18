-- ~/.config/nvim/lua/plugins/copilot.lua
-- Inline ghost-text Copilot with a privacy guard (see config/ai.lua).
-- The `ai.copilot` LazyVim extra is intentionally NOT enabled: it would add
-- Copilot to the blink.cmp menu as well, duplicating every suggestion.
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		-- NOTE: no `build = ":Copilot auth"` — it is interactive and hangs
		-- headless `:Lazy sync`. Run `:Copilot auth` once by hand.
		opts = {
			panel = { enabled = false },
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = false, -- unified keymaps live in config/keymaps.lua
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = false,
				},
			},
			filetypes = {
				yaml = false,
				markdown = false,
				help = false,
				gitcommit = false,
				gitrebase = false,
				["."] = false,
			},
			should_attach = function(bufnr, _)
				return require("config.ai").should_attach(bufnr)
			end,
		},
		config = function(_, opts)
			require("copilot").setup(opts)
			-- Start disabled; <leader>at turns it on.
			pcall(function()
				vim.cmd("Copilot disable")
			end)
		end,
	},
}
