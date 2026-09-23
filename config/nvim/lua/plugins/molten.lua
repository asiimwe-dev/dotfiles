-- ~/.config/nvim/lua/plugins/molten.lua
-- Jupyter notebook execution, with real inline output — rendered via
-- Kitty's graphics protocol (see plugins/image.lua), not a browser tab.
-- Part of a three-plugin stack, each with one job:
--   molten.lua    — runs code against a real Jupyter kernel, shows output
--   image.lua     — renders images/plots inline (molten's dependency)
--   jupytext.lua  — lets .ipynb files be edited as clean, cell-marked .py
--                   instead of raw JSON
--
-- REQUIRES SYSTEM SETUP THIS FILE CANNOT DO FOR YOU — see NOTEBOOKS.md.
-- In short: a dedicated Python venv with `pynvim` + `jupyter_client`
-- installed and pointed to by `vim.g.python3_host_prog` (config/options.lua),
-- ImageMagick installed system-wide, and `python -m ipykernel install`
-- run inside whatever venv you actually want to run notebook code in.
--
-- Molten is a "remote plugin" (its Python side registers with Neovim's
-- RPC). That requires `:UpdateRemotePlugins` to have been run — a classic
-- "installed but silently does nothing" trap if forgotten. `build` below
-- runs it automatically on install/update, but Neovim still needs a
-- restart after the very first install for the generated manifest to load.
-- New, valid, empty notebooks. Per molten-nvim's own Notebook-Setup.md:
-- jupytext needs real kernelspec metadata to know how to parse a file, so
-- an empty buffer named foo.ipynb isn't valid — this writes the minimal
-- correct nbformat v4 JSON structure and opens it.
vim.api.nvim_create_user_command("PyNotebookNew", function(cmd_opts)
	local path = cmd_opts.args ~= "" and cmd_opts.args or vim.fn.input("New notebook path: ", "notebook.ipynb")
	if path == "" then
		return
	end
	if not path:match("%.ipynb$") then
		path = path .. ".ipynb"
	end
	if vim.fn.filereadable(path) == 1 then
		vim.notify("File already exists: " .. path, vim.log.levels.ERROR)
		return
	end

	local template = [[{
 "cells": [],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": { "name": "python", "version": "3" }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
]]
	local f = io.open(path, "w")
	if not f then
		vim.notify("Could not create " .. path, vim.log.levels.ERROR)
		return
	end
	f:write(template)
	f:close()
	vim.cmd.edit(vim.fn.fnameescape(path))
end, {
	nargs = "?",
	desc = "Create a new, valid, empty Jupyter notebook and open it",
})

return {
	{
		"benlubas/molten-nvim",
		version = "^1.0.0", -- pin to the 1.x line; the plugin follows semver
		build = ":UpdateRemotePlugins",
		ft = { "python", "ipynb" },
		init = function()
			-- Isolated host Python for Neovim's remote-plugin provider —
			-- deliberately NOT your project venv. This keeps pynvim /
			-- jupyter_client (Molten's own runtime deps) separate from
			-- whatever packages a given data-analysis project needs, so
			-- switching projects/venvs can never break Molten itself.
			-- Doesn't exist until you create it — see NOTEBOOKS.md.
			vim.g.python3_host_prog = vim.fn.stdpath("data") .. "/molten-venv/bin/python3"

			-- Set *before* the plugin loads — Molten is a remote plugin and
			-- caches its config at initialization (see MoltenUpdateOption in
			-- the README for the one exception: changing values at runtime).
			vim.g.molten_image_provider = "image.nvim"
			vim.g.molten_output_win_max_height = 20
			vim.g.molten_wrap_output = true
			-- Output shown as persistent virtual text below the cell, not
			-- just in a floating window that closes when you leave — the
			-- floating window auto-popup is turned off below since virt
			-- text already keeps results visible; flip `auto_open_output`
			-- back to true if you'd rather have both.
			vim.g.molten_virt_text_output = true
			vim.g.molten_virt_lines_off_by_1 = true
			vim.g.molten_auto_open_output = false
			vim.g.molten_use_border_highlights = true
			vim.g.molten_save_path = vim.fn.stdpath("data") .. "/molten"
		end,
		keys = {
			-- FIX (before it was ever written): the plugin's own README
			-- suggests <localleader>-prefixed keymaps. In this config,
			-- maplocalleader is a single backslash (config/options.lua) —
			-- and the Snacks buffer picker is already bound to a *double*
			-- backslash ("\\\\", see plugins/picker.lua). Any
			-- <localleader>-prefixed key would force Neovim to wait out
			-- `timeoutlen` on every press of that buffer-picker binding, to
			-- see whether a second backslash was coming — the exact same
			-- class of bug already found and fixed twice in this config
			-- (flash.nvim vs the "s" window keys, and flash.nvim vs
			-- <leader><space>). Using <leader>M instead sidesteps it
			-- entirely; nothing else in this config claims that prefix.
			{ "<leader>Mi", "<cmd>MoltenInit<cr>", desc = "Initialize Kernel" },
			{ "<leader>MI", "<cmd>MoltenInfo<cr>", desc = "Molten Info / Status" },
			{
				"<leader>Me",
				"<cmd>MoltenEvaluateOperator<cr>",
				desc = "Evaluate Operator (motion)",
			},
			{ "<leader>Ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Evaluate Line" },
			{ "<leader>Mr", "<cmd>MoltenReevaluateCell<cr>", desc = "Re-evaluate Cell" },
			{
				-- The leading <C-u> clears any range Vim auto-inserts when
				-- entering command mode from visual mode, and the trailing
				-- `gv` restores the visual selection afterward — both
				-- required exactly as documented; MoltenEvaluateVisual
				-- explicitly cannot be called with a range.
				"<leader>Me",
				"<cmd><C-u>MoltenEvaluateVisual<cr>gv",
				mode = "v",
				desc = "Evaluate Visual Selection",
			},
			{ "<leader>Md", "<cmd>MoltenDelete<cr>", desc = "Delete Cell" },
			{ "<leader>Mh", "<cmd>MoltenHideOutput<cr>", desc = "Hide Output" },
			{
				-- must be called with `noautocmd`, exactly as documented, or
				-- window-entering autocmds elsewhere in this config (e.g.
				-- incline.nvim's per-window render) can interfere with it.
				"<leader>Mo",
				"<cmd>noautocmd MoltenEnterOutput<cr>",
				desc = "Enter Output Window",
			},
			{ "<leader>Mx", "<cmd>MoltenInterrupt<cr>", desc = "Interrupt Kernel" },
			{ "<leader>MR", "<cmd>MoltenRestart<cr>", desc = "Restart Kernel" },
			{ "<leader>Mn", "<cmd>MoltenNext<cr>", desc = "Next Cell" },
			{ "<leader>Mp", "<cmd>MoltenPrev<cr>", desc = "Prev Cell" },
			{ "<leader>MN", "<cmd>PyNotebookNew<cr>", desc = "New Notebook" },
		},
	},
}
