vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

require("nvim-treesitter.install").prefer_git = true

require("nvim-treesitter.configs").setup({
	modules = {},
	sync_install = false,
	ignore_install = {},
	ensure_installed = {
		"javascript",
		"typescript",
		"php",
		"c",
		"lua",
		"rust",
		"vim",
		"vimdoc",
		"query",
		"html",
		"yaml",
		"python",
		"svelte",
		"twig",
		"gitcommit",
	},
	auto_install = true, -- auto-install missing parsers (needs `git` + build tools)
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	indent = { enable = true },
})
