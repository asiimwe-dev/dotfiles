-- ~/.config/nvim/lua/config/discipline.lua
-- "Cowboy" module: nags you if you hold down hjkl / arrow keys more than
-- 5 times in a row without a count prefix, detecting the key and suggesting
-- efficient alternatives (e.g. `w`, `b`, `f`, `{`, `}`, `<C-d>`, `0`, `$`).

local M = {}

-- Contextual suggestions mapped per key
local SUGGESTIONS = {
	h = "Try `b`, `ge`, `0`, `^`, or `f{char}`",
	j = "Try `}`, `<C-d>`, `5j`, or `}`",
	k = "Try `{`, `<C-u>`, `5k`, or `{`",
	l = "Try `w`, `e`, `$`, or `f{char}`",
	["<Up>"] = "Use `k`, `{`, `<C-u>`, or count prefixes",
	["<Down>"] = "Use `j`, `}`, `<C-d>`, or count prefixes",
	["<Left>"] = "Use `h`, `b`, `0`, or `f{char}`",
	["<Right>"] = "Use `l`, `w`, `$`, or `f{char}`",
}

function M.cowboy()
	---@type table?
	local id
	local max_keystrokes = 5

	for _, key in ipairs({ "h", "j", "k", "l", "<Up>", "<Down>", "<Left>", "<Right>" }) do
		local count = 0
		local timer = assert((vim.uv or vim.loop).new_timer())
		local map = key

		vim.keymap.set("n", key, function()
			-- A count-prefixed motion (e.g. `5j`) resets the counter and returns immediately
			if vim.v.count > 0 then
				count = 0
				return map
			end

			if count >= max_keystrokes then
				local suggestion = SUGGESTIONS[key] or "Use text objects or count prefixes!"
				local msg = string.format("Hold it Cowboy! Too much '%s'!\n💡 %s", key, suggestion)

				local ok
				ok, id = pcall(vim.notify, msg, vim.log.levels.WARN, {
					title = "Discipline",
					icon = "🤠",
					replace = id,
					keep = function()
						return count >= max_keystrokes
					end,
				})
				if not ok then
					id = nil
					return map
				end
			else
				count = count + 1
				timer:start(1500, 0, function()
					count = 0
				end)
				return map
			end
		end, { expr = true, silent = true })
	end
end

return M
