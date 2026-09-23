-- ~/.config/nvim/lua/plugins/jupytext.lua
-- Lets .ipynb files be opened and edited as clean, cell-marked Python
-- (# %% delimiters) instead of a wall of raw JSON — converts on the fly,
-- transparently, on read/write. Requires the `jupytext` CLI on PATH
-- (`pip install jupytext` — see NOTEBOOKS.md), separate from molten's own
-- Python packages.
--
-- CRITICAL, confirmed straight from the plugin's own README: this must
-- NOT be lazy-loaded. If it's loaded lazily (via `ft`/`event`/`cmd`, the
-- pattern every other plugin in this config uses), its BufReadCmd hook can
-- miss the moment a .ipynb file is actually opened, and you see raw JSON
-- instead of the converted view — a documented, common failure mode, not
-- a hypothetical one. `lazy = false` is the plugin author's own stated
-- fix. It's a tiny plugin; the startup cost is negligible.
return {
	{
		"GCBallesteros/jupytext.nvim",
		lazy = false,
		config = true,
	},
}
