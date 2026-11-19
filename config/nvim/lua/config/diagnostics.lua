-- ~/.config/nvim/lua/config/diagnostics.lua
-- Shared inline-diagnostic ("Error Lens") settings.
--
-- Neovim renders one prefix per diagnostic on a line but only the last
-- diagnostic's message. With severity_sort = true the list arrives sorted
-- HINT -> ERROR, so that last diagnostic is the most severe one: on a line
-- with an error and a warning the error is what you read, and the warning is
-- folded into the "+N" counter.
--
-- The virtual text handler allows format() to return nil to drop a diagnostic
-- from the inline display only; signs, undercurls, lualine and the <A-d>
-- float still show it.
local M = {}

local sev = vim.diagnostic.severity

local icons = {
	[sev.ERROR] = vim.fn.nr2char(0xf015a), -- nf-md-alert_circle
	[sev.WARN] = vim.fn.nr2char(0xf0026), -- nf-md-alert
	[sev.INFO] = vim.fn.nr2char(0xf02fc), -- nf-md-information
	[sev.HINT] = vim.fn.nr2char(0xf0335), -- nf-md-lightbulb
}

-- Diagnostics that only restate what the formatter fixes on save. Hidden
-- inline (regardless of severity) but still signed and underlined.
local inline_noise = {
	eslint = { ["prettier/prettier"] = true },
}

local function inline_format(d)
	local deny = inline_noise[d.source or ""]
	if deny and deny[d.code or ""] then
		return nil
	end
	local msg = vim.trim((d.message:gsub("%s*\n%s*", " ")))
	local max = 90
	if vim.fn.strdisplaywidth(msg) > max then
		msg = vim.fn.strcharpart(msg, 0, max - 1) .. "…"
	end
	return msg
end

--- Build a complete virtual_text config for the given minimum severity.
--- `vim.diagnostic.config` replaces the whole table, so the cycle must pass
--- every key again rather than just `severity`.
function M.virtual_text(min)
	return {
		severity = { min = min },
		spacing = 2,
		source = "if_many",
		prefix = function(d, i, total)
			if i ~= total then
				return ""
			end
			local icon = icons[d.severity] or icons[sev.ERROR]
			return total > 1 and string.format("%s +%d", icon, total - 1) or icon
		end,
		format = inline_format,
	}
end

local levels = {
	{ label = "errors + warnings", min = sev.WARN },
	{ label = "errors only", min = sev.ERROR },
	{ label = "everything", min = sev.HINT },
}

local current = 1

--- Cycle the inline verbosity: errors+warnings -> errors only -> everything.
function M.cycle()
	current = current % #levels + 1
	local level = levels[current]
	vim.diagnostic.config({ virtual_text = M.virtual_text(level.min) })
	vim.notify("Inline diagnostics: " .. level.label, vim.log.levels.INFO)
end

return M
