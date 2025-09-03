vim.g.mapleader = " "

-- Replaced by oil.nvim
-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Moves highlighted block by 1 line.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Joining, but staying on the beginning of the line.
vim.keymap.set("n", "J", "mzJ`z")

-- When searching searched elements are in the middle of the screen
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>p", '"+p')
vim.keymap.set("n", "<leader>P", '"+P')

-- vim.keymap.set("n", "<C-l>", "mzgg=G`z")

-- vim.keymap.set("n", "<C-h>", "<cmd>bprev<CR>", { noremap = true })
vim.keymap.set("n", "<C-y>", "<cmd>bnext<CR>", { noremap = true })

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>k", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "<leader>j", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
