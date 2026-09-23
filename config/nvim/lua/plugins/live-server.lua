-- ~/.config/nvim/lua/plugins/live-server.lua
--
-- Web preview, tier 1: static HTML/CSS/JS (no build tool/dev server of its
-- own) — vanilla practice projects, static sites, no framework.
--
-- live-server.nvim is a genuine, actively maintained plugin purpose-built
-- for this: pure Lua (no npm/node/python/binaries), binds to 127.0.0.1
-- only, real SSE-based live-reload (not a file-save-triggers-browser hack)
-- with CSS hot-injection (style changes apply without a full reload/lost
-- DOM state), and it opens the browser via Neovim's own built-in
-- `vim.ui.open()` — cross-platform, no hardcoded browser binary or flags,
-- works identically regardless of desktop environment or terminal.
--
-- For a project with its own dev server (Vite/Next.js/CRA/Flutter web —
-- see tier 2 below), don't use this plugin for that project; those already
-- have better HMR than a generic file-watcher could offer.
return {
	{
		"selimacerbas/live-server.nvim",
		dependencies = {
			-- NOTE: the upstream README also lists telescope.nvim as a
			-- "recommended" dependency for the path/port picker UX. Not
			-- included — this config's finder is Snacks.picker (LazyVim's
			-- own default; see plugins/picker.lua), not telescope, and
			-- live-server.nvim doesn't integrate with Snacks directly
			-- either. It falls back to vim.ui.select/vim.ui.input, which
			-- resolve through dressing.nvim's rounded builtin backend
			-- regardless of which finder is active, so the picker UI stays
			-- visually consistent with the rest of this config either way.
		},
		cmd = {
			"LiveServerStart",
			"LiveServerOpen",
			"LiveServerReload",
			"LiveServerToggleLive",
			"LiveServerStatus",
			"LiveServerStop",
			"LiveServerStopAll",
		},
		keys = {
			{ "<leader>Ps", "<cmd>LiveServerStart<cr>", desc = "Start (pick path & port)" },
			{ "<leader>Po", "<cmd>LiveServerOpen<cr>", desc = "Open existing port in browser" },
			{ "<leader>Pr", "<cmd>LiveServerReload<cr>", desc = "Force reload (pick port)" },
			{ "<leader>Pt", "<cmd>LiveServerToggleLive<cr>", desc = "Toggle live-reload (pick port)" },
			{ "<leader>Pi", "<cmd>LiveServerStatus<cr>", desc = "Show server status" },
			{ "<leader>PS", "<cmd>LiveServerStop<cr>", desc = "Stop one (pick port)" },
			{ "<leader>PA", "<cmd>LiveServerStopAll<cr>", desc = "Stop all" },
		},
		opts = {
			default_port = 8000,
			open_on_start = true,
			notify = true,
			notify_on_reload = false,
			live_reload = {
				enabled = true,
				inject_script = true,
				debounce = 120,
				css_inject = true, -- CSS changes hot-swap without a full reload
			},
			directory_listing = {
				enabled = true,
				show_hidden = false,
			},
			-- Deliberately not setting `auto_start` — auto-launching a server
			-- just because an .html file was opened can surprise you with an
			-- unexpected extra server running per project. Start explicitly
			-- with <leader>Ps instead. If you want auto-start for a specific
			-- workflow, this is the option:
			-- auto_start = { filetypes = { "html" }, port = 8000 },
		},
		config = function(_, opts)
			require("live_server").setup(opts)
		end,
	},
}
