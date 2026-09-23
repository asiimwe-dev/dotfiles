local M = {}

local colors = {
	normal = { fg = "#38bdf8", bg = "#0f2d3e" },
	insert = { fg = "#4ade80", bg = "#0e351d" },
	visual = { fg = "#c084fc", bg = "#2b1440" },
	replace = { fg = "#ff5370", bg = "#3b0f18" },
	command = { fg = "#fbbf24", bg = "#352506" },
}

local function mode_key(mode)
	mode = mode or vim.fn.mode(true)
	local first = mode:sub(1, 1)

	if first == "i" or first == "R" or first == "r" then
		if first == "i" then
			return "insert"
		end
		return "replace"
	end

	if first == "v" or first == "V" or first == "\22" then
		return "visual"
	end

	if first == "c" then
		return "command"
	end

	return "normal"
end

function M.apply(mode)
	local style = colors[mode_key(mode)] or colors.normal

	vim.api.nvim_set_hl(0, "LineNr", { fg = style.fg })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = style.fg, bg = style.bg, bold = true })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = style.bg })
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = style.fg })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = style.fg })
end

function M.setup()
	local group = vim.api.nvim_create_augroup("UserLineNumberHighlights", { clear = true })

	vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, {
		group = group,
		callback = function()
			M.apply()
		end,
	})

	M.apply()
end

return M
