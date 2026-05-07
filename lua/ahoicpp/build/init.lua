local utils = require("ahoicpp.utils")
local config = require("ahoicpp.config")
local prompts = require("ahoicpp.ui.prompts")

local M = {}

local compiling = false
function M.compile()
	if compiling then
		vim.notify("Your project is already being compiled. Please wait until it finishes.", vim.log.levels.WARN)
		return
	end
	local python = ""
	if vim.fn.executable("python") == 1 then
		python = "python"
	elseif vim.fn.executable("python3") == 1 then
		python = "python3"
	else
		vim.notify("Python not found. Stopping.", vim.log.levels.WARN)
		return
	end

	local compile_as = "rel"
	if config.options.compile_as_debug then
		compile_as = "deb"
	end

	if not utils.file_exists("build.py") then
		vim.notify("build.py not found. Are you sure you have created your app?", vim.log.levels.WARN)
		return
	end

	vim.notify("Starting compilation.", vim.log.levels.INFO)
	compiling = true
	vim.system({ python, "build.py", compile_as }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				compiling = false
				vim.notify("C++ app (" .. compile_as .. ") compilation finished.", vim.log.levels.INFO)
				if utils.file_exists("ahoicpp_project.json") then
					local project_data = utils.read_file("ahoicpp_project.json")
					if project_data and project_data ~= "" then
						local json_data = vim.fn.json_decode(project_data)
						if
							json_data
							and json_data.project_name
							and json_data.build_path
							and json_data.execution_path
						then
							if
								json_data.project_name ~= ""
								and json_data.build_path ~= ""
								and json_data.execution_path ~= ""
								and json_data.build_path ~= json_data.execution_path
							then
								local file = utils.read_bin_file(json_data.build_path .. json_data.project_name)
								if file then
									local copy_succeeded =
										utils.write_bin_file(file, json_data.execution_path .. json_data.project_name)
									if copy_succeeded == 0 then
										vim.notify(
											"C++ app ("
												.. compile_as
												.. ") compilation finished and copied to the execution path.",
											vim.log.levels.INFO
										)
									end
								end
							end
						end
					end
				end
				local clients = vim.lsp.get_clients({ name = "clangd" })
				if #clients > 0 then
					if vim.version().minor >= 12 then
						vim.cmd("lsp restart clangd")
					else
						vim.cmd("LspRestart clangd")
					end
				end
			else
				compiling = false
				if config.options.escafandro.debug_assist then
					prompts.escafandro_debug()
				else
					vim.notify("Failed to compile. Please read build.log", vim.log.levels.ERROR)
					vim.cmd("edit ./build/build.log")
				end
			end
		end)
	end)
end

function M.execute_compiled_binary()
	if utils.file_exists("ahoicpp_project.json") then
		local project_data = utils.read_file("ahoicpp_project.json")
		if project_data and project_data ~= "" then
			local json_data = vim.fn.json_decode(project_data)
			if json_data and json_data.project_name and json_data.build_path and json_data.execution_path then
				if json_data.project_name ~= "" and json_data.execution_path ~= "" then
					if utils.file_exists(json_data.execution_path .. json_data.project_name) then
						vim.cmd("terminal cd " .. json_data.execution_path .. "&& ./" .. json_data.project_name)
						vim.cmd("startinsert")
					else
						vim.notify("Binary not found. Have you compiled it already?", vim.log.levels.WARN)
					end
				else
					vim.notify("Something may be wrong with your path configuration.", vim.log.levels.WARN)
				end
			else
				vim.notify("Something may be wrong with your path configuration.", vim.log.levels.WARN)
			end
		else
			vim.notify("Check your ahoicpp_project.json file.", vim.log.levels.WARN)
		end
	else
		vim.notify("ahoicpp_project.json file does not exist.", vim.log.levels.WARN)
	end
end

return M
