local dialogs = require("ahoicpp.ui.dialogs")
local project = require("ahoicpp.project")
local utils = require("ahoicpp.utils")
local config = require("ahoicpp.config")

local M = {}

local function create_prompt_dialog(title, prompt_text, callback, start_insert)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = dialogs.create_dialog(title, 60, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, prompt_text)

	if start_insert ~= false then
		vim.cmd("startinsert")
	end

	local function close_and_cleanup()
		pcall(vim.api.nvim_win_close, win, true)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end

	vim.fn.prompt_setcallback(buf, function(input)
		close_and_cleanup()
		if callback then
			callback(input)
		end
	end)

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = close_and_cleanup,
	})

	return buf, win
end

function M.create_main_input()
	local function proceed()
		create_prompt_dialog("AhoiCpp Add Main", "App Name: ", function(input)
			if input and utils.is_valid_class_name(input) then
				project.create_main(input)
			else
				vim.notify("Invalid C++ file/class name provided.", vim.log.levels.WARN)
			end
		end)
	end

	if utils.file_exists("./.ahoicpp") then
		if utils.dir_exists("./App") then
			vim.notify(
				"You appear to have a main app already. Please check your project structure.",
				vim.log.levels.WARN
			)
			return
		end
		proceed()
	else
		local directories = utils.get_directories()
		if #directories > 0 then
			dialogs.create_yes_no_dialog({
				"",
				"This directory contains a few subdirectories, and appear not to be an AhoiCpp project.",
				"Are you sure you want to start a project here?",
				"",
			}, function(confirmed)
				if confirmed then
					proceed()
				end
			end)
		else
			proceed()
		end
	end
end

function M.create_module_input()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.", vim.log.levels.WARN)
		return
	end

	create_prompt_dialog("AhoiCpp Add Module", "Module Name: ", function(input)
		if input and utils.is_valid_class_name(input) then
			project.create_module(input, "Modules")
		else
			vim.notify("Invalid class name provided.", vim.log.levels.WARN)
		end
	end)
end

function M.clone_external()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.", vim.log.levels.WARN)
		return
	end

	create_prompt_dialog("AhoiCpp Clone External from Git", "git clone ", function(input)
		if not input or input == "" then
			vim.notify("Invalid input provided.", vim.log.levels.WARN)
			return
		end

		local function get_repo_name(url)
			local name = url:gsub("%.git$", "")
			name = name:match("([^/]+)$")
			return name
		end

		local repo_name = get_repo_name(input)
		if not repo_name then
			vim.notify("Could not parse repository name from URL.", vim.log.levels.ERROR)
			return
		end

		vim.notify("Starting to clone " .. repo_name .. " from " .. input, vim.log.levels.INFO)
		vim.system({ "git", "clone", input, "externals/" .. repo_name }, {}, function(obj)
			vim.schedule(function()
				if obj.code == 0 then
					vim.notify("Successfully cloned " .. repo_name, vim.log.levels.INFO)
					if config.options.enable_popups then
						local message_lines = {
							"",
							repo_name .. " was successfully cloned from " .. input .. ".",
							"In order to make it available to your classes, you may have to",
							"add other paths to ./AhoiCppExternals.cmake. ",
							"There is also the ./externals/README.md as a resource.",
							"",
							"",
							"                                              Press <ENTER> to close",
						}
						dialogs.create_popup(repo_name .. " cloned", message_lines)
					end
				else
					vim.notify(
						"Failed to clone repository. Check your command, repository, or if you already have it cloned.",
						vim.log.levels.ERROR
					)
				end
			end)
		end)
	end)
end

function M.create_module_directory_input()
	if not utils.file_exists("./.ahoicpp") then
		vim.notify("AhoiCpp is not initialized. Please create an app first.", vim.log.levels.WARN)
		return
	end

	local directory_name = ""
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
		dialogs.create_dialog("AhoiCpp Available Module Directories", width, completion_height, completion_buf)
	local win =
		dialogs.create_dialog("AhoiCpp Add Directory and Module", width, prompt_height, buf, row + completion_height)

	vim.api.nvim_set_option_value("cursorline", true, { win = completion_win })
	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Directory Name: ")
	vim.cmd("startinsert")

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
			pcall(vim.api.nvim_buf_delete, completion_buf, { force = true })
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
				vim.notify("Selected " .. directory_name .. ".")
				local buf2 = vim.api.nvim_create_buf(false, true)
				local win2 = dialogs.create_dialog("AhoiCpp Add Module to " .. directory_name, width, 1, buf2)

				vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf2 })
				vim.fn.prompt_setprompt(buf2, "Module Name: ")

				vim.defer_fn(function()
					vim.cmd("startinsert")
				end, 10)

				vim.fn.prompt_setcallback(buf2, function(input2)
					vim.api.nvim_win_close(win2, true)
					if input2 and input2 ~= "" and utils.is_valid_class_name(input2) then
						project.create_module(input2, directory_name)
					else
						vim.notify("Invalid module name provided.", vim.log.levels.ERROR)
					end
					vim.schedule(function()
						if vim.api.nvim_buf_is_valid(buf2) then
							vim.api.nvim_buf_delete(buf2, { force = true })
						end
					end)
				end)

				vim.api.nvim_create_autocmd("BufLeave", {
					buffer = buf2,
					callback = function()
						if vim.api.nvim_buf_is_valid(buf2) then
							vim.api.nvim_buf_delete(buf2, { force = true })
						end
					end,
				})
			else
				vim.notify("Invalid directory name provided.", vim.log.levels.ERROR)
			end
		end
	end

	vim.keymap.set("i", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(win)
		local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
		local input = line:gsub("^Directory Name: ", "")

		if input == "" then
			local filtered_dirs = vim.api.nvim_buf_get_lines(completion_buf, 0, -1, false)
			if #filtered_dirs > 0 and selected_index <= #filtered_dirs then
				local selected_dir = filtered_dirs[selected_index]
				vim.fn.prompt_setcallback(buf, function(dir_input)
					create_directory_and_proceed_to_module(dir_input)
				end)
				vim.cmd("stopinsert")
				vim.fn.prompt_setcallback(buf, function() end)
				create_directory_and_proceed_to_module(selected_dir)
				return
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

return M
