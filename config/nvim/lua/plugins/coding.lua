-- ~/.config/nvim/lua/plugins/coding.lua
return {
	-- Disable LazyVim's default mini.pairs (updated repository namespace)
	{ "nvim-mini/mini.pairs", enabled = false },

	-- Auto-close & auto-rename HTML/JSX/XML tags
	{
		"windwp/nvim-ts-autotag",
		event = "LazyFile",
		opts = {},
	},

	-- Auto-pairs for brackets and quotes while typing. This part is
	-- independent of the completion engine — it just pairs (), [], {}, "",
	-- '' as you type, regardless of what's providing completions.
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
			ts_config = {
				lua = { "string" },
				javascript = { "template_string" },
			},
		},
	},

	-- Auto-insert parens after accepting a function completion. The old
	-- nvim-autopairs + nvim-cmp confirm hook was a silent no-op on this
	-- config (it uses blink.cmp, not nvim-cmp). blink.cmp's native
	-- equivalent, driven by LSP semantic tokens, is LazyVim's documented
	-- recommended setting:
	{
		"saghen/blink.cmp",
		opts = {
			completion = {
				accept = {
					auto_brackets = { enabled = true },
				},
			},
		},
	},
}
