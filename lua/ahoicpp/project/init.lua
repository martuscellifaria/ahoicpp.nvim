local fs = require("ahoicpp.utils")
local templates = require("ahoicpp.templates")
local config = require("ahoicpp.config")

local M = {}

function M.create_class(class_name, output_dir)
	local sep = package.config:sub(1, 1)
	local header_path = output_dir .. sep .. class_name .. ".h"
	local header_template = templates.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", class_name)
	local ok = fs.write_file(header_path, header_template)
	if ok then
		vim.cmd("edit " .. header_path)
	end

	local cpp_path = output_dir .. sep .. class_name .. ".cpp"
	local cpp_template = templates.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", class_name)
	ok = fs.write_file(cpp_path, cpp_template)
	if ok then
		vim.cmd("edit " .. cpp_path)
	end
end

function M.create_main(main_name)
	local sep = package.config:sub(1, 1)
	local app_path = "." .. sep .. "App" .. sep .. "src"
	fs.create_dir(app_path)
	fs.create_dir("." .. sep .. "externals")
	fs.create_dir("." .. sep .. ".fetchers")
	fs.write_file("." .. sep .. "externals" .. sep .. "README.md", templates.get_externals_readme())
	local readme_template = templates.get_readme_template()
	readme_template = readme_template:gsub("{{PROJECT_NAME}}", main_name)
	fs.write_file("." .. sep .. "README.md", readme_template)

	local fetcher_template = templates.get_libpqxx_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "libpqxx_fetcher.py", fetcher_template)
	fetcher_template = templates.get_opencv_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "opencv_fetcher.py", fetcher_template)
	fetcher_template = templates.get_curl_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "curl_fetcher.py", fetcher_template)
	fetcher_template = templates.get_botan_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "botan_fetcher.py", fetcher_template)
	fetcher_template = templates.get_eigen_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "eigen_fetcher.py", fetcher_template)
	fetcher_template = templates.get_grpc_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "grpc_fetcher.py", fetcher_template)
	fetcher_template = templates.get_protobuf_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "protobuf_fetcher.py", fetcher_template)
	fetcher_template = templates.get_spdlog_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "spdlog_fetcher.py", fetcher_template)
	fetcher_template = templates.get_open62541_fetcher()
	fs.write_file("." .. sep .. ".fetchers" .. sep .. "open62541_fetcher.py", fetcher_template)

	local project_json_template = templates.get_project_json_template()
	project_json_template = project_json_template:gsub("{{PROJECT_NAME}}", main_name)
	project_json_template = project_json_template:gsub("{{SEP}}", sep)
	fs.write_file("." .. sep .. "ahoicpp_project.json", project_json_template)

	local cpp_version = config.options.cpp_version
	if not vim.list_contains(config.cpp_supported_versions, cpp_version) then
		vim.notify("Version " .. cpp_version .. " does not exist. Defaulting to C++ 23.", vim.log.levels.WARN)
		cpp_version = 23
	end
	local main_path = app_path .. sep .. main_name .. ".cpp"
	fs.write_file(main_path, templates.get_main_template(cpp_version))
	vim.cmd("edit " .. main_path)

	fs.write_file("." .. sep .. "App" .. sep .. "version.c.in", templates.get_version_c_in())
	fs.write_file("." .. sep .. "App" .. sep .. "version.h.in", templates.get_version_h_in())
	fs.write_file("." .. sep .. "App" .. sep .. "version.rc.in", templates.get_version_rc_in())

	fs.write_file("." .. sep .. ".gitignore", templates.get_gitignore())
	fs.write_file(
		"." .. sep .. "AhoiCppProject.cmake",
		"#Created automagically by AhoiCpp. Please do not modify this file."
	)

	local cmake_template = templates.get_parent_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	fs.write_file("." .. sep .. "CMakeLists.txt", cmake_template)

	fs.write_file(
		"." .. sep .. "App" .. sep .. "AhoiCppSubdirs.cmake",
		"#Created automagically by AhoiCpp. Please do not modify this file."
	)
	fs.write_file("." .. sep .. "AhoiCppExternals.cmake", templates.get_ahoi_externals_template())

	cmake_template = templates.get_app_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	cmake_template = cmake_template:gsub("{{CPP_VERSION}}", cpp_version)
	fs.write_file("." .. sep .. "App" .. sep .. "CMakeLists.txt", cmake_template)

	fs.write_file("." .. sep .. "build.py", templates.get_buildscript())

	if config.options.autocompile_on_create then
		require("ahoicpp.build").compile()
	end

	if config.options.git_init then
		vim.system({ "git", "init" }, {}, function(obj)
			vim.schedule(function()
				if obj.code == 0 then
					vim.system({ "git", "symbolic-ref", "HEAD", "refs/heads/main" }, {}, function(obj2)
						vim.schedule(function()
							if obj2.code == 0 then
								vim.notify(
									"Successfully started a git repository at the root directory.",
									vim.log.levels.INFO
								)
							else
								vim.system({ "git", "branch", "-m", "master", "main" }, {}, function(obj3)
									vim.schedule(function()
										vim.notify(
											"Successfully started a git repository at the root directory.",
											vim.log.levels.INFO
										)
									end)
								end)
							end
						end)
					end)
				else
					vim.notify("Failed to start repository. Do you have git installed?", vim.log.levels.ERROR)
				end
			end)
		end)
	end
end
function M.create_module(module_name, parent_directory_name)
	local sep = package.config:sub(1, 1)

	if not fs.dir_exists("." .. sep .. parent_directory_name) then
		fs.create_dir("." .. sep .. parent_directory_name)
	end

	local modules_path = "."
		.. sep
		.. parent_directory_name
		.. sep
		.. module_name
		.. sep
		.. "include"
		.. sep
		.. module_name
	fs.create_dir(modules_path)
	fs.create_dir("." .. sep .. parent_directory_name .. sep .. module_name .. sep .. "src")

	local cmake_path = "." .. sep .. parent_directory_name .. sep .. "CMakeLists.txt"
	local parent_cmake_content = fs.read_file(cmake_path) or ""
	if not string.find(parent_cmake_content, "add_subdirectory(" .. module_name .. ")", 1, true) then
		fs.append_file(cmake_path, "add_subdirectory(" .. module_name .. ")\n")
	end

	cmake_path = "." .. sep .. parent_directory_name .. sep .. module_name .. sep .. "CMakeLists.txt"
	local cpp_version = config.options.cpp_version
	if not vim.list_contains(config.cpp_supported_versions, cpp_version) then
		vim.notify("Version " .. cpp_version .. " does not exist. Defaulting to C++ 23.", vim.log.levels.WARN)
		cpp_version = 23
	end
	local cmake_template = templates.get_module_cmake_template()
	cmake_template = cmake_template:gsub("{{MODULE_NAME}}", module_name)
	cmake_template = cmake_template:gsub("{{CPP_VERSION}}", cpp_version)
	fs.write_file(cmake_path, cmake_template)

	local header_path = "."
		.. sep
		.. parent_directory_name
		.. sep
		.. module_name
		.. sep
		.. "include"
		.. sep
		.. module_name
		.. sep
		.. module_name
		.. ".h"
	local header_template = templates.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", module_name)
	local ok = fs.write_file(header_path, header_template)
	if ok then
		vim.cmd("edit " .. header_path)
	end

	local cpp_path = "."
		.. sep
		.. parent_directory_name
		.. sep
		.. module_name
		.. sep
		.. "src"
		.. sep
		.. module_name
		.. ".cpp"
	local cpp_template = templates.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", module_name)
	ok = fs.write_file(cpp_path, cpp_template)
	if ok then
		vim.cmd("edit " .. cpp_path)
	end

	if fs.file_exists("." .. sep .. "AhoiCppProject.cmake") then
		local parent_cmake_text = fs.read_file("." .. sep .. "AhoiCppProject.cmake")
		if parent_cmake_text then
			if not string.find(parent_cmake_text, "add_subdirectory(" .. parent_directory_name .. ")", 1, true) then
				parent_cmake_text = parent_cmake_text .. "\nadd_subdirectory(" .. parent_directory_name .. ")"
				fs.update_file("." .. sep .. "AhoiCppProject.cmake", parent_cmake_text)
			end
		end
	end

	if fs.file_exists("." .. sep .. "App" .. sep .. "AhoiCppSubdirs.cmake") then
		local subdirs_text = fs.read_file("." .. sep .. "App" .. sep .. "AhoiCppSubdirs.cmake")
		if subdirs_text then
			if
				not string.find(subdirs_text, "target_link_libraries(${PROJECT_NAME} " .. module_name .. ")", 1, true)
			then
				subdirs_text = subdirs_text .. "\ntarget_link_libraries(${PROJECT_NAME} " .. module_name .. ")"
				fs.update_file("." .. sep .. "App" .. sep .. "AhoiCppSubdirs.cmake", subdirs_text)
			end
		end
	end

	if config.options.autocompile_on_create then
		vim.defer_fn(function()
			require("ahoicpp.build").compile()
		end, 50)
	end
end

return M
