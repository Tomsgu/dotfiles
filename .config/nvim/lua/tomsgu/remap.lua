vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- vim.keymap.set("n", "<C-7>", "<C-6>", {noremap = true})
-- vim.keymap.set("n", "<C-&>", "<C-6>", {noremap = true})

-- Moves highlighted block by 1 line.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Joining, but staying on the beginning of the line.
vim.keymap.set("n", "J", "mzJ`z")

-- When searching searched elements are in the middle of the screen
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("n", "<leader>p", "\"+p")
vim.keymap.set("v", "<leader>p", "\"+p")
vim.keymap.set("n", "<leader>P", "\"+P")

-- vim.keymap.set("n", "<C-l>", "mzgg=G`z")

vim.keymap.set("n", "<C-h>", "<cmd>bprev<CR>", {noremap = true})
vim.keymap.set("n", "<C-y>", "<cmd>bnext<CR>", {noremap = true})

-- [[ Highlight on yank ]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})
