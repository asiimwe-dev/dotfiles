-- ~/.config/nvim/lua/plugins/escape.lua
-- jk / jj to leave insert mode WITHOUT a timeoutlen delay on every `j`
-- (a plain `inoremap jk <Esc>` makes Neovim wait before inserting any "j").
return {
	{
		"max397574/better-escape.nvim",
		event = "InsertCharPre",
		opts = function()
			return {
				timeout = vim.o.timeoutlen,
				default_mappings = false,
				mappings = {
					i = { j = { k = "<Esc>", j = "<Esc>" } },
				},
			}
		end,
	},
}
