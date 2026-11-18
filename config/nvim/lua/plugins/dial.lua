-- ~/.config/nvim/lua/plugins/dial.lua
-- Streamlined dial.nvim: high-frequency daily augends only.

local M = {}

---@param increment boolean
---@param g? boolean
function M.dial(increment, g)
	local mode = vim.fn.mode(true)
	local is_visual = mode == "v" or mode == "V" or mode == "\22"
	local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
	return require("dial.map")[func]("default")
end

local function key(lhs, increment, g, desc)
	return {
		lhs,
		function()
			return M.dial(increment, g)
		end,
		expr = true,
		desc = desc,
		mode = { "n", "v" },
	}
end

return {
	"monaqa/dial.nvim",
	keys = {
		key("<C-a>", true, false, "Increment"),
		key("<C-x>", false, false, "Decrement"),
		key("g<C-a>", true, true, "Increment (g)"),
		key("g<C-x>", false, true, "Decrement (g)"),
	},
	config = function()
		local augend = require("dial.augend")

		require("dial.config").augends:register_group({
			default = {
				-- Numbers
				augend.integer.alias.decimal,
				augend.integer.alias.hex,

				-- Booleans
				augend.constant.alias.bool,
				augend.constant.new({ elements = { "True", "False" }, word = true, cyclic = true }),
				augend.constant.new({ elements = { "yes", "no" }, word = true, cyclic = true }),
				augend.constant.new({ elements = { "on", "off" }, word = true, cyclic = true }),

				-- Logical & syntax
				augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
				augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
				augend.constant.new({ elements = { "let", "const" }, word = true, cyclic = true }),

				-- Dates
				augend.date.alias["%Y-%m-%d"],
				augend.date.alias["%Y/%m/%d"],
				augend.constant.new({
					elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
					word = true,
					cyclic = true,
				}),
			},
		})
	end,
}
