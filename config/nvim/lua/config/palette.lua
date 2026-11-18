-- ~/.config/nvim/lua/config/palette.lua
-- Single source of truth for every hand-picked colour in this config.
-- colorscheme.lua, lualine, incline, dashboard and line_number_hl all read
-- from here, so a palette tweak is one edit instead of six.
local M = {
	-- surfaces
	bg_base = "#02151e", -- deep glass obsidian (statusline, pills, notify fade)
	bg_alt = "#052630", -- subtle container tint

	-- accents
	sky = "#38bdf8",
	green = "#4ade80",
	yellow = "#fbbf24",
	purple = "#c084fc",
	red = "#ff5370",
	teal = "#2dd4bf",
	orange = "#f97316",
	pink = "#f472b6",
	violet = "#a78bfa",

	-- neutrals
	muted = "#586e75",
	slate = "#94a3b8",
	mist = "#cbd5e1",
	text = "#e2e8f0",
	soft = "#f1f5f9",
}

-- Per-mode accents used by line_number_hl (fg = accent, bg = tinted surface).
M.mode = {
	normal = { fg = M.sky, bg = "#0f2d3e" },
	insert = { fg = M.green, bg = "#0e351d" },
	visual = { fg = M.purple, bg = "#2b1440" },
	replace = { fg = M.red, bg = "#3b0f18" },
	command = { fg = M.yellow, bg = "#352506" },
}

-- Blend an accent toward a surface. `amount` is how much of the accent
-- survives (1 = accent, 0 = background), so small values are the faint
-- glassy tints used behind reference highlights.
local function tint(accent, amount, bg)
	bg = bg or M.bg_base
	local a = { tonumber(accent:sub(2, 3), 16), tonumber(accent:sub(4, 5), 16), tonumber(accent:sub(6, 7), 16) }
	local b = { tonumber(bg:sub(2, 3), 16), tonumber(bg:sub(4, 5), 16), tonumber(bg:sub(6, 7), 16) }
	return string.format(
		"#%02x%02x%02x",
		math.floor(b[1] + (a[1] - b[1]) * amount + 0.5),
		math.floor(b[2] + (a[2] - b[2]) * amount + 0.5),
		math.floor(b[3] + (a[3] - b[3]) * amount + 0.5)
	)
end

M.tint = tint

-- Reference highlights: ~14% accent over bg_base (no fill, no underline).
M.ref_text = tint(M.sky, 0.14) -- #0a2d3d
M.ref_read = tint(M.teal, 0.14) -- #083035
M.ref_write = tint(M.red, 0.14) -- #251e29

return M
