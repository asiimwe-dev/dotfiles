-- ~/.config/nvim/lua/config/ai.lua
-- Copilot controller: on/off state, privacy guard and accept/dismiss helpers.
-- Replaces the old `_G.AICompletion` global; keymaps and lualine now
-- `require("config.ai")` explicitly so the dependency is visible.
local M = { enabled = false }

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Copilot" })
end

local function run_cmd(command)
	return pcall(function()
		vim.cmd(command)
	end)
end

local function refresh_statusline()
	vim.cmd("redrawstatus")
end

-- ── Privacy guard ────────────────────────────────────────────────────────
-- Matching is done on the *basename*, extension and well-known directories,
-- not on substrings of the whole path, so `~/code/secretary-app/main.py`
-- is no longer treated as sensitive while `.npmrc` or `*.tfvars` now are.
local sensitive_fts = {
	gitcommit = true,
	gitrebase = true,
	help = true,
	netrw = true,
	lazy = true,
	mason = true,
	snacks_picker = true,
	snacks_terminal = true,
	checkhealth = true,
}

local sensitive_names = {
	[".envrc"] = true,
	[".npmrc"] = true,
	[".netrc"] = true,
	[".pgpass"] = true,
	[".pypirc"] = true,
	[".htpasswd"] = true,
	[".git-credentials"] = true,
	["id_rsa"] = true,
	["id_dsa"] = true,
	["id_ecdsa"] = true,
	["id_ed25519"] = true,
	["passwd"] = true,
	["shadow"] = true,
	["kubeconfig"] = true,
	["terraform.tfstate"] = true,
	["terraform.tfstate.backup"] = true,
}

local sensitive_name_patterns = {
	"^%.env$",
	"^%.env[%._%-]",
	"^secrets?$",
	"^secrets?[%._%-]",
	"^credentials?$",
	"^credentials?[%._%-]",
	"^service[%-_]?account.*%.json$",
}

local sensitive_exts = {
	env = true,
	pem = true,
	key = true,
	p12 = true,
	pfx = true,
	jks = true,
	keystore = true,
	kdbx = true,
	gpg = true,
	tfvars = true,
}

local sensitive_dirs = { "/%.ssh/", "/%.aws/", "/%.gnupg/", "/%.kube/" }

local function is_sensitive_path(path)
	path = path:lower():gsub("\\", "/")
	local base = path:match("([^/]+)$") or path
	if sensitive_names[base] then
		return true
	end
	for _, pat in ipairs(sensitive_name_patterns) do
		if base:match(pat) then
			return true
		end
	end
	local ext = base:match("%.([^.]+)$")
	if ext and sensitive_exts[ext] then
		return true
	end
	for _, pat in ipairs(sensitive_dirs) do
		if path:find(pat) then
			return true
		end
	end
	return false
end

function M.is_safe_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	if vim.b[bufnr].ai_completion_disabled then
		return false
	end
	local bo = vim.bo[bufnr]
	if bo.buftype ~= "" and bo.buftype ~= "acwrite" then
		return false
	end
	if not bo.modifiable or sensitive_fts[bo.filetype] then
		return false
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name ~= "" then
		if is_sensitive_path(name) then
			return false
		end
		local size = vim.fn.getfsize(name)
		if type(size) == "number" and size > 1000000 then
			return false
		end
	end
	return true
end

-- Used as copilot.lua's `should_attach`.
function M.should_attach(bufnr)
	return M.enabled and M.is_safe_buffer(bufnr)
end

-- ── State ────────────────────────────────────────────────────────────────
function M.enable()
	if not run_cmd("Copilot enable") then
		notify("Could not enable Copilot (is the plugin loaded?)", vim.log.levels.ERROR)
		return
	end
	M.enabled = true
	notify("Copilot enabled")
	refresh_statusline()
end

function M.disable()
	if not run_cmd("Copilot disable") then
		notify("Could not disable Copilot", vim.log.levels.ERROR)
		return
	end
	M.enabled = false
	notify("Copilot disabled")
	refresh_statusline()
end

function M.toggle()
	if M.enabled then
		M.disable()
	else
		M.enable()
	end
end

function M.status()
	return M.enabled and "copilot" or "none"
end

function M.is_active()
	return M.enabled
end

function M.show_status()
	notify("Copilot is " .. (M.enabled and "ENABLED" or "DISABLED"))
end

-- ── Suggestion helpers ───────────────────────────────────────────────────
function M.accept(kind)
	if not M.enabled then
		return false
	end
	local ok, s = pcall(require, "copilot.suggestion")
	if ok and s.is_visible and s.is_visible() then
		if kind == "word" then
			s.accept_word()
		elseif kind == "line" then
			s.accept_line()
		else
			s.accept()
		end
		return true
	end
	return false
end

function M.dismiss()
	pcall(function()
		require("copilot.suggestion").dismiss()
	end)
end

return M
