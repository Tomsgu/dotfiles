vim.pack.add({
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/folke/todo-comments.nvim" },
	{ src = "https://github.com/folke/ts-comments.nvim" },
})

require("todo-comments").setup({
	opts = {
		signs = false,
	},
})

require("ts-comments").setup({})
