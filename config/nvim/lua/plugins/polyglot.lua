-- ~/.config/nvim/lua/plugins/polyglot.lua
-- Treesitter parsers. LSP servers are declared in plugins/lsp.lua (LazyVim
-- installs them through Mason), formatters in plugins/formatting.lua.
-- LazyVim and the enabled extras already bring bash, c, html, javascript,
-- json, lua, markdown, python, regex, tsx, typescript, xml, yaml, …; only
-- what this setup adds on top is listed here.
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"dart", "java", "kotlin", "groovy", -- JVM + Gradle build files
				"cpp", "rust",
				"css", "scss", "vue", "svelte", "graphql",
				"toml", "dockerfile", "sql", "php",
				"markdown", "markdown_inline",
				"gitcommit", "gitignore", "git_config",
			},
		},
	},
}
