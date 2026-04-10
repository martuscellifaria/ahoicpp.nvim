-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

-- Main file

local utils = require("ahoicpp.utils")

local function create_dialog(dialog_title, dialog_width, dialog_height, buf, row, col)
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

local M = {}

M.config = {
	autocompile_on_create = true,
	keymaps = {
		group_c = "<leader>c",
		group_cp = "<leader>cp",
		create_app = "<leader>cpa",
		help = "<leader>cph",
		create_module = "<leader>cpm",
		compile = "<leader>cpc",
		create_module_dir = "<leader>cpd",
		clone_external = "<leader>cpe",
		toggle_autocompile = "<leader>cpt",
	},
}

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	M.autocompile_on_create = M.config.autocompile_on_create

	if M.config.keymaps == false then
		return
	end

	local km = M.config.keymaps

	if km.group_c then
		vim.keymap.set("n", km.group_c, "<Nop>", { desc = "+C++" })
	end

	if km.group_cp then
		vim.keymap.set("n", km.group_cp, "<Nop>", { desc = "+AhoiCpp" })
	end

	local function map_if(key, func, desc)
		if key and key ~= false then
			vim.keymap.set("n", key, func, { desc = desc })
		end
	end

	map_if(km.create_app, M.create_main_input, "Create C++ [a]pp")
	map_if(km.help, M.create_about_ahoicpp, "Open Ahoicpp [h]elp")
	map_if(km.create_module, M.create_module_input, "Create C++ [m]odule")
	map_if(km.compile, M.compile_app, "[c]ompile C++ app")
	map_if(km.create_module_dir, M.create_module_directory_input, "Create custom module with [d]irectory")
	map_if(km.clone_external, M.clone_external_from_git, "Clone [e]xternal dependency from Git")
	map_if(km.toggle_autocompile, M.toggle_autocompile, "[t]oggle autocompile app")
end

function M.toggle_autocompile()
	M.autocompile_on_create = not M.autocompile_on_create
	if M.autocompile_on_create then
		vim.notify("Autocompile on create activated", vim.log.levels.INFO)
	else
		vim.notify("Autocompile on create deactivated", vim.log.levels.INFO)
	end
end

function M.create_module_input()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.\n", vim.log.levels.WARN)
		return
	end
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("AhoiCpp Add Module", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Module Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and utils.is_valid_class_name(input) then
			M.create_module(input, "Modules")
		else
			vim.notify("Invalid class name provided.\n", vim.log.levels.WARN)
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

function M.create_module_directory_input()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.\n", vim.log.levels.WARN)
		return
	end

	local directory_name = ""
	local module_name = ""
	local dirs = utils.get_directories()
	local selected_index = 1

	local buf = vim.api.nvim_create_buf(false, true)
	local width = 40
	local completion_height = math.min(10, #dirs + 3)
	if #dirs == 0 then
		completion_height = 1
	end

	local prompt_height = 1
	local height = completion_height + prompt_height
	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2)

	local completion_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(completion_buf, 0, -1, false, dirs)
	vim.api.nvim_set_option_value("modifiable", true, { buf = completion_buf })

	local completion_win =
		create_dialog("AhoiCpp Available Module Directories", width, completion_height, completion_buf)

	local win = create_dialog("AhoiCpp Add Directory and Module", width, prompt_height, buf, row + completion_height)

	vim.api.nvim_set_option_value("cursorline", true, { win = completion_win })
	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Directory Name: ")

	local function update_completion_selection(text)
		local filtered = {}
		for _, dir in ipairs(dirs) do
			if dir:lower():match("^" .. text:lower()) then
				table.insert(filtered, dir)
			end
		end
		vim.api.nvim_buf_set_lines(completion_buf, 0, -1, false, filtered)

		if #filtered > 0 then
			if selected_index > #filtered then
				selected_index = #filtered
			end
			if selected_index < 1 then
				selected_index = 1
			end
			pcall(vim.api.nvim_win_set_cursor, completion_win, { selected_index, 0 })
		end
	end

	vim.keymap.set("i", "<Tab>", function()
		local filtered_dirs = vim.api.nvim_buf_get_lines(completion_buf, 0, -1, false)
		if #filtered_dirs > 0 and selected_index <= #filtered_dirs then
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
			vim.fn.prompt_setprompt(buf, "Directory Name: ")
			vim.api.nvim_feedkeys(filtered_dirs[selected_index], "n", false)
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<End>", true, false, true), "n", false)
		end
	end, { buffer = buf })

	vim.keymap.set("i", "<Up>", function()
		selected_index = math.max(1, selected_index - 1)
		pcall(vim.api.nvim_win_set_cursor, completion_win, { selected_index, 0 })
	end, { buffer = buf })

	vim.keymap.set("i", "<Down>", function()
		local filtered_dirs = vim.api.nvim_buf_get_lines(completion_buf, 0, -1, false)
		selected_index = math.min(#filtered_dirs, selected_index + 1)
		pcall(vim.api.nvim_win_set_cursor, completion_win, { selected_index, 0 })
	end, { buffer = buf })

	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			if lines[1] then
				local prompt_text = lines[1]:gsub("^Directory Name: ", "")
				update_completion_selection(prompt_text)
			end
		end,
	})

	local function create_directory_and_proceed_to_module(input)
		if input ~= "" then
			vim.cmd("stopinsert")
			pcall(vim.api.nvim_win_close, completion_win, true)
			pcall(vim.api.nvim_win_delete, completion_buf, { force = true })
			vim.api.nvim_win_close(win, true)
			directory_name = input
			if
				directory_name
				and utils.is_valid_class_name(directory_name)
				and directory_name ~= "App"
				and directory_name ~= "build"
				and directory_name ~= "externals"
				and not directory_name:match("^%.")
			then
				local buf2 = vim.api.nvim_create_buf(false, true)
				local win2 = create_dialog("AhoiCpp Add Directory and Module", width, 1, buf2)

				vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf2 })
				vim.fn.prompt_setprompt(buf2, "Module Name: ")

				vim.defer_fn(function()
					vim.cmd("startinsert")
				end, 10)
				vim.fn.prompt_setcallback(buf2, function(input2)
					vim.api.nvim_win_close(win2, true)
					module_name = input2
					if module_name and utils.is_valid_class_name(module_name) then
						M.create_module(module_name, directory_name)
					else
						vim.notify("Invalid module name provided.\n", vim.log.levels.ERROR)
					end
					vim.api.nvim_buf_delete(buf2, { force = true })
				end)
			else
				vim.notify("Invalid directory name provided.\n", vim.log.levels.ERROR)
			end
		end
	end

	vim.keymap.set("i", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(win)
		local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
		local input = line:gsub("^Directory Name: ", "")

		if input == "" then
			cursor = vim.api.nvim_win_get_cursor(completion_win)
			line = vim.api.nvim_buf_get_lines(completion_buf, cursor[1] - 1, cursor[1], false)[1]
			if line then
				vim.api.nvim_set_current_win(win)
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
				vim.fn.prompt_setprompt(buf, "Directory Name: ")
				vim.api.nvim_feedkeys(line, "n", false)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<End>", true, false, true), "n", false)
				input = line
			end
		end
		create_directory_and_proceed_to_module(input)
	end, { buffer = buf })
	local group = vim.api.nvim_create_augroup("InputBuffersGroup", { clear = true })
	local related_buffers = { buf, completion_buf }
	local function close_all_related()
		for _, b in ipairs(related_buffers) do
			if vim.api.nvim_buf_is_valid(b) then
				pcall(vim.api.nvim_buf_delete, b, { force = true })
			end
		end
	end
	for _, bufnr in ipairs(related_buffers) do
		vim.api.nvim_create_autocmd("BufLeave", {
			group = group,
			buffer = bufnr,
			callback = close_all_related,
			once = true,
		})
	end

	vim.cmd("startinsert")
end

function M.create_class_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("AhoiCpp Add Class", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Class Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and utils.is_valid_class_name(input) then
			M.create_class(input, ".")
		else
			vim.notify("Invalid class name provided.\n", vim.log.levels.WARN)
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
	local function proceed_with_main_creation()
		local buf = vim.api.nvim_create_buf(false, true)
		local win = create_dialog("AhoiCpp Add Main", 40, 1, buf)

		vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
		vim.fn.prompt_setprompt(buf, "App Name: ")
		vim.cmd("startinsert")

		vim.fn.prompt_setcallback(buf, function(input)
			vim.api.nvim_win_close(win, true)
			if input and utils.is_valid_class_name(input) then
				M.create_main(input)
			else
				vim.notify("Invalid C++ file/class name provided.\n", vim.log.levels.WARN)
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

	if utils.file_exists("./.ahoicpp") then
		if utils.dir_exists("./App") then
			vim.notify(
				"You appear to have a main app already. Please check your project structure.\n",
				vim.log.levels.WARN
			)
			return
		end
		proceed_with_main_creation()
	else
		local directories = utils.get_directories()
		if #directories > 0 then
			M.create_yes_no_dialog({
				"",
				"This directory contains a few subdirectories, and appear not to be an AhoiCpp project.",
				"Are you sure you want to start a project here?",
				"",
			}, function(confirmed)
				if confirmed then
					proceed_with_main_creation()
				elseif confirmed == false then
					return
				else
					return
				end
			end)
		else
			proceed_with_main_creation()
		end
	end
end

function M.clone_external_from_git()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.\n", vim.log.levels.WARN)
		return
	end
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("AhoiCpp Clone External from Git", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "git clone ")
	vim.cmd("startinsert")

	local function get_repo_name(url)
		local name = url:gsub("%.git$", "")
		name = name:match("([^/]+)$")
		return name
	end
	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input then
			local repo_name = get_repo_name(input)
			vim.system({ "git", "clone", input, "externals/" .. repo_name }, {}, function(obj)
				vim.schedule(function()
					if obj.code == 0 then
						vim.notify("Successfully cloned " .. repo_name, vim.log.levels.INFO)
					else
						vim.notify("Failed to clone repository", vim.log.levels.ERROR)
					end
				end)
			end)
		else
			vim.notify("Invalid input provided.\nInput: " .. input .. "\n", vim.log.levels.WARN)
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

	create_dialog("About AhoiCpp", width, height, buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
end

function M.create_yes_no_dialog(message, callback)
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "HelpBuffer",
		callback = function()
			vim.keymap.set("n", "<CR>", ":bd!<CR>", { buffer = true, silent = true })
		end,
	})

	local buf = vim.api.nvim_create_buf(false, true)
	local width = 0
	for _, s in ipairs(message) do
		width = math.max(width, #s)
	end
	local height = #message + 2
	local choice = true
	local win = create_dialog("AhoiCpp Yes/No", width, height, buf)

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
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
end

function M.compile_app()
	local python = ""
	if vim.fn.executable("python") == 1 then
		python = "python"
	elseif vim.fn.executable("python3") == 1 then
		python = "python3"
	else
		vim.notify("Python not found. Stopping.\n", vim.log.levels.WARN)
		return
	end
	if utils.file_exists("build.py") then
		vim.notify("Starting compilation.", vim.log.levels.INFO)
		vim.system({ python, "build.py", "abcde" }, { text = true }, function(obj)
			vim.schedule(function()
				if obj.code == 0 then
					vim.notify("C++ app compilation finished.", vim.log.levels.INFO)
					local clients = vim.lsp.get_clients({ name = "clangd" })
					if #clients > 0 then
						vim.cmd("LspRestart clangd")
					end
				else
					vim.notify("Failed to compile. Please read build.log", vim.log.levels.ERROR)
					vim.cmd("edit ./build/build.log")
				end
			end)
		end)
	else
		vim.notify("build.py not found. Are you sure you have created your app?\n", vim.log.levels.WARN)
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
	utils.create_dir("./externals")
	utils.write_file("./externals/README.md", utils.get_externals_readme())
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
	utils.write_file("./.ahoicpp", utils.get_ahoi_template())
	utils.write_file("./.gitignore", utils.get_gitignore())
	utils.write_file("./AhoiCppProject.cmake", "#Created automagically by AhoiCpp. Please do not modify this file.")
	local cmake_path = "./CMakeLists.txt"
	local cmake_template = utils.get_parent_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	utils.write_file(cmake_path, cmake_template)
	utils.write_file("./App/AhoiCppSubdirs.cmake", "#Created automagically by AhoiCpp. Please do not modify this file.")
	cmake_path = "./App/CMakeLists.txt"
	cmake_template = utils.get_app_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	utils.write_file(cmake_path, cmake_template)
	local build_path = "./build.py"
	local build_template = utils.get_buildscript()
	utils.write_file(build_path, build_template)
	if M.autocompile_on_create then
		M.compile_app()
	end
end

function M.create_module(module_name, parent_directory_name)
	local add_to_cmake = false
	if not utils.dir_exists("./" .. parent_directory_name) then
		add_to_cmake = true
	end
	local modules_path = "./" .. parent_directory_name .. "/" .. module_name .. "/include/" .. module_name
	utils.create_dir(modules_path)
	modules_path = "./" .. parent_directory_name .. "/" .. module_name .. "/src"
	utils.create_dir(modules_path)
	local cmake_path = "./" .. parent_directory_name .. "/CMakeLists.txt"
	local mode = utils.file_exists(cmake_path) and "a" or "w"
	local file, err = io.open(cmake_path, mode)
	if not file then
		error("Error opening file: " .. tostring(err))
	end
	file:write("add_subdirectory(" .. module_name .. ")\n")
	file:close()
	cmake_path = "./" .. parent_directory_name .. "/" .. module_name .. "/CMakeLists.txt"
	local cmake_template = utils.get_module_cmake_template()
	cmake_template = cmake_template:gsub("{{MODULE_NAME}}", module_name)
	utils.write_file(cmake_path, cmake_template)
	local header_path = "./"
		.. parent_directory_name
		.. "/"
		.. module_name
		.. "/include/"
		.. module_name
		.. "/"
		.. module_name
		.. ".h"
	local header_template = utils.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", module_name)
	utils.write_file(header_path, header_template)
	vim.cmd("edit" .. header_path)
	local cpp_path = "./" .. parent_directory_name .. "/" .. module_name .. "/src/" .. module_name .. ".cpp"
	local cpp_template = utils.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", module_name)
	utils.write_file(cpp_path, cpp_template)
	if utils.file_exists("./AhoiCppProject.cmake") and add_to_cmake then
		local parent_cmake_file = io.open("./AhoiCppProject.cmake", "r")
		if parent_cmake_file then
			local parent_cmake_text = parent_cmake_file:read("*a")
			if parent_cmake_text then
				parent_cmake_file:close()
				parent_cmake_text = parent_cmake_text .. "\nadd_subdirectory(" .. parent_directory_name .. ")"
				utils.update_file("./AhoiCppProject.cmake", parent_cmake_text)
			end
		end
	end
	if utils.file_exists("./App/AhoiCppSubdirs.cmake") and add_to_cmake then
		local parent_cmake_file = io.open("./App/AhoiCppSubdirs.cmake", "r")
		if parent_cmake_file then
			local parent_cmake_text = parent_cmake_file:read("*a")
			if parent_cmake_text then
				parent_cmake_file:close()
				parent_cmake_text = parent_cmake_text
					.. "\ntarget_link_libraries(${PROJECT_NAME} "
					.. module_name
					.. ")"
				utils.update_file("./App/AhoiCppSubdirs.cmake", parent_cmake_text)
			end
		end
	end

	vim.cmd("edit" .. cpp_path)
	if M.autocompile_on_create then
		M.compile_app()
	end
end

return M
