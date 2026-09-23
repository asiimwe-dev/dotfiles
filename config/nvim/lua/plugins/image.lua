-- ~/.config/nvim/lua/plugins/image.lua
-- Renders images/plots inline via Kitty's graphics protocol — molten.lua's
-- dependency for showing matplotlib/seaborn/etc. output directly in the
-- buffer, not popped out to a separate viewer.
--
-- DELIBERATE CHOICE: image.nvim has two rendering processors —
-- "magick_rock" (an ImageMagick binding compiled via LuaRocks, pinned to
-- Lua 5.1, whose upstream rock is effectively unmaintained — this is the
-- single most common "image.nvim just doesn't work" failure mode reported
-- upstream, version-mismatch build failures and all) and "magick_cli"
-- (shells out to a normal `magick`/`convert` binary — just needs
-- ImageMagick installed like any other CLI tool, no Lua-version-pinned
-- compilation step at all). "magick_cli" is confirmed to already be
-- image.nvim's own default; it's set explicitly here anyway so this stays
-- correct even if that default ever changes, and `build = false` makes
-- sure lazy.nvim never attempts to build the rock in the first place.
return {
	{
		"3rd/image.nvim",
		build = false,
		ft = { "python", "ipynb", "markdown" },
		opts = {
			backend = "kitty",
			processor = "magick_cli",
			integrations = {
				-- Molten drives image display itself; document-integration
				-- auto-rendering (e.g. inline images in markdown just from
				-- opening the file) isn't needed here and is one less thing
				-- to go wrong.
				markdown = { enabled = false },
				neorg = { enabled = false },
				html = { enabled = false },
				css = { enabled = false },
			},
			-- Sizing straight from molten-nvim's own documented sample
			-- config (Not-So-Quick-Start-Guide.md) — the window-percentage
			-- maxes specifically are called out there as important for a
			-- good experience, not arbitrary numbers.
			max_width = 100,
			max_height = 12,
			max_width_window_percentage = math.huge,
			max_height_window_percentage = math.huge,
		},
	},
}
