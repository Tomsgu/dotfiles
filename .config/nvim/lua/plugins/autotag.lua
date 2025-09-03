vim.pack.add({
	{ src = "https://github.com/windwp/nvim-ts-autotag" },
})

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = false, -- don't auto insert closing tag
		enable_rename = true, -- rename the paired tag as you edit
		enable_close_on_slash = true, -- auto-close on </
	},

	aliases = { ["twig"] = "html" },
})
