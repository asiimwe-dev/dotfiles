-- lua/plugins/ai_completion.lua
-- Production-ready multi-engine AI inline completion.
-- Uses official should_attach / filter APIs + strong privacy guards.
--
-- Engines are OFF by default and must be enabled explicitly:
--   <leader>aic  Copilot
--   <leader>ain  NeoCodeium (Windsurf)
--   <leader>aio  All engines OFF
--   <leader>ait  Cycle engines
--   <leader>ais  Show current engine
--   <M-l> / <M-w> / <M-a>  accept / accept word / accept line
--   <C-]>  dismiss the current suggestion
--
-- Per-buffer opt-out: set vim.b[bufnr].ai_completion_disabled = true
--
-- Note: <leader>ai* is used because <leader>a is often taken by other plugins.

---------------------------------------------------------------------------
-- Shared safety + state module (local to this file)
---------------------------------------------------------------------------
local AI = {
	current = "none", -- "none" | "copilot" | "neocodeium"
}

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "AI Engine" })
end

-- Known sensitive / UI filetypes (kept at module scope, not re-created)
local sensitive_fts = {
	gitcommit = true,
	gitrebase = true,
	hgcommit = true,
	svn = true,
	cvs = true,
	help = true,
	man = true,
	qf = true,
	netrw = true,
	TelescopePrompt = true,
	TelescopeResults = true,
	lazy = true,
	mason = true,
	["neo-tree"] = true,
	NvimTree = true,
	oil = true,
	snacks_picker = true,
	snacks_explorer = true,
	snacks_input = true,
	snacks_notif = true,
	snacks_terminal = true,
	snacks_dashboard = true,
	snacks_layout_box = true,
	["dap-repl"] = true,
	dapui_watches = true,
	dapui_stacks = true,
	dapui_breakpoints = true,
	dapui_scopes = true,
	dapui_console = true,
	checkhealth = true,
	alpha = true,
	dashboard = true,
	startify = true,
	lazygit = true,
}

-- Path / filename patterns for secrets, credentials and keys (lowercased)
local sensitive_patterns = {
	"%.env",
	"%.env%..*",
	"secrets?",
	"credentials?",
	"%.pem$",
	"%.key$",
	"%.secret$",
	"%.p12$",
	"%.pfx$",
	"%.jks$",
	"%.keystore$",
	"%.crt$",
	"%.cer$",
	"id_rsa",
	"id_ed25519",
	"id_ecdsa",
	"%.gpg$",
	"%.asc$",
	"passwd",
	"shadow",
	"%.netrc",
	"%.pgpass",
	"%.npmrc$",
	"%.yarnrc$",
	"%.pypirc$",
	"%.gemrc$",
	"%.bazrc$",
	"git%-credentials",
	"%.git%-credentials",
	"aws.?credentials",
	"%.aws/credentials",
	"kube.?config",
	"%.kube/config",
	"%.docker/config%.json",
	"%.dockerconfigjson",
	"lazygit",
	-- Extra high-value patterns
	"%.secrets?%.json$",
	"%.secrets?%.ya?ml$",
	"credentials%.json$",
	"service.?account",
	"%.tfstate",
	"%.ssh/config$",
	"id_rsa%.pub",
}

--- Pure function: is this buffer safe for AI?
---@param bufnr? integer
---@return boolean
local function is_safe_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	-- Explicit per-buffer opt-out
	if vim.b[bufnr].ai_completion_disabled then
		return false
	end

	local bo = vim.bo[bufnr]
	local name = vim.api.nvim_buf_get_name(bufnr):lower()
	local ft = bo.filetype
	local bt = bo.buftype

	-- 1. Special / UI buftypes (allow normal + acwrite, block everything else)
	if bt ~= "" and bt ~= "acwrite" then
		return false
	end

	-- 2. Never suggest inside read-only buffers
	if not bo.modifiable then
		return false
	end

	-- 3. Known sensitive / UI filetypes
	if sensitive_fts[ft] then
		return false
	end

	-- 4. Path / filename patterns (secrets, credentials, keys…)
	for _, pat in ipairs(sensitive_patterns) do
		if name:match(pat) then
			return false
		end
	end

	-- 5. Protocol / special schemes (oil, fugitive, etc.)
	if name:match("^%w+://") and not name:match("^file://") then
		return false
	end

	-- 6. Unlisted buffers are usually temporary / UI
	if not bo.buflisted and bt == "" then
		if name == "" or name:match("^term://") then
			return false
		end
	end

	-- 7. Skip very large files (cost / latency / accidental secret dumps)
	if name ~= "" then
		local ok, size = pcall(vim.fn.getfsize, name)
		if ok and type(size) == "number" and size > 1000000 then -- 1 MB
			return false
		end
	end

	return true
end

local function refresh_statusline()
	pcall(function()
		require("lualine").refresh({ place = { "statusline" } })
	end)
end

---------------------------------------------------------------------------
-- Engine controllers (thin wrappers around official commands / APIs)
---------------------------------------------------------------------------
local controllers = {
	copilot = {
		cmd = ":Copilot",
		module = "copilot",
		enable = function()
			pcall(function()
				vim.cmd("Copilot enable")
			end)
		end,
		disable = function()
			pcall(function()
				vim.cmd("Copilot disable")
			end)
		end,
		available = function()
			return pcall(require, "copilot") or vim.fn.exists(":Copilot") == 2
		end,
		accept = function()
			local ok, s = pcall(require, "copilot.suggestion")
			if ok and s.is_visible and s.is_visible() then
				s.accept()
				return true
			end
			return false
		end,
		accept_word = function()
			local ok, s = pcall(require, "copilot.suggestion")
			if ok and s.is_visible and s.is_visible() then
				s.accept_word()
				return true
			end
			return false
		end,
		accept_line = function()
			local ok, s = pcall(require, "copilot.suggestion")
			if ok and s.is_visible and s.is_visible() then
				s.accept_line()
				return true
			end
			return false
		end,
	},

	neocodeium = {
		cmd = ":NeoCodeium",
		module = "neocodeium",
		enable = function()
			pcall(function()
				-- Prefer Lua API (stable, no command parsing quirks)
				local ok, commands = pcall(require, "neocodeium.commands")
				if ok and commands.enable then
					commands.enable()
				else
					vim.cmd("NeoCodeium enable")
				end
			end)
		end,
		disable = function()
			pcall(function()
				-- Prefer Lua API. true = also stop the server binary
				-- (true privacy when off). Bang form is :NeoCodeium! disable
				-- (bang on the command, NOT on the subcommand).
				local ok, commands = pcall(require, "neocodeium.commands")
				if ok and commands.disable then
					commands.disable(true)
				else
					vim.cmd("NeoCodeium! disable")
				end
			end)
		end,
		available = function()
			return pcall(require, "neocodeium") or vim.fn.exists(":NeoCodeium") == 2
		end,
		accept = function()
			local ok, neo = pcall(require, "neocodeium")
			if ok and neo.visible and neo.visible() then
				neo.accept()
				return true
			end
			return false
		end,
		accept_word = function()
			local ok, neo = pcall(require, "neocodeium")
			if ok and neo.visible and neo.visible() then
				neo.accept_word()
				return true
			end
			return false
		end,
		accept_line = function()
			local ok, neo = pcall(require, "neocodeium")
			if ok and neo.visible and neo.visible() then
				neo.accept_line()
				return true
			end
			return false
		end,
	},
}

-- Is the engine actually enabled in the running session right now?
local function is_enabled(name)
	if name == "copilot" then
		return #vim.lsp.get_clients({ name = "copilot" }) > 0
	elseif name == "neocodeium" then
		local ok, neo = pcall(require, "neocodeium")
		if ok and neo.get_status then
			-- 0 = Enabled
			-- 1 = Globally disabled
			-- 2 = Buffer disabled
			-- 3 = Filetype disabled
			-- 4 = Filter returned false
			-- 5 = Wrong encoding
			-- 6 = Special buftype
			local status = neo.get_status()
			return status == 0
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
--- Switch the active engine ("none" | "copilot" | "neocodeium").
---@param target string
---@param silent? boolean
---@return boolean ok Whether the switch succeeded
function AI.switch(target, silent)
	if target ~= "none" and not controllers[target] then
		if not silent then
			notify("Unknown engine: " .. tostring(target), vim.log.levels.ERROR)
		end
		return false
	end

	-- No-op when already in the requested state (avoids needless restarts)
	if AI.current == target then
		if target == "none" or is_enabled(target) then
			return true
		end
		-- stale state: engine lost but we think it's active → fall through
	end

	-- Always disable the other engine(s) first
	for name, ctrl in pairs(controllers) do
		if name ~= target and ctrl.available() then
			ctrl.disable()
		end
	end

	if target == "none" then
		AI.current = "none"
		if not silent then
			notify("All AI engines OFF")
		end
	else
		-- Set state BEFORE enabling so should_attach/filter see it immediately
		AI.current = target
		if controllers[target].available() then
			controllers[target].enable()
			if not silent then
				notify("→ " .. target)
			end
		else
			AI.current = "none"
			if not silent then
				notify(target .. " is not available", vim.log.levels.WARN)
			end
			refresh_statusline()
			return false
		end
	end

	refresh_statusline()
	return true
end

--- Cycle through engines, skipping any that aren't installed.
function AI.cycle()
	local order = { "copilot", "neocodeium", "none" }
	local start = 1
	for i, eng in ipairs(order) do
		if eng == AI.current then
			start = i
			break
		end
	end
	for _ = 1, #order do
		local candidate = order[start % #order + 1]
		start = start + 1
		if candidate == "none" or (controllers[candidate] and controllers[candidate].available()) then
			AI.switch(candidate, false)
			return
		end
	end
	AI.switch("none", false)
end

---@return string current engine ("none" | "copilot" | "neocodeium")
function AI.status()
	return AI.current
end

---@return boolean true when any engine is active
function AI.is_active()
	return AI.current ~= "none"
end

---Expose the safety predicate (useful for statusline / custom filters).
---@param bufnr? integer
---@return boolean
function AI.is_safe_buffer(bufnr)
	return is_safe_buffer(bufnr)
end

---Accept the current suggestion from whichever engine is active.
---@param kind? "line" | "word" | "full"
---@return boolean accepted
function AI.accept(kind)
	local eng = AI.current
	local ctrl = eng ~= "none" and controllers[eng]
	if not ctrl then
		return false
	end
	if kind == "word" then
		return ctrl.accept_word()
	elseif kind == "full" then
		return ctrl.accept()
	end
	return ctrl.accept_line()
end

---Dismiss the current suggestion from whichever engine is active.
function AI.dismiss()
	local eng = AI.current
	if eng == "copilot" then
		pcall(function()
			require("copilot.suggestion").dismiss()
		end)
	elseif eng == "neocodeium" then
		pcall(function()
			require("neocodeium").clear()
		end)
	end
end

---Show the current engine in a notification.
function AI.show_status()
	notify("Current engine: " .. AI.current)
end

---Deterministic off-state WITHOUT force-loading lazy-loaded engines. Only
---touches engines whose modules are already in package.loaded.
function AI.ensure_off()
	for _, ctrl in pairs(controllers) do
		if ctrl.module and package.loaded[ctrl.module] then
			ctrl.disable()
		end
	end
	AI.current = "none"
end

-- Expose for statusline / other plugins
_G.AICompletion = AI

---------------------------------------------------------------------------
-- Plugin specs
---------------------------------------------------------------------------
return {
	---------------------------------------------------------------------------
	-- GitHub Copilot (copilot.lua)
	---------------------------------------------------------------------------
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		build = ":Copilot auth",
		opts = {
			panel = { enabled = false },
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = false, -- we handle accept ourselves (unified keys)
					accept_word = false,
					accept_line = false,
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = false, -- unified <C-]> handles dismissal
				},
			},
			-- Explicit disables; omit ["*"] so plugin internal defaults still apply
			-- for unlisted filetypes. should_attach is the real gate anyway.
			filetypes = {
				yaml = false,
				markdown = false,
				help = false,
				gitcommit = false,
				gitrebase = false,
				["."] = false,
			},
			-- Official recommended way to refuse buffers (runs before attach)
			should_attach = function(bufnr, _)
				return AI.current == "copilot" and is_safe_buffer(bufnr)
			end,
		},
		config = function(_, opts)
			require("copilot").setup(opts)
			-- Start disabled; user (or AI.switch) will enable when wanted
			pcall(function()
				vim.cmd("Copilot disable")
			end)
		end,
	},

	---------------------------------------------------------------------------
	-- NeoCodeium (Windsurf / formerly Codeium)
	---------------------------------------------------------------------------
	{
		"monkoose/neocodeium",
		cmd = "NeoCodeium", -- lazy-load on demand so :NeoCodeium always works
		event = "VeryLazy",
		opts = {
			-- Start DISABLED. NOTE: `enabled` is strictly a boolean in
			-- neocodeium (not a function) — a function is always truthy and
			-- would boot the Windsurf server on startup, silently defeating
			-- the privacy default. Toggle at runtime via :NeoCodeium enable
			-- or AI.switch("neocodeium").
			enabled = false,
			manual = false,
			debounce = true, -- safer default than the plugin's no-debounce
			show_label = true,
			silent = true,
			disable_in_special_buftypes = true,
			-- Official filter – runs on every buffer
			filter = function(bufnr)
				return AI.current == "neocodeium" and is_safe_buffer(bufnr)
			end,
			filetypes = {
				help = false,
				gitcommit = false,
				gitrebase = false,
				TelescopePrompt = false,
				["dap-repl"] = false,
				["."] = false,
			},
		},
		config = function(_, opts)
			require("neocodeium").setup(opts)
			-- Guaranteed off after setup (enabled=false already does this,
			-- but explicit disable keeps state consistent if setup changes).
			pcall(function()
				local ok, commands = pcall(require, "neocodeium.commands")
				if ok and commands.disable then
					commands.disable(true)
				end
			end)
		end,
	},
}
