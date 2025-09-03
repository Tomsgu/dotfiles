--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.guicursor = ""
vim.opt.winborder = "rounded"
vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#8caaee" })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#8caaee" })

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- autosave when loosing focus on file.
vim.opt.autowriteall = true

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Set an 80 char vertical line
vim.opt.colorcolumn = "80"

vim.opt.spell = true
vim.opt.spelllang = "en_us"

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- Set a window title depending on the file.
vim.opt.title = true
