function SetColors(color)
	color = color or "onedark"
	vim.cmd.colorscheme(color)
end

SetColors()
