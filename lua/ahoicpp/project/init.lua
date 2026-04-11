-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

local fs = require("ahoicpp.project.filesystem")
local templates = require("ahoicpp.templates")
local config = require("ahoicpp.config")

local M = {}

function M.create_class(class_name, output_dir)
	local header_path = output_dir .. "/" .. class_name .. ".h"
	local header_template = templates.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", class_name)
	fs.write_file(header_path, header_template)
	vim.cmd("edit " .. header_path)

	local cpp_path = output_dir .. "/" .. class_name .. ".cpp"
	local cpp_template = templates.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", class_name)
	fs.write_file(cpp_path, cpp_template)
	vim.cmd("edit " .. cpp_path)
end

function M.create_main(main_name)
	local app_path = "./App/src"
	fs.create_dir(app_path)
	fs.create_dir("./externals")
	fs.write_file("./externals/README.md", templates.get_externals_readme())

	local main_path = app_path .. "/" .. main_name .. ".cpp"
	fs.write_file(main_path, templates.get_main_template())
	vim.cmd("edit " .. main_path)

	fs.write_file("./App/version.c.in", templates.get_version_c_in())
	fs.write_file("./App/version.h.in", templates.get_version_h_in())
	fs.write_file("./App/version.rc.in", templates.get_version_rc_in())

	fs.write_file("./.ahoicpp", templates.get_ahoi_template())
	fs.write_file("./.gitignore", templates.get_gitignore())
	fs.write_file("./AhoiCppProject.cmake", "#Created automagically by AhoiCpp. Please do not modify this file.")

	local cmake_template = templates.get_parent_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	fs.write_file("./CMakeLists.txt", cmake_template)

	fs.write_file("./App/AhoiCppSubdirs.cmake", "#Created automagically by AhoiCpp. Please do not modify this file.")

	cmake_template = templates.get_app_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	fs.write_file("./App/CMakeLists.txt", cmake_template)

	fs.write_file("./build.py", templates.get_buildscript())

	if config.options.autocompile_on_create then
		require("ahoicpp.build").compile()
	end
end

function M.create_module(module_name, parent_directory_name)
	local add_to_cmake = false
	if not fs.dir_exists("./" .. parent_directory_name) then
		add_to_cmake = true
	end

	local modules_path = "./" .. parent_directory_name .. "/" .. module_name .. "/include/" .. module_name
	fs.create_dir(modules_path)
	fs.create_dir("./" .. parent_directory_name .. "/" .. module_name .. "/src")

	local cmake_path = "./" .. parent_directory_name .. "/CMakeLists.txt"
	local mode = fs.file_exists(cmake_path) and "a" or "w"
	local file, err = io.open(cmake_path, mode)
	if not file then
		vim.notify("Error opening file: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	file:write("add_subdirectory(" .. module_name .. ")\n")
	file:close()

	cmake_path = "./" .. parent_directory_name .. "/" .. module_name .. "/CMakeLists.txt"
	local cmake_template = templates.get_module_cmake_template()
	cmake_template = cmake_template:gsub("{{MODULE_NAME}}", module_name)
	fs.write_file(cmake_path, cmake_template)

	local header_path = "./"
		.. parent_directory_name
		.. "/"
		.. module_name
		.. "/include/"
		.. module_name
		.. "/"
		.. module_name
		.. ".h"
	local header_template = templates.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", module_name)
	fs.write_file(header_path, header_template)
	vim.cmd("edit " .. header_path)

	local cpp_path = "./" .. parent_directory_name .. "/" .. module_name .. "/src/" .. module_name .. ".cpp"
	local cpp_template = templates.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", module_name)
	fs.write_file(cpp_path, cpp_template)

	if fs.file_exists("./AhoiCppProject.cmake") and add_to_cmake then
		local parent_cmake_file = io.open("./AhoiCppProject.cmake", "r")
		if parent_cmake_file then
			local parent_cmake_text = parent_cmake_file:read("*a")
			if parent_cmake_text then
				parent_cmake_file:close()
				if not string.find(parent_cmake_text, "add_subdirectory(" .. parent_directory_name .. ")", 1, true) then
					parent_cmake_text = parent_cmake_text .. "\nadd_subdirectory(" .. parent_directory_name .. ")"
					fs.update_file("./AhoiCppProject.cmake", parent_cmake_text)
				end
			else
				parent_cmake_file:close()
			end
		end
	end

	if fs.file_exists("./App/AhoiCppSubdirs.cmake") and add_to_cmake then
		local subdirs_file = io.open("./App/AhoiCppSubdirs.cmake", "r")
		if subdirs_file then
			local subdirs_text = subdirs_file:read("*a")
			if subdirs_text then
				subdirs_file:close()
				if
					not string.find(
						subdirs_text,
						"target_link_libraries(${PROJECT_NAME} " .. module_name .. ")",
						1,
						true
					)
				then
					subdirs_text = subdirs_text .. "\ntarget_link_libraries(${PROJECT_NAME} " .. module_name .. ")"
					fs.update_file("./App/AhoiCppSubdirs.cmake", subdirs_text)
				end
			else
				subdirs_file:close()
			end
		end
	end

	vim.cmd("edit " .. cpp_path)

	if config.options.autocompile_on_create then
		require("ahoicpp.build").compile()
	end
end

return M
