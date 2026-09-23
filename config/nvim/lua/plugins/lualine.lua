-- lua/plugins/lualine.lua
return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			-- ─────────────────────────────────────────────────────────────
			-- VIBRANT HIGH-LUMINANCE GLASSY PALETTE
			-- ─────────────────────────────────────────────────────────────
			local bg_base = "#02151e" -- Deep glass obsidian background
			local bg_alt = "#052630" -- Subtle container tint

			-- High-saturation, distinct functional tokens
			local colors = {
				sky = "#38bdf8", -- Primary / Info / Default Branch / Copilot
				green = "#4ade80", -- Insert Mode / Feature Branches / Codeium / Additions
				yellow = "#fbbf24", -- Command Mode / Hotfix Branches / Warnings / Venv / Progress
				purple = "#c084fc", -- Visual Mode / LSP Active Status
				red = "#ff5370", -- Replace Mode / Production Branch / Errors / File Size / Recording
				teal = "#2dd4bf", -- Filenames / Dev Branches / Formatters / Cursor Position
				orange = "#f97316", -- Indentation & Encoding metadata
				muted = "#586e75", -- Inactive elements / Secondary labels
				text = "#e2e8f0", -- High contrast crisp text
			}

			-- ─────────────────────────────────────────────────────────────
			-- Refresh helpers
			-- ─────────────────────────────────────────────────────────────
			local function refresh_statusline()
				require("lualine").refresh({ place = { "statusline" } })
			end

			local function force_git_and_statusline_refresh()
				vim.schedule(function()
					if package.loaded["gitsigns"] then
						pcall(require("gitsigns").refresh)
						local buf = vim.api.nvim_get_current_buf()
						if vim.api.nvim_buf_is_valid(buf) then
							pcall(require("gitsigns").attach, buf)
						end
					end
					refresh_statusline()
				end)
			end

			vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
				callback = refresh_statusline,
			})

			vim.api.nvim_create_autocmd({
				"TermClose",
				"TermLeave",
				"WinClosed",
				"FocusGained",
				"BufEnter",
				"BufWinEnter",
			}, {
				callback = force_git_and_statusline_refresh,
			})

			-- ─────────────────────────────────────────────────────────────
			-- Cached helpers (Performance Optimized)
			-- ─────────────────────────────────────────────────────────────
			local uv = vim.uv or vim.loop

			local file_size_cache = { path = "", size = "", last = 0 }
			local function file_size()
				local file = vim.fn.expand("%:p")
				if file == "" then
					return ""
				end

				local now = uv.now()
				if file == file_size_cache.path and now - file_size_cache.last < 500 then
					return file_size_cache.size
				end

				local size = vim.fn.getfsize(file)
				local formatted = ""
				if type(size) == "number" and size > 1024 * 1024 then
					formatted = string.format("%.1fMB", size / (1024 * 1024))
				end

				file_size_cache.path = file
				file_size_cache.size = formatted
				file_size_cache.last = now
				return formatted
			end

			local live_server_ok, live_server = pcall(require, "live_server")
			local function live_server_status()
				if not live_server_ok then
					return ""
				end
				local status = live_server.statusline()
				return status ~= "" and ("󰈙 " .. status) or ""
			end

			-- Window width conditioner (hides components on small splits)
			local function wide_enough()
				return vim.fn.winwidth(0) > 90
			end

			-- ─────────────────────────────────────────────────────────────
			-- AI Engine Definitions
			-- ─────────────────────────────────────────────────────────────
			local ai_icons = { copilot = "", neocodeium = "󰚩" }
			local ai_labels = { copilot = "Copilot", neocodeium = "Codeium" }
			local ai_colors = {
				copilot = { fg = colors.sky, gui = "bold" },
				neocodeium = { fg = colors.green, gui = "bold" },
			}

			local function get_ai_status()
				return _G.AICompletion and _G.AICompletion.status() or "none"
			end

			local function ai_engine_display()
				local eng = get_ai_status()
				if eng == "none" or eng == "" then
					return ""
				end
				return (ai_icons[eng] or "") .. " " .. (ai_labels[eng] or eng)
			end

			local function ai_engine_color()
				local eng = get_ai_status()
				return ai_colors[eng] or { fg = colors.muted }
			end

			-- ─────────────────────────────────────────────────────────────
			-- High-Luminance Theme Matrix
			-- ─────────────────────────────────────────────────────────────
			local vibrant_glassy = {
				normal = {
					a = { fg = bg_base, bg = colors.sky, gui = "bold" },
					b = { fg = colors.sky, bg = bg_alt, gui = "bold" },
					c = { fg = colors.text, bg = bg_base },
					x = { fg = colors.text, bg = bg_base },
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
				inactive = {
					a = { fg = colors.muted, bg = bg_alt },
					b = { fg = colors.muted, bg = bg_alt },
					c = { fg = colors.muted, bg = bg_base },
					x = { fg = colors.muted, bg = bg_base },
					y = { fg = colors.muted, bg = bg_alt },
					z = { fg = colors.muted, bg = bg_alt },
				},
			}

			-- ─────────────────────────────────────────────────────────────
			-- Setup Execution
			-- ─────────────────────────────────────────────────────────────
			require("lualine").setup({
				options = {
					theme = vibrant_glassy,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					globalstatus = true,
					disabled_filetypes = { statusline = { "dashboard", "alpha", "snacks_dashboard" } },
				},
				sections = {
					lualine_a = {
						{
							"mode",
							icon = "",
							separator = { left = "", right = "" },
							padding = { left = 1, right = 1 },
						},
					},
					lualine_b = {
						{
							"branch",
							icon = "",
							source = function()
								local dict = vim.b.gitsigns_status_dict
								local head = (dict and dict.head) or vim.b.gitsigns_head
								if head and head ~= "" then
									return head
								end

								local ok, git_branch = pcall(require, "lualine.components.branch.git_branch")
								if ok then
									return git_branch.get_branch()
								end
								return ""
							end,
							color = function()
								local dict = vim.b.gitsigns_status_dict
								local branch = (dict and dict.head) or vim.b.gitsigns_head or ""

								if branch == "" then
									local ok, git_branch = pcall(require, "lualine.components.branch.git_branch")
									if ok then
										branch = git_branch.get_branch() or ""
									end
								end

								if branch == "main" or branch == "master" or branch == "prod" then
									return { fg = colors.red, bg = bg_alt, gui = "bold" }
								elseif branch:find("^feat") or branch:find("feature") then
									return { fg = colors.green, bg = bg_alt, gui = "bold" }
								elseif branch:find("^fix") or branch:find("bug") or branch:find("^hotfix") then
									return { fg = colors.yellow, bg = bg_alt, gui = "bold" }
								elseif branch:find("^dev") or branch:find("staging") then
									return { fg = colors.teal, bg = bg_alt, gui = "bold" }
								end
								return { fg = colors.sky, bg = bg_alt, gui = "bold" }
							end,
						},
						{
							"diff",
							symbols = { added = " ", modified = " ", removed = " " },
							colored = true,
							diff_color = {
								added = { fg = colors.green, gui = "bold" },
								modified = { fg = colors.yellow, gui = "bold" },
								removed = { fg = colors.red, gui = "bold" },
							},
						},
					},
					lualine_c = {
						{
							"filename",
							file_status = true,
							newfile_status = true,
							path = 1,
							symbols = {
								modified = " 󰏫",
								readonly = " 󰌾",
								unnamed = " 󰏬 No Name",
								newfile = " 󰎔 New",
							},
							color = { fg = colors.teal, gui = "bold" },
						},
						{
							"diagnostics",
							symbols = { error = "󰅚 ", warn = "󰀦 ", info = "󰋼 ", hint = "󰌵 " },
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
								return "󰑋 REC @" .. vim.fn.reg_recording()
							end,
							cond = function()
								return vim.fn.reg_recording() ~= ""
							end,
							color = { fg = bg_base, bg = colors.red, gui = "bold" },
							separator = { left = "", right = "" },
						},
						-- Active Python / Virtual Environment (Vibrant Yellow)
						{
							function()
								local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_DEFAULT_ENV")
								if venv then
									return " " .. vim.fn.fnamemodify(venv, ":t")
								end
								return ""
							end,
							cond = wide_enough,
							color = { fg = colors.yellow, gui = "bold" },
						},
						-- Active Formatter status via Conform (Vibrant Teal)
						{
							function()
								local ok, conform = pcall(require, "conform")
								if not ok then
									return ""
								end
								local formatters = conform.list_formatters(0)
								if #formatters > 0 then
									return "󰉁 " .. formatters[1].name
								end
								return ""
							end,
							cond = wide_enough,
							color = { fg = colors.teal, gui = "bold" },
						},
						{
							live_server_status,
							color = { fg = colors.sky, gui = "bold" },
						},
						{
							ai_engine_display,
							color = ai_engine_color,
						},
						{
							"searchcount",
							icon = "󰍉",
							cond = wide_enough,
							color = { fg = colors.yellow, gui = "bold" },
						},
						{
							file_size,
							icon = "󰉋",
							cond = function()
								return wide_enough() and file_size() ~= ""
							end,
							color = { fg = colors.red, gui = "bold" },
						},
						{
							"lsp_status",
							icon = "",
							symbols = {
								spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
								done = "✓",
								separator = " ",
							},
							ignore_lsp = { "copilot" },
							color = function()
								local clients = vim.lsp.get_clients({ bufnr = 0 })
								local real_clients = vim.tbl_filter(function(c)
									return c.name ~= "copilot"
								end, clients)
								return #real_clients == 0 and { fg = colors.muted }
									or { fg = colors.purple, gui = "bold" }
							end,
						},
					},
					lualine_y = {
						-- Indentation Type & Size (Vibrant Orange)
						{
							function()
								local space = vim.bo.expandtab and "Spaces" or "Tabs"
								local size = vim.bo.shiftwidth == 0 and vim.bo.tabstop or vim.bo.shiftwidth
								return string.format("󰌒 %s:%d", space, size)
							end,
							cond = wide_enough,
							color = { fg = colors.orange, bg = bg_alt, gui = "bold" },
						},
						-- Encoding Metadata (Vibrant Sky Blue)
						{
							function()
								local enc = vim.bo.fileencoding
								return enc ~= "" and enc:upper() or "UTF-8"
							end,
							cond = wide_enough,
							color = { fg = colors.sky, bg = bg_alt, gui = "bold" },
						},
						{
							"progress",
							icon = "󰆤",
							color = { fg = colors.yellow, bg = bg_alt, gui = "bold" },
						},
						{
							function()
								local cur = vim.api.nvim_win_get_cursor(0)
								local total_lines = vim.api.nvim_buf_line_count(0)
								return string.format("󰍎 %d:%d 󰦨 %d", cur[1], cur[2] + 1, total_lines)
							end,
							color = { fg = colors.teal, bg = bg_alt, gui = "bold" },
						},
					},
					lualine_z = {
						{
							function()
								return os.date("%H:%M")
							end,
							icon = "",
							separator = { left = "", right = "" },
							padding = { left = 1, right = 1 },
						},
					},
				},
			})
		end,
	},
}
