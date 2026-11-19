-- ~/.config/nvim/lua/config/keymaps.lua

local map = vim.keymap.set

-- ─────────────────────────────────────────────────────────────────────────
-- AI controls (GitHub Copilot) — logic lives in config/ai.lua
local function ai(method, arg)
	return function()
		local ok, A = pcall(require, "config.ai")
		if ok and A[method] then
			A[method](arg)
		end
	end
end

map("n", "<leader>at", ai("toggle"), { desc = "AI Toggle Copilot" })
map("n", "<leader>aic", ai("enable"), { desc = "AI → Copilot On" })
map("n", "<leader>aio", ai("disable"), { desc = "AI → Copilot Off" })
map("n", "<leader>ais", ai("show_status"), { desc = "AI Status" })

map("i", "<M-l>", ai("accept", "full"), { desc = "AI Accept", silent = true })
map("i", "<M-w>", ai("accept", "word"), { desc = "AI Accept Word", silent = true })
map("i", "<M-a>", ai("accept", "line"), { desc = "AI Accept Line", silent = true })
map("i", "<C-]>", ai("dismiss"), { desc = "AI Dismiss", silent = true })

-- Scroll half-page and keep the cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down & Center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up & Center" })

-- Clear navigation history (<leader>hj = jump list, <leader>hm = marks,
-- <leader>hr = registers).
-- `:clearjumps` only clears the current window's jumplist, so clear them all.
map("n", "<leader>hj", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		vim.api.nvim_win_call(win, function()
			vim.cmd("clearjumps")
		end)
	end
	vim.notify("Jump list cleared in all windows", vim.log.levels.INFO)
end, { desc = "Clear Jump List (all windows)" })

-- Delete every mark. getmarklist() with no argument only returns GLOBAL
-- marks, so lowercase (buffer-local) marks have to be cleared per buffer.
map("n", "<leader>hm", function()
	vim.cmd("delmarks A-Z0-9")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("delmarks a-z")
			end)
		end
	end
	vim.notify("Marks cleared", vim.log.levels.INFO)
end, { desc = "Clear All Marks" })

-- Clear every writable register: unnamed, numbered 0-9, named a-z, the
-- small-delete "-" and the clipboard "*"/"+".
-- Vim rejects the read-only ones (% # : .), so they are simply not touched;
-- note that with a clipboard provider this also empties the system clipboard.
map("n", "<leader>hr", function()
	local regs = { '"', "-", "*", "+" }
	for i = 0, 9 do
		regs[#regs + 1] = tostring(i)
	end
	for c = ("a"):byte(), ("z"):byte() do
		regs[#regs + 1] = string.char(c)
	end
	for _, reg in ipairs(regs) do
		pcall(vim.fn.setreg, reg, "")
	end
	vim.notify("Registers cleared", vim.log.levels.INFO)
end, { desc = "Clear All Registers" })

-- Notifications come from nvim-notify + noice (the Snacks notifier is off), so
-- LazyVim's Snacks-based <leader>un is re-pointed. (<leader>n is in picker.lua.)
map("n", "<leader>un", function()
	local ok, notify = pcall(require, "notify")
	if ok then
		notify.dismiss({ silent = true, pending = true })
	else
		vim.notify("Notifier not available", vim.log.levels.WARN)
	end
end, { desc = "Dismiss All Notifications" })

-- Select all (kept off <C-a> so Vim's increment still works)
map("n", "<leader>aa", "gg<S-v>G", { desc = "Select All Text" })

-- Show diagnostic float at cursor (normal + insert)
map({ "n", "i" }, "<A-d>", function()
	vim.diagnostic.open_float()
end, { desc = "Line Diagnostics" })

-- Git: workflows go through lazygit rather than the snacks git pickers.
-- These three are kept explicitly so the snacks_picker extra cannot
-- re-bind them to its picker versions. Picker keys that are dropped live
-- in plugins/picker.lua.
map("n", "<leader>gl", function()
	Snacks.lazygit.log({ cwd = LazyVim.root.git() })
end, { desc = "Git Log (Lazygit)" })
map("n", "<leader>gL", function()
	Snacks.lazygit.log()
end, { desc = "Git Log (Lazygit, cwd)" })
map("n", "<leader>gf", function()
	if vim.api.nvim_buf_get_name(0) == "" then
		Snacks.lazygit.log()
	else
		Snacks.lazygit.log_file()
	end
end, { desc = "Git File Log (Lazygit)" })
-- Blame line is covered by gitsigns' <leader>ghb / <leader>ghB.
pcall(vim.keymap.del, "n", "<leader>gb")

-- Java automation (new file types + project runner).
-- Project scaffolding is handled by the standalone `jgen` CLI.
local function java(fn)
	return function()
		local ok, creator = pcall(require, "config.java_creator")
		if not ok then
			vim.notify("Failed to load config/java_creator: " .. tostring(creator), vim.log.levels.ERROR)
			return
		end
		creator[fn]()
	end
end

vim.api.nvim_create_user_command("JavaNew", java("new_java_type"), {
	desc = "Java: New Class / Interface / Enum / …",
})
vim.api.nvim_create_user_command("JavaRun", java("run_project"), {
	desc = "Java: Compile & run current project",
})
-- (:JavaNewFile was a duplicate of :JavaNew and was removed.)

map("n", "<leader>jn", "<cmd>JavaNew<cr>", { desc = "Java: New Class / Type" })
map("n", "<leader>jr", "<cmd>JavaRun<cr>", { desc = "Java: Run project" })
