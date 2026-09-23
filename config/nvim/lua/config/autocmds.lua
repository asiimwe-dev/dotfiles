-- ~/.config/nvim/lua/config/autocmds.lua
-- All autocmds live here. `vim.o`/`vim.opt` settings belong in options.lua,
-- not here — keeps the two files from blurring together.

local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- Auto-restore the last session when nvim is launched without file arguments.
-- None is created; the dashboard still appears when no session exists.
vim.api.nvim_create_autocmd("VimEnter", {
	group = augroup,
	nested = true,
	callback = function()
		if #vim.fn.argv() == 0 then
			require("persistence").load({ last = true })
		end
	end,
})

-- Disable diagnostic warnings specifically for markdown buffers
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = "markdown",
	callback = function(ev)
		vim.diagnostic.enable(false, { bufnr = ev.buf })
	end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

-- Toggle Python diagnostics on demand.
-- basedpyright is tuned down in plugins/lsp.lua already (see that file for
-- the noise-reduction settings), but sometimes you just want silence while
-- prototyping. <leader>tp flips diagnostics on/off for the current buffer.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = "python",
	callback = function(ev)
		vim.keymap.set("n", "<leader>tp", function()
			local enabled = vim.diagnostic.is_enabled({ bufnr = ev.buf })
			vim.diagnostic.enable(not enabled, { bufnr = ev.buf })
			vim.notify("Python diagnostics " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
		end, { buffer = ev.buf, desc = "Toggle Python Diagnostics" })
	end,
})
