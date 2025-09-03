vim.pack.add({
	{ src = "https://github.com/ccaglak/phptools.nvim" },
	{ src = "https://github.com/ccaglak/namespace.nvim" },
})

require("namespace").setup({
	ui = true,
	cacheOnload = false, -- cache composer.json on load
	dumpOnload = false, -- dump composer.json on load
	sort = {
		on_save = false, -- sorts on every search
		sort_type = "length_desc", -- default: natural -- seam like what pint is sorting
		--  ascending -- descending -- length_asc
		-- length_desc -- natural -- case_insensitive
	},
})

require("phptools").setup({
	ui = {
		enable = true, -- default:true; false only if you have a UI enhancement plugin
		fzf = false, -- default:false; tests requires fzf used only in tests module otherwise there might long list  of tests
	},
	drupal_autoloader = { -- delete if you dont use it
		enable = false, -- default:false
		scan_paths = { "/web/modules/contrib/" }, -- Paths to scan for modules
		root_markers = { ".git" }, -- Project root markers
		autoload_file = "/vendor/composer/autoload_psr4.php", -- Autoload file path
	},
	custom_toggles = { -- delete if you dont use it
		enable = false, -- default:false
		-- { "foo", "bar", "baz" }, -- Add more custom toggle groups here
	},
})

vim.keymap.set("n", "<leader>la", "<cmd>Php classes<cr>")
vim.keymap.set("n", "<leader>lc", "<cmd>Php class<cr>")
vim.keymap.set("n", "<leader>ln", "<cmd>Php namespace<cr>")
vim.keymap.set("n", "<leader>ls", "<cmd>Php sort<cr>")

vim.keymap.set("n", "<leader>lm", "<cmd>PhpTools Method<cr>")
vim.keymap.set("n", "<leader>lc", "<cmd>PhpTools Class<cr>")
vim.keymap.set("n", "<leader>ls", "<cmd>PhpTools Scripts<cr>")
vim.keymap.set("n", "<leader>ln", "<cmd>PhpTools Namespace<cr>")
vim.keymap.set("n", "<leader>lg", "<cmd>PhpTools GetSet<cr>")
vim.keymap.set("n", "<leader>lf", "<cmd>PhpTools Create<cr>")
vim.keymap.set("n", "<leader>ld", "<cmd>PhpTools DrupalAutoLoader<cr>")
vim.keymap.set("v", "<leader>lr", "<cmd>PhpTools Refactor<cr>")
