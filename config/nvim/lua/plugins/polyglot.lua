-- ~/.config/nvim/lua/plugins/polyglot.lua
-- Treesitter parsers + Mason-managed LSP server install list.
-- Actual per-server LSP *configuration* (settings, noise reduction, etc.)
-- lives in plugins/lsp.lua — this file only controls what gets installed.
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"dart",
				"java",
				"c",
				"cpp",
				"python",
				"go",
				"rust",
				"javascript",
				"typescript",
				"tsx",
				"html",
				"css",
				"json",
				"yaml",
				"toml",
				"dockerfile",
				"bash",
				"lua",
				"markdown",
				"markdown_inline",
				"sql",
				"php",
				"vue",
				"svelte",
				"scss",
				"graphql",
			},
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
		},
		opts = {
			ensure_installed = {
				"jdtls",
				"clangd",
				-- FIX: "pyright" used to be listed here *in addition to*
				-- basedpyright being explicitly configured in plugins/lsp.lua.
				-- mason-lspconfig auto-enables anything in this list, so both
				-- LSPs were attaching to every Python buffer at once —
				-- duplicate diagnostics, duplicate hover, duplicate
				-- completion. Swapped to basedpyright so only one runs.
				"basedpyright",
				"gopls",
				"rust_analyzer",
				"ts_ls",
				"html",
				"cssls",
				"dockerls",
				"marksman",
				"sqls",
				"intelephense",
			},
		},
	},
}
