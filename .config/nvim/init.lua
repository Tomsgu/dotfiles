vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.clipboard = "unnamedplus"

require("config")

function password_from_pass(key)
	local out = vim.fn.system({ "pass", "show", key })
	if vim.v.shell_error ~= 0 or not out then
		return nil
	end

	local first = vim.split(out, "\n", { plain = true })[1] or ""
	return vim.trim(first)
end

require("plugins.autotag")
require("plugins.core")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.gitsigns")
require("plugins.oil")
--
--require("plugins.trouble")
require("plugins.undotree")
require("plugins.autocompletion")
require("plugins.lsp")
require("plugins.formatting")
require("plugins.nvim_lint")
require("plugins.comments")
-- require("plugins.noice")
-- require("plugins.harpoon")
require("plugins.php")
