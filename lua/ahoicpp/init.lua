utils = require("ahoicpp.utils")
-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

-- Main file

local function create_dialog(dialog_title, dialog_width, dialog_height, buf)
	local width = dialog_width
	local height = dialog_height
	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

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

local M = {}

function M.setup_ahoicpp()
	vim.keymap.set("n", "<leader>cpp", M.create_class_input, { desc = "Create C++ [c]lass" })
	vim.keymap.set("n", "<leader>cpa", M.create_main_input, { desc = "Create C++ [a]pp" })
	vim.keymap.set("n", "<leader>cph", M.create_about_ahoicpp, { desc = "Open Ahoicpp [h]elp" })
	vim.keymap.set("n", "<leader>cpm", M.create_module_input, { desc = "Create C++ [m]odule" })
	vim.keymap.set("n", "<leader>cpc", M.compile_app, { desc = "[c]ompile C++ app" })
end

function M.create_module_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Module", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Module Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and utils.is_valid_class_name(input) then
			M.create_module(input)
		else
			vim.notify("Invalid class name provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_class_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Class", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Class Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and utils.is_valid_class_name(input) then
			M.create_class(input, ".")
		else
			vim.notify("Invalid class name provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_main_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Main", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "App Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and utils.is_valid_class_name(input) then
			M.create_main(input)
		else
			vim.notify("Invalid C++ file/class name provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_about_ahoicpp()
	local lines = {
		"",
		"Ahoi C++ is an A.H.O.I. (Alex's Heavily Opinionated Interfaces)",
		"tool for setting a C++ 23 environment in NeoVim.",
		"",
		"C++ is a terrible language, but it pays my bills since 2016.",
		"This is my take on making it not so disfunctional.",
		"",
		"Ahoi C++ can set up classes, cmake files, app entrypoints and",
		"even creates a python script for building your project.",
		"",
		"",
		"                                     Press <ENTER> to close",
	}

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "HelpBuffer",
		callback = function()
			vim.keymap.set("n", "<CR>", ":bd!<CR>", { buffer = true, silent = true })
		end,
	})

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "HelpBuffer")

	local width = 0
	for _, s in ipairs(lines) do
		width = math.max(width, #s)
	end
	local height = #lines

	create_dialog("Ahoi C++ Add Main", width, height, buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
end

function M.compile_app()
	if utils.file_exists("build.py") then
		vim.notify("Starting compilation.")
		vim.fn.jobstart({ "python", "build.py", "abcde" }, {
			on_exit = function(_, code)
				if code == 0 then
					vim.notify("C++ app compilation finished.")
				else
					vim.notify("Failed to compile. Please read build.log")
					vim.cmd("edit" .. "./build/build.log")
				end
			end,
		})
	else
		vim.notify("build.py not found.")
	end
end

function M.create_class(class_name, output_dir)
	local header_path = output_dir .. "/" .. class_name .. ".h"
	local header_template = utils.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", class_name)
	utils.write_file(header_path, header_template)
	vim.cmd("edit" .. header_path)
	local cpp_path = output_dir .. "/" .. class_name .. ".cpp"
	local cpp_template = utils.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", class_name)
	utils.write_file(cpp_path, cpp_template)
	vim.cmd("edit" .. cpp_path)
end

function M.create_main(main_name)
	local app_path = "./App/src"
	utils.create_dir(app_path)
	local main_path = app_path .. "/" .. main_name .. ".cpp"
	local main_template = utils.get_main_template()
	utils.write_file(main_path, main_template)
	vim.cmd("edit" .. main_path)
	app_path = "./App"
	local version_path = app_path .. "/version.c.in"
	local version_template = utils.get_version_c_in()
	utils.write_file(version_path, version_template)
	version_path = app_path .. "/version.h.in"
	version_template = utils.get_version_h_in()
	utils.write_file(version_path, version_template)
	version_path = app_path .. "/version.rc.in"
	version_template = utils.get_version_rc_in()
	utils.write_file(version_path, version_template)
	local cmake_path = "./CMakeLists.txt"
	local cmake_template = utils.get_parent_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	utils.write_file(cmake_path, cmake_template)
	cmake_path = "./App/CMakeLists.txt"
	cmake_template = utils.get_app_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	utils.write_file(cmake_path, cmake_template)
	local build_path = "./build.py"
	local build_template = utils.get_buildscript()
	utils.write_file(build_path, build_template)
end

function M.create_module(module_name)
	local modules_path = "./Modules/" .. module_name .. "/include/" .. module_name
	utils.create_dir(modules_path)
	modules_path = "./Modules/" .. module_name .. "/src"
	utils.create_dir(modules_path)
	local cmake_path = "./Modules/CMakeLists.txt"
	local mode = utils.file_exists(cmake_path) and "a" or "w"
	local file, err = io.open(cmake_path, mode)
	if not file then
		error("Error opening file: " .. tostring(err))
	end
	file:write("add_subdirectory(" .. module_name .. ")\n")
	file:close()
	cmake_path = "./Modules/" .. module_name .. "/CMakeLists.txt"
	local cmake_template = utils.get_module_cmake_template()
	cmake_template = cmake_template:gsub("{{MODULE_NAME}}", module_name)
	utils.write_file(cmake_path, cmake_template)
	local header_path = "./Modules/" .. module_name .. "/include/" .. module_name .. "/" .. module_name .. ".h"
	local header_template = utils.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", module_name)
	utils.write_file(header_path, header_template)
	vim.cmd("edit" .. header_path)
	local cpp_path = "./Modules/" .. module_name .. "/src/" .. module_name .. ".cpp"
	local cpp_template = utils.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", module_name)
	utils.write_file(cpp_path, cpp_template)
	vim.cmd("edit" .. cpp_path)
end

M.setup_ahoicpp()
return M
