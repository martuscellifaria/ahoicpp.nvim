local utils = require("ahoicpp.utils")
local config = require("ahoicpp.config")

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
				vim.notify("Failed to compile. Please read build.log", vim.log.levels.ERROR)
				vim.cmd("edit ./build/build.log")
			end
		end)
	end)
end

return M
