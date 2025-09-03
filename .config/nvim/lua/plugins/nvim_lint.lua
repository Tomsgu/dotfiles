vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-lint" },
})

local lint = require("lint")
local uv = vim.uv or vim.loop

-- Which linters to run per filetype
lint.linters_by_ft = {
	php = { "phpstan" },
}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
	callback = function()
		-- try_lint without arguments runs the linters defined in `linters_by_ft`
		-- for the current filetype
		require("lint").try_lint()
	end,
})
