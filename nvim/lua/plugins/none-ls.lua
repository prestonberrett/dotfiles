return {
	-- Linters and formatters
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier.with({ filetypes = { "html", "json", "yaml", "markdown" } }),
				require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
				require("none-ls.formatting.ruff_format"),
				null_ls.builtins.formatting.shfmt.with({ args = { "-i", "4" } }),
				null_ls.builtins.formatting.terraform_fmt,
			},
		})

		-- list of formatters & linters for mason to install
		require("mason-null-ls").setup({
			ensure_installed = {
				-- 'checkmake',
				"prettier", -- ts/js formatter
				"eslint_d", -- ts/js linter
				"shfmt",
				'stylua', -- lua formatter; Already installed via Mason
				'ruff', -- Python linter and formatter; Already installed via Mason
			},
			-- auto-install configured formatters & linters (with null-ls)
			automatic_installation = true,
		})

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
