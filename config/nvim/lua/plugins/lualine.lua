-- lua/plugins/lualine.lua
--
-- Standalone Lualine (bottom bar) · Glassy theme matching tmux
-- Tmux status lives on TOP with windows centred; this is the independent bottom bar.
--
-- Design rule: the bar stays quiet. Defaults (UTF-8, unix, your usual indent)
-- are hidden; anything that deviates from normal gets surfaced.
--
-- NOTE: `opts` returns a fresh table on purpose, so LazyVim's default lualine
-- sections are discarded. Parent `opts` functions still run (lazy.nvim resolves
-- them first), but their result is replaced by ours.

-- ─────────────────────────────────────────────────────────────
-- User switches
-- ─────────────────────────────────────────────────────────────
local TRANSPARENT = false -- false: original solid bg_base (true: bg = NONE for true "glass")
local SHOW_CLOCK = false -- original design; set false if tmux already shows a clock
local BIG_FILE_BYTES = 1024 * 1024 -- show file size only above this

local uv = vim.uv or vim.loop

-- ─────────────────────────────────────────────────────────────
-- Icons (by codepoint so they survive copy/paste and font-stripping)
-- ─────────────────────────────────────────────────────────────
local function ic(cp)
	return vim.fn.nr2char(cp)
end

local icons = {
	branch = ic(0xe0a0),
	record = ic(0xf044b),
	file = ic(0xf0214),
	modified = ic(0xf03eb),
	readonly = ic(0xf033e),
	err = ic(0xf015a),
	warn = ic(0xf0026),
	info = ic(0xf02fc),
	hint = ic(0xf0335),
	indent = ic(0xf0312),
	search = ic(0xf0349),
	formatter = ic(0xf0d0),
	lsp = ic(0xf013),
	copilot = ic(0xf4b8),
	python = ic(0xe73c),
	clock = ic(0xf017),
	cap_l = ic(0xe0b6),
	cap_r = ic(0xe0b4),
	comp_l = ic(0xe0b5),
	comp_r = ic(0xe0b7),
	sect_l = ic(0xe0b4),
	sect_r = ic(0xe0b6),
}

-- ─────────────────────────────────────────────────────────────
-- Refresh helpers
-- ─────────────────────────────────────────────────────────────
local aug = vim.api.nvim_create_augroup("UserLualine", { clear = true })

local function debounce(ms, fn)
	local timer = uv.new_timer()
	if not timer then
		return fn
	end
	return function()
		timer:stop()
		timer:start(ms, 0, vim.schedule_wrap(fn))
	end
end

local refresh_statusline = debounce(30, function()
	-- Don't force-load lualine from an early LspAttach/FileType event.
	if not package.loaded["lualine"] then
		return
	end
	-- With globalstatus a plain redraw re-evaluates every component; cheaper
	-- than lualine.refresh(), which rebuilds more than we need.
	vim.cmd("redrawstatus")
end)

vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave", "VimResized", "FocusGained", "DirChanged" }, {
	group = aug,
	callback = refresh_statusline,
})

-- ─────────────────────────────────────────────────────────────
-- Cached helpers
-- ─────────────────────────────────────────────────────────────

-- Per-buffer cache, invalidated by `events` and on buffer removal.
local function buf_cache(compute, events)
	local cache = {}
	vim.api.nvim_create_autocmd(events, {
		group = aug,
		callback = function(args)
			local buf = args.buf
			vim.schedule(function()
				cache[buf] = nil
				refresh_statusline()
			end)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = aug,
		callback = function(args)
			cache[args.buf] = nil
		end,
	})
	return function()
		local buf = vim.api.nvim_get_current_buf()
		local hit = cache[buf]
		if hit == nil then
			hit = compute(buf)
			cache[buf] = hit
		end
		return hit
	end
end

local formatter_cache = buf_cache(function(buf)
	local ok, conform = pcall(require, "conform")
	if not ok then
		return {}
	end
	-- Prefer what will actually run on save (respects stop_after_first and
	-- fallbacks); fall back to the configured list on older conform versions.
	local fn = conform.list_formatters_to_run or conform.list_formatters
	local ok_list, list = pcall(fn, buf)
	return ok_list and list or {}
end, { "FileType", "LspAttach", "LspDetach", "BufWritePost" })

local lsp_cache = buf_cache(function(buf)
	return vim.tbl_filter(function(c)
		return c.name ~= "copilot"
	end, vim.lsp.get_clients({ bufnr = buf }))
end, { "LspAttach", "LspDetach" })

-- Short-lived cache for file size (stat is a syscall).
local size_cache = { path = "", text = "", at = 0 }
local function file_size()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return ""
	end
	local now = uv.now()
	if path == size_cache.path and now - size_cache.at < 500 then
		return size_cache.text
	end
	local size = vim.fn.getfsize(path)
	local text = ""
	if type(size) == "number" and size >= BIG_FILE_BYTES then
		text = string.format("%.1fMB", size / (1024 * 1024))
	end
	size_cache.path, size_cache.text, size_cache.at = path, text, now
	return text
end

-- config.ai.status() is a plain boolean lookup, so no caching: a cache here
-- would show a stale state right after toggling Copilot.
local function ai_status()
	local ok, ai = pcall(require, "config.ai")
	return (ok and ai.status and ai.status()) or "none"
end

-- Virtualenv name never changes mid-session; resolve once.
local venv_label
local function venv_name()
	if venv_label == nil then
		local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_DEFAULT_ENV")
		if not venv or venv == "" then
			venv_label = ""
		else
			local name = vim.fn.fnamemodify(venv, ":t")
			-- ".venv" tells you nothing; use the project directory instead.
			if name == ".venv" or name == "venv" or name == "env" then
				name = vim.fn.fnamemodify(venv, ":h:t")
			end
			venv_label = icons.python .. " " .. name
		end
	end
	return venv_label
end

-- ─────────────────────────────────────────────────────────────
-- Show-on-exception segments
-- ─────────────────────────────────────────────────────────────

-- Encoding / line endings: silent for UTF-8 + unix.
local function file_meta()
	local parts = {}
	local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
	if enc:lower() ~= "utf-8" then
		parts[#parts + 1] = enc:upper()
	end
	if vim.bo.fileformat ~= "unix" then
		parts[#parts + 1] = vim.bo.fileformat
	end
	return table.concat(parts, " ")
end

-- Indent: silent when the buffer matches your global defaults.
local function eff_sw(sw, ts)
	return sw == 0 and ts or sw
end

local function indent_info()
	local sw = eff_sw(vim.bo.shiftwidth, vim.bo.tabstop)
	local gsw = eff_sw(vim.go.shiftwidth, vim.go.tabstop)
	if vim.bo.expandtab == vim.go.expandtab and sw == gsw then
		return ""
	end
	return string.format("%s %s:%d", icons.indent, vim.bo.expandtab and "Spaces" or "Tabs", sw)
end

-- Cursor position: virtcol is the display column (matches the ruler on tabs
-- and multibyte text, unlike the byte column from nvim_win_get_cursor).
local function position()
	return string.format("%d:%d", vim.fn.line("."), vim.fn.virtcol("."))
end

-- Formatters: show everything conform will run, e.g. "isort+black".
local function formatter_info()
	local list = formatter_cache()
	if #list == 0 then
		return ""
	end
	local names = {}
	for _, f in ipairs(list) do
		names[#names + 1] = f.name
	end
	return icons.formatter .. " " .. table.concat(names, "+")
end

-- ─────────────────────────────────────────────────────────────
-- Simple width thresholds (replaces the old layout engine)
-- Components that render empty cost nothing; the rest drop out as the
-- terminal narrows. Mode, filename, progress and position never hide.
-- ─────────────────────────────────────────────────────────────
local function wide(n)
	return function()
		return vim.o.columns >= n
	end
end

-- ─────────────────────────────────────────────────────────────
-- AI engine definitions
-- ─────────────────────────────────────────────────────────────
local ai_labels = { copilot = icons.copilot .. " Copilot" }

local function ai_display()
	local eng = ai_status()
	if eng == "none" or eng == "" then
		return ""
	end
	return ai_labels[eng] or eng
end

-- ─────────────────────────────────────────────────────────────
-- Branch colouring
-- ─────────────────────────────────────────────────────────────
local function branch_name()
	local dict = vim.b.gitsigns_status_dict
	local branch = (dict and dict.head) or vim.b.gitsigns_head or ""
	if branch == "" then
		local ok, git_branch = pcall(require, "lualine.components.branch.git_branch")
		if ok then
			branch = git_branch.get_branch() or ""
		end
	end
	return branch
end

local function build_opts()
	local colors = require("config.palette") -- bg_base bg_alt sky green yellow purple red teal orange muted text
	local bg_base, bg_alt = colors.bg_base, colors.bg_alt
	local c_bg = TRANSPARENT and "NONE" or bg_base

	-- Theme. Missing sections in insert/visual/etc. inherit from `normal`.
	-- No `inactive` block: globalstatus means there are no inactive statuslines.
	local theme = {
		normal = {
			a = { fg = bg_base, bg = colors.sky, gui = "bold" },
			b = { fg = colors.sky, bg = bg_alt, gui = "bold" },
			c = { fg = colors.text, bg = c_bg },
			x = { fg = colors.text, bg = c_bg },
			y = { fg = colors.sky, bg = bg_alt, gui = "bold" },
			z = { fg = bg_base, bg = colors.sky, gui = "bold" },
		},
		insert = {
			a = { fg = bg_base, bg = colors.green, gui = "bold" },
			z = { fg = bg_base, bg = colors.green, gui = "bold" },
		},
		visual = {
			a = { fg = bg_base, bg = colors.purple, gui = "bold" },
			z = { fg = bg_base, bg = colors.purple, gui = "bold" },
		},
		replace = {
			a = { fg = bg_base, bg = colors.red, gui = "bold" },
			z = { fg = bg_base, bg = colors.red, gui = "bold" },
		},
		command = {
			a = { fg = bg_base, bg = colors.yellow, gui = "bold" },
			z = { fg = bg_base, bg = colors.yellow, gui = "bold" },
		},
	}

	local caps = { left = icons.cap_l, right = icons.cap_r }

	-- Position + (optional) clock live at the far right.
	local position_in_y = {
		position,
		color = { fg = colors.mist, bg = bg_alt, gui = "bold" },
	}
	local position_in_z = {
		position,
		separator = caps,
		padding = { left = 1, right = 1 },
	}
	local clock = {
		function()
			return os.date("%H:%M")
		end,
		icon = icons.clock,
		separator = caps,
		padding = { left = 1, right = 1 },
	}

	local lualine_y = {
		{
			indent_info,
			color = { fg = colors.orange, bg = bg_alt, gui = "bold" },
		},
		{
			file_meta,
			color = { fg = colors.sky, bg = bg_alt, gui = "bold" },
		},
		{
			"progress",
			color = { fg = colors.slate, bg = bg_alt, gui = "bold" },
		},
	}
	local lualine_z
	if SHOW_CLOCK then
		table.insert(lualine_y, position_in_y)
		lualine_z = { clock }
	else
		lualine_z = { position_in_z }
	end

	return {
		options = {
			theme = theme,
			component_separators = { left = icons.comp_l, right = icons.comp_r },
			section_separators = { left = icons.sect_l, right = icons.sect_r },
			globalstatus = true,
			disabled_filetypes = { statusline = { "alpha", "snacks_dashboard" } },
		},
		sections = {
			lualine_a = {
				{
					"mode",
					fmt = function(str)
						return vim.o.columns < 80 and str:sub(1, 1) or str
					end,
					separator = caps,
					padding = { left = 1, right = 1 },
				},
			},
			lualine_b = {
				{
					"branch",
					cond = wide(80),
					icon = icons.branch,
					color = function()
						local branch = branch_name()
						-- Classify on the first path segment so "feature/x" and
						-- "user/feature/x" style names are handled predictably,
						-- and "debugging-tools" is not mistaken for a bugfix.
						local kind = branch:match("^[^/]+") or ""
						if branch == "main" or branch == "master" or branch == "prod" then
							return { fg = colors.red, bg = bg_alt, gui = "bold" }
						elseif kind:find("^feat") then
							return { fg = colors.green, bg = bg_alt, gui = "bold" }
						elseif kind:find("^fix") or kind:find("^bug") or kind:find("^hotfix") then
							return { fg = colors.yellow, bg = bg_alt, gui = "bold" }
						elseif kind:find("^dev") or kind:find("^staging") then
							return { fg = colors.teal, bg = bg_alt, gui = "bold" }
						end
						return { fg = colors.sky, bg = bg_alt, gui = "bold" }
					end,
				},
				{
					"diff",
					cond = wide(90),
					symbols = { added = "+", modified = "~", removed = "-" },
					colored = true,
					diff_color = {
						added = { fg = colors.green, gui = "bold" },
						modified = { fg = colors.yellow, gui = "bold" },
						removed = { fg = colors.red, gui = "bold" },
					},
					-- Read gitsigns directly so lualine never falls back to
					-- shelling out to git if gitsigns loads late.
					source = function()
						local d = vim.b.gitsigns_status_dict
						if d then
							return { added = d.added, modified = d.changed, removed = d.removed }
						end
					end,
				},
			},
			lualine_c = {
				{
					"filename",
					file_status = true,
					newfile_status = true,
					path = 1,
					shorting_target = 40, -- lualine shortens the path to leave room for the right side
					symbols = {
						modified = " " .. icons.modified,
						readonly = " " .. icons.readonly,
						unnamed = "[No Name]",
						newfile = " [New]",
					},
					color = { fg = colors.teal, gui = "bold" },
				},
				{
					"diagnostics",
					symbols = {
						error = icons.err .. " ",
						warn = icons.warn .. " ",
						info = icons.info .. " ",
						hint = icons.hint .. " ",
					},
					diagnostics_color = {
						error = { fg = colors.red, gui = "bold" },
						warn = { fg = colors.yellow, gui = "bold" },
						info = { fg = colors.sky, gui = "bold" },
						hint = { fg = colors.teal, gui = "bold" },
					},
				},
			},
			lualine_x = {
				{
					function()
						return icons.record .. " REC @" .. vim.fn.reg_recording()
					end,
					cond = function()
						return vim.fn.reg_recording() ~= ""
					end,
					color = { fg = bg_base, bg = colors.red, gui = "bold" },
					separator = caps,
				},
				{
					function()
						return venv_name()
					end,
					cond = function()
						return vim.bo.filetype == "python" and wide(90)()
					end,
					color = { fg = colors.slate, gui = "bold" },
				},
				{
					formatter_info,
					cond = wide(110),
					color = { fg = colors.slate, gui = "bold" },
				},
				{
					ai_display,
					cond = wide(100),
					color = function()
						local eng = ai_status()
						if eng == "copilot" then
							return { fg = colors.sky, gui = "bold" }
						end
						return { fg = colors.muted }
					end,
				},
				{
					"searchcount",
					icon = icons.search,
					color = { fg = colors.yellow, gui = "bold" },
				},
				{
					file_size,
					icon = icons.file,
					cond = function()
						return file_size() ~= ""
					end,
					color = { fg = colors.red, gui = "bold" },
				},
				{
					"lsp_status",
					cond = wide(100),
					icon = icons.lsp,
					symbols = {
						spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
						done = "✓",
						separator = " ",
					},
					ignore_lsp = { "copilot" },
					color = function()
						if #lsp_cache() == 0 then
							return { fg = colors.muted }
						end
						return { fg = colors.slate, gui = "bold" }
					end,
				},
			},
			lualine_y = lualine_y,
			lualine_z = lualine_z,
		},
	}
end

return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function()
			return build_opts()
		end,
		config = function(_, opts)
			require("lualine").setup(opts)

			-- Rebuild the theme when the colorscheme (and so the palette) changes.
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = aug,
				callback = function()
					package.loaded["config.palette"] = nil
					local ok, new_opts = pcall(build_opts)
					if ok then
						require("lualine").setup(new_opts)
					end
				end,
			})
		end,
	},
}
