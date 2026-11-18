-- lua/plugins/flutter.lua
-- Flutter support for Neovim via flutter-tools.nvim (lazy.nvim spec).
--
-- Requirements: Neovim 0.11+, lazy.nvim, a Flutter SDK (PATH, FVM, or one of
-- the locations searched in `resolve_flutter_path`).
--
-- Design notes:
--   * Only documented flutter-tools commands/options are used (checked against
--     the upstream README). No plugin internals are required, so refactors
--     upstream can't break the keymaps.
--   * Keymaps are buffer-local to Dart files and every one goes through
--     `run()`, which (a) tells the user what is happening, (b) checks the
--     command exists, and (c) reports failures instead of throwing.
--   * Everything environment-specific degrades gracefully instead of erroring.
--
-- Known upstream issue (flutter-tools.nvim #557, fix PR #558, still open when
-- this was written): :FlutterQuit can print
--   "attempt to index local 'line' (a nil value)" from commands.lua
-- while the session shuts down. It is raised inside the plugin's own scheduled
-- output callback, so no wrapper can catch it. See the commented opt-in
-- override below, and remove it once #558 is merged.

local TITLE = "Flutter"

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = TITLE })
end

-- Resolve the Flutter SDK. Returns nil to let flutter-tools use PATH.
-- Order: vim.g.flutter_sdk_path -> $FLUTTER_ROOT -> PATH -> common locations.
local function resolve_flutter_path()
	local exe = vim.fn.has("win32") == 1 and "flutter.bat" or "flutter"
	local home = vim.uv.os_homedir() or ""

	local function bin(root)
		return root .. "/bin/" .. exe
	end

	-- `or false` keeps the list free of nils: ipairs() stops at the first nil,
	-- which previously made an unset g:flutter_sdk_path hide $FLUTTER_ROOT.
	for _, root in ipairs({ vim.g.flutter_sdk_path or false, vim.env.FLUTTER_ROOT or false }) do
		if root and vim.fn.executable(bin(root)) == 1 then
			return bin(root)
		end
	end

	if vim.fn.executable("flutter") == 1 then
		return nil -- already on PATH
	end

	for _, root in ipairs({
		home .. "/development/flutter",
		home .. "/flutter",
		home .. "/snap/flutter/common/flutter",
	}) do
		if vim.fn.executable(bin(root)) == 1 then
			return bin(root)
		end
	end

	vim.schedule(function()
		notify(
			"No Flutter SDK found. Add `flutter` to PATH, set $FLUTTER_ROOT, "
				.. "or set vim.g.flutter_sdk_path before plugins load.",
			vim.log.levels.WARN
		)
	end)
	return nil
end

-- Merge blink.cmp capabilities when available; never error if it isn't.
local function build_capabilities(config)
	local ok, blink = pcall(require, "blink.cmp")
	if ok and type(blink.get_lsp_capabilities) == "function" then
		local ok2, merged = pcall(blink.get_lsp_capabilities, config)
		if ok2 and type(merged) == "table" then
			return merged
		end
	end
	return config
end

-- Native color previews (Colors.blue, Color(0xFF...)) on Neovim 0.12+.
-- Neovim 0.12 changed the signature to enable(enable, filter, opts); the old
-- form enable(enable, bufnr, opts) silently did nothing under pcall. Try the
-- new form first, then the old one. No-op where the API doesn't exist.
local function enable_document_colors(_, bufnr)
	local dc = vim.lsp.document_color
	if not (dc and type(dc.enable) == "function") then
		return
	end
	local opts = { style = "background" } -- "background" | "foreground" | "virtual"
	if not pcall(dc.enable, true, { bufnr = bufnr }, opts) then
		pcall(dc.enable, true, bufnr, opts)
	end
end

-- Run a flutter-tools command with user feedback and safe error handling.
--   cmd      : Ex command name (e.g. "FlutterRun")
--   starting : message shown immediately (what is being performed)
local function run(cmd, starting)
	return function()
		if vim.fn.exists(":" .. cmd) ~= 2 then
			notify(
				cmd
					.. " is not available. Open a Dart file inside a Flutter project "
					.. "and make sure flutter-tools.nvim is installed (:Lazy).",
				vim.log.levels.WARN
			)
			return
		end
		notify(starting)
		local ok, err = pcall(function()
			vim.cmd(cmd)
		end)
		if not ok then
			notify(cmd .. " failed: " .. tostring(err), vim.log.levels.ERROR)
		end
	end
end

-- Ask the Dart language server to organize imports (sort + remove unused).
local function organize_imports()
	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		notify("No language server is attached to this buffer yet.", vim.log.levels.WARN)
		return
	end
	notify("Organizing imports…")
	vim.lsp.buf.code_action({
		context = { only = { "source.organizeImports" }, diagnostics = {} },
		apply = true,
	})
end

-- Is this a FVM project? Resolved from the Dart file's own directory instead
-- of the cwd, so launching nvim from outside the project still finds `.fvm`.
-- (flutter-tools reads this once at setup, so one session = one SDK flavour.)
local function uses_fvm()
	local name = vim.api.nvim_buf_get_name(0)
	local start = name ~= "" and name or (vim.uv.cwd() or vim.fn.getcwd())
	return vim.fs.root(start, { ".fvm" }) ~= nil
end

-- ── Hot reload on save ──────────────────────────────────────────────────
-- flutter-tools has no built-in "reload on save", so it is wired here.
--   * only files under lib/ (tests, tooling, pubspec.yaml don't hot reload)
--   * silently skipped when no app was started/attached through flutter-tools
--   * debounced, so :wa / format-on-save / autowrite produce ONE reload
--   * toggle with <leader>Fh (vim.g.flutter_hot_reload_on_save, default on)
-- Reminder: reload cannot apply changes to main(), const/initial state, enums
-- or generics. Those need a hot RESTART (<leader>FR).
vim.g.flutter_hot_reload_on_save = vim.g.flutter_hot_reload_on_save ~= false

local reload_timer
local function cancel_reload_timer()
	if reload_timer and not reload_timer:is_closing() then
		reload_timer:stop()
		reload_timer:close()
	end
	reload_timer = nil
end

local function hot_reload_on_save(ev)
	if not vim.g.flutter_hot_reload_on_save then
		return
	end
	local path = vim.fn.fnamemodify(ev.file, ":p"):gsub("\\", "/")
	if not path:find("/lib/", 1, true) then
		return
	end
	-- Optional guard via flutter-tools' own state; if that internal API ever
	-- changes we just fall through and rely on :FlutterReload being quiet.
	local ok, cmds = pcall(require, "flutter-tools.commands")
	if ok and type(cmds.is_running) == "function" and not cmds.is_running() then
		return
	end
	cancel_reload_timer()
	local timer = vim.uv.new_timer()
	if not timer then
		return
	end
	reload_timer = timer
	timer:start(
		120,
		0,
		vim.schedule_wrap(function()
			cancel_reload_timer()
			pcall(function()
				vim.cmd("FlutterReload")
			end)
		end)
	)
end

local function setup_hot_reload_on_save()
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("FlutterHotReloadOnSave", { clear = true }),
		pattern = "*.dart",
		callback = hot_reload_on_save,
	})
end

local function toggle_hot_reload_on_save()
	vim.g.flutter_hot_reload_on_save = not vim.g.flutter_hot_reload_on_save
	notify("Hot reload on save: " .. (vim.g.flutter_hot_reload_on_save and "ON" or "OFF"))
end

return {
	{
		-- Default: upstream. To get the FlutterQuit nil-check fix before PR #558
		-- is merged, swap in the block below (opt-in; remove once merged):
		--   "mmcdanielq/flutter-tools.nvim",
		--   branch = "fix/commands-update-device-from-output-nil-check",
		"nvim-flutter/flutter-tools.nvim",
		main = "flutter-tools",
		ft = "dart",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = function()
			return {
				flutter_path = resolve_flutter_path(),
				fvm = uses_fvm(),

				ui = {
					border = "rounded",
					notification_style = "native",
				},

				-- NOTE: the key is `statusline` (not `status`).
				decorations = {
					statusline = {
						app_version = true,
						device = true,
					},
				},

				widget_guides = { enabled = true },

				-- VS Code style closing labels, e.g. `// Container`
				closing_tags = {
					enabled = true,
					highlight = "Comment",
					prefix = "// ",
				},

				-- Debugging through nvim-dap is opt-in (needs mfussenegger/nvim-dap).
				debugger = {
					enabled = false,
				},

				dev_log = {
					enabled = true,
					notify_errors = true, -- surface failed reloads / runtime errors
					open_cmd = "15split",
					focus_on_open = false, -- keep the cursor in your code
				},

				dev_tools = {
					autostart = false,
					auto_open_browser = false,
				},

				outline = {
					open_cmd = "30vnew",
					auto_open = false,
				},

				lsp = {
					on_attach = enable_document_colors,
					capabilities = build_capabilities,
					settings = {
						showTodos = true,
						completeFunctionCalls = true,
						enableSnippets = true,
						enableSdkFormatter = true,
						updateImportsOnRename = true,
						renameFilesWithClasses = "always",
						analysisExcludedFolders = {
							vim.fn.expand("$HOME/.pub-cache"),
						},
					},
				},
			}
		end,

		config = function(_, opts)
			require("flutter-tools").setup(opts)
			setup_hot_reload_on_save()
		end,

		-- All maps are Dart-buffer-local. Each tells you what it is doing.
		keys = {
			{
				"<leader>Fr",
				run("FlutterRun", "Starting app… (pick a device if asked)"),
				ft = "dart",
				desc = "Flutter Run",
			},
			{
				"<leader>Fq",
				run("FlutterQuit", "Stopping the running app…"),
				ft = "dart",
				desc = "Flutter Quit (stop app)",
			},
			{
				"<leader>FD",
				run("FlutterDetach", "Detaching (app keeps running on device)…"),
				ft = "dart",
				desc = "Flutter Detach (leave app running)",
			},
			{ "<leader>FR", run("FlutterRestart", "Hot restarting…"), ft = "dart", desc = "Flutter Hot Restart" },
			{ "<leader>Fl", run("FlutterReload", "Hot reloading…"), ft = "dart", desc = "Flutter Hot Reload" },
			{ "<leader>Fd", run("FlutterDevices", "Listing devices…"), ft = "dart", desc = "Flutter Devices" },
			{ "<leader>Fe", run("FlutterEmulators", "Listing emulators…"), ft = "dart", desc = "Flutter Emulators" },
			{
				"<leader>FL",
				run("FlutterLogToggle", "Toggling Flutter log…"),
				ft = "dart",
				desc = "Toggle Flutter Log",
			},
			{
				"<leader>Fc",
				run("FlutterLogClear", "Clearing Flutter log…"),
				ft = "dart",
				desc = "Clear Flutter Log",
			},
			{
				"<leader>Ft",
				run("FlutterDevTools", "Starting DevTools server…"),
				ft = "dart",
				desc = "Start DevTools",
			},
			{
				"<leader>Fo",
				run("FlutterOutlineToggle", "Toggling widget outline…"),
				ft = "dart",
				desc = "Toggle Flutter Outline",
			},
			{
				"<leader>Fs",
				run("FlutterLspRestart", "Restarting Dart language server…"),
				ft = "dart",
				desc = "Restart Dart LSP",
			},
			{ "<leader>Fi", organize_imports, ft = "dart", desc = "Organize Imports" },
			{ "<leader>Fh", toggle_hot_reload_on_save, ft = "dart", desc = "Toggle Hot Reload on Save" },
		},
	},

	-- flutter-tools starts its own dartls and its README says NOT to configure
	-- dartls through lspconfig. The lang.dart extra does exactly that
	-- (servers.dartls = {}), which leaves two Dart analysis servers running per
	-- project. Keep the extra (parser, formatter, neotest) but turn its server off.
	{
		"neovim/nvim-lspconfig",
		opts = { servers = { dartls = { enabled = false } } },
	},
}
