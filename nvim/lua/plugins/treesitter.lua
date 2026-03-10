return {
	-- syntax highlighting
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			ensure_installed = { "lua", "javascript", "markdown", "powershell", "python" },
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})

		local treesitter_parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		treesitter_parser_config.powershell = {
			install_info = {
				url = "C:\\Users\\rpb003\\AppData\\Local\\nvim-data\\tree-sitter-powershell-main",
				files = { "src/parser.c", "src/scanner.c" },
				branch = "main",
				generate_requires_npm = false,
				requires_generate_from_grammar = false,
			},
			filetype = "ps1",
		}
	end,
}
