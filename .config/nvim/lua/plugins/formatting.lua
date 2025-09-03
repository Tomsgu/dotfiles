vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})

require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		go = { "gofmt" },
		-- twig = { "prettier", "twig-cs-fixer" },
		twig = { "dprint", "twig-cs-fixer" },
		--twig = { "ludtwig" },
		html = { "dprint" },
		php = { "easy-coding-standard" },
		css = { "prettier" },
		scss = { "prettier" },
		markdown = { "prettier" },
		yaml = { "prettier" },
		json = { "prettier" },
		lua = { "stylua" },
		["html.twig"] = { "dprint" },
	},
	format_after_save = {
		lsp_fallback = true,
		async = true,
	},
	formatters = {
		prettier = {
			prepend_args = { "--tab-width", "4" },
		},
		ludtwig = {
			command = "ludtwig",
			args = { "-f", "$FILENAME" },
		},
	},
})
