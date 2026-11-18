-- ~/.config/nvim/lua/plugins/web.lua
-- Web-development specifics that sit on top of the LazyVim extras listed in
-- lazyvim.json (lang.typescript + vtsls, lang.vue, lang.tailwind, linting.eslint,
-- formatting.prettier, util.mini-hipatterns, lang.json, lang.yaml).
--
-- Design rule: tooling follows the PROJECT. ESLint and Biome language servers
-- only attach when the project has their config file; formatters are chosen
-- per project in plugins/formatting.lua.
return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- Emmet abbreviations (html/css/scss/less/vue/jsx/tsx). Installed by Mason.
				emmet_language_server = {},

				-- Biome language server. Its lspconfig root_dir only resolves when a
				-- biome.json(c) exists, so it stays completely idle in every other
				-- project (no extra process, no duplicate diagnostics next to ESLint).
				biome = {},

				-- Tailwind projects use @tailwind/@apply/@theme/@source/...; the CSS
				-- server doesn't know them and flags every one. Tailwind's own server
				-- (lang.tailwind extra) validates those instead.
				cssls = {
					settings = {
						css = { lint = { unknownAtRules = "ignore" } },
						scss = { lint = { unknownAtRules = "ignore" } },
						less = { lint = { unknownAtRules = "ignore" } },
					},
				},

				-- Class completion/hover/colour inside helper calls (shadcn-style
				-- cn()/cva()/clsx()/cx()), not just class="..." attributes.
				tailwindcss = {
					settings = {
						tailwindCSS = {
							experimental = {
								classRegex = {
									{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
									{ "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
									{ "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
									{ "clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
								},
							},
						},
					},
				},
			},

			setup = {
				-- ESLint fix-on-save. The lazyvim linting.eslint extra registers its own
				-- "eslint: lsp" formatter, but at this LazyVim version that formatter
				-- routes through conform (LazyVim.lsp.format), which then runs Prettier
				-- instead of asking ESLint for fixes -- i.e. it never applies a fix.
				-- This replaces it with a direct request to the ESLint server. Priority
				-- 200 / non-primary: it runs BEFORE conform, so Prettier gets the last
				-- word on layout. Only active in projects where the ESLint server
				-- attached (i.e. an ESLint config exists). Honors <leader>uf toggles.
				eslint = function()
					LazyVim.format.register({
						name = "eslint: fix",
						priority = 200,
						primary = false,
						sources = function(buf)
							local ret = {}
							for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = "eslint" })) do
								if client:supports_method("textDocument/formatting", buf) then
									table.insert(ret, client.name)
								end
							end
							return ret
						end,
						format = function(buf)
							vim.lsp.buf.format({ bufnr = buf, name = "eslint", timeout_ms = 4000 })
						end,
					})
				end,
			},
		},
	},
}
