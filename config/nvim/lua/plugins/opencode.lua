-- ~/.config/nvim/lua/plugins/opencode.lua
local opencode_cmd = "opencode --port"

---@type snacks.terminal.Opts
local terminal_opts = {
	win = {
		position = "right",
		enter = false,
	},
}

return {
	"nickjvandyke/opencode.nvim",
	dependencies = {
		"folke/snacks.nvim",
	},
	config = function()
		-- Auto-reload buffers when OpenCode edits files on disk
		vim.o.autoread = true
		-- opencode.nvim reads vim.g.opencode_opts (no setup() to call)
		---@type opencode.Opts
		vim.g.opencode_opts = {
			server = {
				-- Run the server in a snacks.terminal window so <leader>ot can
				-- show/hide it alongside the floating Ask/Select UIs
				start = function()
					require("snacks.terminal").open(opencode_cmd, terminal_opts)
				end,
			},
		}

		-- Widen the server-discovery probe timeout.
		-- opencode.nvim hardcodes `curl --max-time 2` for every non-persistent
		-- request (lua/opencode/server/init.lua) and retries discovery for only
		-- ~5 seconds, so a cold `opencode --port` boot (Bun runtime + project
		-- load) frequently outlives the probe: the first ask errors with a
		-- timeout notification, then succeeds on the next attempt once the
		-- server is up. There is no plugin config knob for this, so we patch
		-- `server.curl` here in nvim config with the same implementation and a
		-- 10s cap for one-shot (non-persistent) requests; persistent SSE
		-- subscriptions keep no timeout. Applied on plugin load, so it survives
		-- `:Lazy update`.
		--
		-- NOTE: this mirrors upstream `opencode/server/init.lua` — re-check
		-- that file for drift when updating the plugin.
		local server = require("opencode.server")
		server.curl = function(self, path, method, body, on_success, on_error, opts)
			local url = self.url .. path
			opts = opts or { persistent = false }

			local cmd = {
				"curl",
				"-s", -- Silent
				"-S", -- Except for errors/stderr
				"--fail-with-body",
				"-X",
				method,
				"-H",
				"Content-Type: application/json",
				"-H",
				"Accept: application/json",
				"-H",
				"Accept: text/event-stream",
				"-N",
			}

			local username = require("opencode.config").opts.server.username
			local password = require("opencode.config").opts.server.password
			if username and password then
				-- We can always send credentials; servers with no auth set just ignore them
				table.insert(cmd, "--user")
				table.insert(cmd, username .. ":" .. password)
			end

			if not opts.persistent then
				table.insert(cmd, "--max-time")
				table.insert(cmd, 10) -- upstream hardcodes 2 — widened for slow cold boots
			end

			if body then
				table.insert(cmd, "-d")
				table.insert(cmd, vim.fn.json_encode(body))
			end

			table.insert(cmd, url)

			local response_buffer = {}
			local function process_response_buffer()
				if #response_buffer > 0 then
					local full_event = table.concat(response_buffer)
					response_buffer = {}
					vim.schedule(function()
						local ok, result = pcall(vim.fn.json_decode, full_event)
						if ok then
							if on_success then
								on_success(result)
							end
						else
							on_error(
								"Failed to decode response from " .. url .. "\nResponse: " .. full_event .. "\nError: " .. result,
								-1
							)
						end
					end)
				end
			end

			local stderr_lines = {}
			return vim.fn.jobstart(cmd, {
				on_stdout = function(_, data)
					if not data then
						return
					end
					for _, line in ipairs(data) do
						if line == "" and opts.persistent then
							process_response_buffer()
						else
							local clean_line = (line:gsub("^data: ?", ""))
							table.insert(response_buffer, clean_line)
						end
					end
				end,
				on_stderr = function(_, data)
					if data then
						for _, line in ipairs(data) do
							if line ~= "" then
								table.insert(stderr_lines, line)
							end
						end
					end
				end,
				on_exit = function(_, code)
					if code == 0 then
						process_response_buffer()
					else
						local response_message = #response_buffer > 0 and table.concat(response_buffer, "\n") or nil
						local stderr_message = #stderr_lines > 0 and table.concat(stderr_lines, "") or nil
						local status

						local detail_lines = { "Request to " .. url .. " failed with exit code: " .. code }
						if response_message and response_message ~= "" then
							table.insert(detail_lines, "Response:\n" .. response_message)
						end
						if stderr_message and stderr_message ~= "" then
							table.insert(detail_lines, "Stderr:\n" .. stderr_message)
							-- `curl` requires manual parsing of the response code
							status = stderr_message:match("The requested URL returned error: (%d+)$")
							status = tonumber(status)
						end

						on_error(table.concat(detail_lines, "\n"), code, status)
					end
				end,
			})
		end

		-- Show the terminal when a prompt is submitted, so the response is visible
		vim.api.nvim_create_autocmd("User", {
			pattern = { "OpencodeEvent:tui.command.execute" },
			callback = function(args)
				---@type opencode.server.Event
				local event = args.data.event
				if event.properties.command == "prompt.submit" then
					local win = require("snacks.terminal").get(opencode_cmd, { create = false })
					if win then
						win:show()
					end
				end
			end,
		})
	end,
	keys = {
		{
			"<leader>oa",
			function()
				require("opencode").ask("@this: ")
			end,
			mode = { "n", "v" },
			desc = "Ask OpenCode (Context)",
		},
		{
			"<leader>oq",
			function()
				require("opencode").ask()
			end,
			mode = { "n", "v" },
			desc = "Ask OpenCode",
		},
		{
			"<leader>os",
			function()
				require("opencode").select()
			end,
			mode = { "n", "v" },
			desc = "Select OpenCode",
		},
		{
			-- Normal mode only: a <leader> mapping in terminal mode adds input
			-- delay on every leader press while typing (see opencode.nvim README).
			-- From inside the terminal, use <C-\><C-n> first.
			"<leader>ot",
			function()
				require("snacks.terminal").toggle(opencode_cmd, terminal_opts)
			end,
			desc = "Toggle OpenCode Terminal",
		},
		{
			"go",
			function()
				return require("opencode").operator("@this ")
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Append Range to OpenCode",
		},
		{
			"goo",
			function()
				return require("opencode").operator("@this ") .. "_"
			end,
			-- FIX: missing `expr = true`. Without it the returned key sequence
			-- ("g@_") is silently discarded — the mapping was a no-op.
			expr = true,
			desc = "Append Line to OpenCode",
		},
		{
			"<leader>on",
			function()
				require("opencode").command("session.new")
			end,
			desc = "OpenCode New Session",
		},
		{
			"<leader>oi",
			function()
				require("opencode").command("session.interrupt")
			end,
			desc = "OpenCode Interrupt Session",
		},
	},
}
