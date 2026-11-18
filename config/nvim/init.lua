-- ~/.config/nvim/init.lua
-- Entry point. Everything lives in lua/config so it can be required piecemeal.
if vim.fn.has("nvim-0.11") == 0 then
	vim.api.nvim_echo({
		{ "This config requires Neovim >= 0.11 (running " .. tostring(vim.version()) .. ").\n", "ErrorMsg" },
	}, true, {})
	return
end

require("config.lazy")
