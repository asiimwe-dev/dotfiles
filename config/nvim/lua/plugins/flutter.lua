-- ~/.config/nvim/lua/plugins/flutter.lua
return {
	{
		"nvim-flutter/flutter-tools.nvim",
		-- FIX: was `lazy = false`, which loaded flutter-tools on every
		-- Neovim startup regardless of project type — pure overhead unless
		-- you're always in a Flutter project. `ft = "dart"` loads it only
		-- when a Dart file is actually opened.
		ft = "dart",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		opts = {
			flutter_path = vim.fn.expand("$HOME/development/flutter/bin/flutter"),
			ui = {
				border = "rounded",
				notification_style = "native",
			},
			decorations = {
				status = {
					app_version = true,
					device = true,
				},
			},
			widget_guides = {
				enabled = true,
			},
			-- Closing tags (VS Code style comment labels like // Container)
			closing_tags = {
				highlight = "Comment",
				prefix = "// ",
				enabled = true,
			},
			-- Color highlight previews in code (e.g. Colors.blue, #FF0000)
			color = {
				enabled = true,
				background = true,
				virtual_text = true,
			},
			-- Integrated Flutter DevTools
			dev_tools = {
				autostart = false, -- set true to auto-open DevTools on run
				auto_open_browser = false,
			},
			lsp = {
				color_capabilities = true,
				settings = {
					showTodos = true,
					completeFunctionCalls = true,
					analysisExcludedFolders = {
						vim.fn.expand("$HOME/.pub-cache"),
					},
					renameFilesWithClasses = "always",
					enableSdkFormatter = true,
					-- auto-fixes missing imports / sorts imports on save
					organizeImportsOnSave = true,
				},
			},
		},
		keys = {
			{ "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "Flutter Run" },
			{ "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Flutter Quit" },
			{ "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Flutter Hot Restart" },
			{ "<leader>Fl", "<cmd>FlutterReload<cr>", desc = "Flutter Hot Reload" },
			{ "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Flutter Devices" },
			{ "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Flutter Emulators" },
			{ "<leader>FL", "<cmd>FlutterLogToggle<cr>", desc = "Toggle Flutter Log" },
			{ "<leader>Ft", "<cmd>FlutterDevTools<cr>", desc = "Open DevTools" },
			{ "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Toggle Flutter Outline Tree" },
		},
	},
}
