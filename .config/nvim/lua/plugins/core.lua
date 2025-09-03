-- Sleuth: auto-detect tabstop/shiftwidth
vim.pack.add({ 
    {src = "https://github.com/tpope/vim-sleuth" },
    { src = "https://github.com/catppuccin/nvim" },
    { src = "https://github.com/m4xshen/autoclose.nvim" },
    -- Tmux navigator
    { src = "https://github.com/christoomey/vim-tmux-navigator" },
    -- Trouble (LSP diagnostics UI)
    { src = "https://github.com/folke/trouble.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" }
})


require("catppuccin").setup({
	flavour = "frappe",
	integrations = {
		treesitter = true,
		cmp = true,
		gitsigns = true,
		telescope = true,
		harpoon = true,
		which_key = true,
	},
})
vim.cmd.colorscheme("catppuccin-frappe")

require("autoclose").setup()

require("trouble").setup({})

vim.keymap.set("n", "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>")
vim.keymap.set("n", "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>")
