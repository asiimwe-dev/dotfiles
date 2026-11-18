-- ~/.config/nvim/lua/config/line_number_hl.lua
-- Mode-aware cursor-line highlighting. Colours come from config/palette.lua.
local P = require("config.palette")

local M = {
	-- true: only the current line number glows with the mode colour and the
	-- rest stay dim (calmer). false: every line number takes the mode colour.
	dim_numbers = true,
}

---@type string?
local last_key = nil

local function mode_key(mode)
	mode = mode or vim.fn.mode(true)
	local first = mode:sub(1, 1)
	if first == "i" then
		return "insert"
	elseif first == "R" then
		return "replace"
	elseif first == "v" or first == "V" or first == "\22" or first == "s" or first == "S" or first == "\19" then
		return "visual"
	elseif first == "c" then
		return "command"
	end
	return "normal" -- n, no (operator-pending), t, prompts
end

--- Apply the highlights for `mode`. No-op unless the mode *category* changed
--- (ModeChanged fires for every operator-pending step), unless `force`.
function M.apply(mode, force)
	local key = mode_key(mode)
	if not force and key == last_key then
		return
	end
	last_key = key

	local style = P.mode[key]
	local number_fg = M.dim_numbers and P.muted or style.fg

	vim.api.nvim_set_hl(0, "LineNr", { fg = number_fg })
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = number_fg })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = number_fg })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = style.fg, bg = style.bg, bold = true })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = style.bg })
end

function M.setup()
	local group = vim.api.nvim_create_augroup("UserLineNumberHighlights", { clear = true })

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function()
			M.apply(vim.v.event and vim.v.event.new_mode or nil)
		end,
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			M.apply(nil, true)
		end,
	})

	M.apply(nil, true)
end

return M
