-- ~/.config/nvim/lua/plugins/flash.lua
-- LazyVim's default flash.nvim spec binds bare "s" (normal/visual/operator)
-- to jump. Our config/keymaps.lua defines several "s"-prefixed window
-- commands (ss, sv, sh, sj, sk, sl, sc, sq), which forces Neovim to wait
-- out `timeoutlen` on every bare "s" press to disambiguate — introducing a
-- visible delay on every flash jump. Fix: move flash off "s" entirely so
-- neither feature waits on the other.
return {
	{
		"folke/flash.nvim",
		keys = {
			{ "s", mode = { "n", "x", "o" }, false }, -- disable default, conflicts with window keymaps
			{
				"ns",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash Jump",
			},
		},
	},
}
