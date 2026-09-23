-- ~/.config/nvim/lua/config/keymaps.lua

local map = vim.keymap.set

-- Enable Cowboy Discipline module safely (prevents crashing if file is missing)
local has_discipline, discipline = pcall(require, "config.discipline")
if has_discipline then
	discipline.cowboy()
end

-- ─────────────────────────────────────────────────────────────────────────
-- AI engine controls. The engines themselves (copilot.lua / neocodeium) are
-- configured in plugins/ai_completion.lua; these bindings moved here from a
-- redundant `plenary.nvim` host spec removed from that file. The module
-- exports itself as _G.AICompletion when lazy.nvim processes the spec —
-- always before these keymaps run, but the handlers stay defensive anyway.
-- All engines start OFF; enable with <leader>aic / <leader>ain.
local ai = function()
	return _G.AICompletion
end
map("n", "<leader>aic", function()
	local A = ai()
	if A then
		A.switch("copilot")
	end
end, { desc = "AI → Copilot" })
map("n", "<leader>ain", function()
	local A = ai()
	if A then
		A.switch("neocodeium")
	end
end, { desc = "AI → NeoCodeium" })
map("n", "<leader>aio", function()
	local A = ai()
	if A then
		A.switch("none")
	end
end, { desc = "AI → Off" })
map("n", "<leader>ait", function()
	local A = ai()
	if A then
		A.cycle()
	end
end, { desc = "AI Cycle" })
map("n", "<leader>ais", function()
	local A = ai()
	if A then
		A.show_status()
	end
end, { desc = "AI Status" })

-- Unified accept / dismiss keys (work with whichever engine is active)
map("i", "<M-l>", function()
	local A = _G.AICompletion
	if A then
		A.accept("full")
	end
end, { desc = "AI Accept", silent = true })
map("i", "<M-w>", function()
	local A = _G.AICompletion
	if A then
		A.accept("word")
	end
end, { desc = "AI Accept Word", silent = true })
map("i", "<M-a>", function()
	local A = _G.AICompletion
	if A then
		A.accept("line")
	end
end, { desc = "AI Accept Line", silent = true })
map("i", "<C-]>", function()
	local A = _G.AICompletion
	if A then
		A.dismiss()
	end
end, { desc = "AI Dismiss", silent = true })

-- Ensure engines are off after startup without force-loading lazy plugins.
-- Only engines already loaded are touched (see AI.ensure_off in
-- plugins/ai_completion.lua).
vim.defer_fn(function()
	local A = _G.AICompletion
	if A and A.ensure_off then
		A.ensure_off()
	end
end, 100)

-- Ergonomic Window Navigation & Splitting (borrowed from Devaslife)
-- NOTE: these all start with "s". LazyVim's default keymaps also bind bare
-- "s" to flash.nvim's jump. Neovim has to wait out `timeoutlen` on every "s"
-- press to see whether a longer sequence (ss, sv, sh...) is coming, which
-- made every flash jump feel laggy. Rather than give up these window keys
-- (which you use constantly), flash's own trigger was remapped instead —
-- see plugins/flash.lua. Both now fire instantly with no conflict.
map("n", "ss", "<cmd>split<cr>", { desc = "Split Window Horizontally", silent = true })
map("n", "sv", "<cmd>vsplit<cr>", { desc = "Split Window Vertically", silent = true })
map("n", "sh", "<C-w>h", { desc = "Go to Left Window" })
map("n", "sk", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "sj", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "sl", "<C-w>l", { desc = "Go to Right Window" })

-- Close / quit current split window
map("n", "sc", "<C-w>c", { desc = "Close Current Window" })
map("n", "sq", "<C-w>q", { desc = "Quit Current Window" })

-- Scroll half-page and keep cursor centered
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down & Center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up & Center" })

-- Resize window with arrow keys (LazyVim default, explicit override here)
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Buffer switching. There's no visible tab/bufferline bar (it clashed with
-- incline.nvim's floating filename, and bufferline.nvim itself was removed
-- — it kept fighting the "stay hidden" setting once enough buffers piled
-- up). Buffers still work exactly as normal via plain :bnext/:bprevious.
-- For a searchable list of everything open, use the Snacks picker buffer
-- list bound to "\\\\" (see plugins/picker.lua).
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Last Buffer" })

-- Clear navigation history (<leader>hj = jump list, <leader>hm = marks).
-- `:clearjumps` only clears the *current window's* jumplist, so entries
-- surviving in split windows made it seem broken — this clears every window.
map("n", "<leader>hj", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		vim.api.nvim_win_call(win, function()
			vim.cmd("clearjumps")
		end)
	end
	vim.notify("Jump list cleared in all windows", vim.log.levels.INFO)
end, { desc = "Clear Jump List (all windows)" })

-- Delete every deletable named/numbered mark (a-z, A-Z, 0-9). Individual
-- delmarks avoids :delmarks! / !! quirks about global vs buffer-local marks.
map("n", "<leader>hm", function()
	for _, m in ipairs(vim.fn.getmarklist()) do
		local name = m.mark:sub(2)
		if name:match("^[%a]") or name:match("^%d$") then
			pcall(vim.cmd, "delmarks " .. name)
		end
	end
	vim.notify("Marks cleared", vim.log.levels.INFO)
end, { desc = "Clear All Marks" })

-- Move Lines up/down
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Select All
-- FIX: this used to be mapped to <C-a>, which silently overwrote Vim's
-- built-in "increment number under cursor" — a genuinely useful editing
-- command with no other binding, so it was just gone. Moved to <leader>aa
-- so both features are available.
map("n", "<leader>aa", "gg<S-v>G", { desc = "Select All Text" })

-- Map 'jj' to exit insert mode
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Show diagnostic float window at cursor (works in both normal and insert mode)
map({ "n", "i" }, "<A-d>", function()
	vim.diagnostic.open_float()
end, { desc = "Line Diagnostics" })

-- Web preview, tier 2: framework dev servers (Vite, Next.js, CRA, Flutter
-- web) that already run their own dev server with real HMR over a
-- websocket — no file-watcher/reload logic needed here at all, the
-- framework's own tooling already refreshes the page the instant you save.
-- Run the dev server itself as an Overseer task (<leader>o - see the
-- editor.overseer extra in config/lazy.lua) so starting/stopping/viewing
-- its logs stays inside Neovim rather than a separate terminal tab; this
-- keymap just pops the browser to the right URL, using Neovim's own
-- built-in vim.ui.open() — cross-platform, no hardcoded browser binary.
-- (Static HTML/CSS/JS projects with no dev server of their own: use
-- <leader>P instead — see plugins/live-server.lua.)
map("n", "<leader>Pu", function()
	local url = vim.fn.input("Dev server URL: ", "http://localhost:5173")
	if url == "" then
		return
	end
	vim.ui.open(url)
end, { desc = "Open Dev Server URL in Browser" })

-- Git: everything workflows via lazygit, not the snacks git pickers.
-- LazyVim's own config.keymaps (gg/gG/gl/gL/gf/gb) load before this file,
-- so they're overridden or deleted here. Keys that came from the
-- snacks_picker extra (gd/gD/gs/gS/fg) are removed in plugins/picker.lua.
-- gi/gI/gp/gP (GitHub issues/PRs) and gB/gY (gitbrowse) stay — lazygit has
-- no equivalent.
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
-- Blame line is covered by gitsigns' <leader>ghb / <leader>ghB — drop the
-- snacks picker version entirely.
vim.keymap.del("n", "<leader>gb")

-- Java Automation (project scaffolding + new file types + run)
-- The heavy module is loaded lazily on first use.
local function java(fn)
	return function()
		local ok, creator = pcall(require, "config.java_creator")
		if not ok then
			vim.notify("Failed to load config/java_creator: " .. tostring(creator), vim.log.levels.ERROR)
			return
		end
		-- Ensure commands & optional keymaps from the module are registered
		if creator.setup and not creator._setup_done then
			creator.setup({ keymaps = false }) -- we manage keymaps here
			creator._setup_done = true
		end
		creator[fn]()
	end
end

-- Commands
vim.api.nvim_create_user_command("JavaNew", java("new"), {
	desc = "Java: New Project or New File (menu)",
})
vim.api.nvim_create_user_command("JavaNewProject", java("scaffold_project"), {
	desc = "Java: Scaffold new project",
})
vim.api.nvim_create_user_command("JavaNewFile", java("new_java_type"), {
	desc = "Java: New Class / Interface / Enum / …",
})
vim.api.nvim_create_user_command("JavaRun", java("run_project"), {
	desc = "Java: Compile & run current project",
})

-- Keymaps
map("n", "<leader>jn", "<cmd>JavaNew<cr>", { desc = "Java: New Project / New File" })
map("n", "<leader>jr", "<cmd>JavaRun<cr>", { desc = "Java: Run project" })
