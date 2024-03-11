vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.4',
        dependencies = { {'nvim-lua/plenary.nvim'} }
    },
    {
        'navarasu/onedark.nvim',
        priority = 1000,
        config = function() 
            vim.cmd.colorscheme('onedark')
        end
    },
    {
        'folke/trouble.nvim',
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
          -- your configuration comes here
          -- or leave it empty to use the default settings
          -- refer to the configuration section below
        },
    },
    {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},             -- Required
            {                                      -- Optional
                'williamboman/mason.nvim',
                run = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            {'williamboman/mason-lspconfig.nvim'}, -- Optional
            -- Autocompletion
            {'hrsh7th/nvim-cmp'},     -- Required
            {'hrsh7th/cmp-nvim-lsp'}, -- Required
            {'L3MON4D3/LuaSnip'},     -- Required

            {'saadparwaiz1/cmp_luasnip'},
            -- Adds a number of user-friendly snippets
            'rafamadriz/friendly-snippets',
        }
    },

    -- Adds git releated signs to the gutter, as well as utilities for managing changes
    { 'lewis6991/gitsigns.nvim' },

    -- Add indentation guides even on blank lines
    { 'lukas-reineke/indent-blankline.nvim' },
    -- "gc" to comment visual regions/lines
    { 'numToStr/Comment.nvim', opts = {} },
    { 'nvim-tree/nvim-tree.lua'},
    { 'm4xshen/autoclose.nvim' },

    -- Useful plugin to show you pending keybinds.
    { 'folke/which-key.nvim', opts = {} },

    {'github/copilot.vim'},
})

-- require('lazy').setup(plugins)
