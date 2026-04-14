-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

local M = {}

function M.create_dialog(dialog_title, dialog_width, dialog_height, buf, row, col)
	local width = dialog_width
	local height = dialog_height
	local ui = vim.api.nvim_list_uis()[1]
	row = row or math.floor((ui.height - height) / 2)
	col = col or math.floor((ui.width - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = dialog_title,
		title_pos = "center",
	})
	return win
end

function M.create_yes_no_dialog(message, callback)
	local buf = vim.api.nvim_create_buf(false, true)
	local width = 0
	for _, s in ipairs(message) do
		width = math.max(width, #s)
	end
	local height = #message + 2
	local choice = true
	local win = M.create_dialog("AhoiCpp Yes/No", width, height, buf)

	local function render()
		local lines = {}
		for _, line in ipairs(message) do
			table.insert(lines, line)
		end
		table.insert(lines, "")
		table.insert(lines, string.format(" %s Yes %s No", choice and ">" or " ", choice and " " or ">"))
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	render()

	local function close(result)
		pcall(vim.api.nvim_win_close, win, true)
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		if callback then
			callback(result)
		end
	end

	for _, key in ipairs({ "h", "<Left>", "l", "<Right>" }) do
		vim.keymap.set("n", key, function()
			choice = (key == "h" or key == "<Left>")
			render()
		end, { buffer = buf })
	end

	vim.keymap.set("n", "<CR>", function()
		close(choice)
	end, { buffer = buf })

	vim.keymap.set("n", "<Esc>", function()
		close(nil)
	end, { buffer = buf })
end

function M.create_popup(title, lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, title)

	local width = 0
	for _, s in ipairs(lines) do
		width = math.max(width, #s)
	end

	M.create_dialog(title, width, #lines, buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	vim.keymap.set("n", "<CR>", ":bd!<CR>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", ":bd!<CR>", { buffer = buf, silent = true })
end

function M.create_about()
	local lines = {
		"",
		"AhoiCpp is an A.H.O.I. (Alex's Heavily Opinionated Interfaces)",
		"tool for setting a C++ 23 environment in Neovim.",
		"",
		"C++ is a challenging language, specially for newcomers.",
		"This is my take on making it easier to hop along.",
		"",
		"AhoiCpp can set up classes, cmake files, app entrypoints and",
		"even creates a python script for building your project.",
		"",
		"",
		"                                     Press <ENTER> to close",
	}

	M.create_popup("AhoiCppHelp", lines)
end

return M
