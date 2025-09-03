vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
})

require("oil").setup({
	columns = { "icon" },
	keymaps = {
		["<C-h>"] = false,
		["<C-l>"] = false,
		["<M-h>"] = "action.select_split",
		["<M-l>"] = "action.refresh",
	},
	view_options = {
		show_hidden = true,
	}
})

-- Open parent directory in current window
vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Open parent directory in floating window
vim.keymap.set("n", "<leader>-", require("oil").toggle_float)
