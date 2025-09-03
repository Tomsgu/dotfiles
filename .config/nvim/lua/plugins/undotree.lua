vim.pack.add({
	{ src = "https://github.com/jiaoshijie/undotree" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
})

require("undotree").setup({
	float_diff = true, -- use floating window for diffs
	layout = "left_bottom", -- window layout
	position = "right", -- panel position
})

vim.keymap.set("n", "<leader>u", function()
	require("undotree").toggle()
end, { desc = "Toggle UndoTree" })
