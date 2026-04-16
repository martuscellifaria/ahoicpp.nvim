local utils = require("ahoicpp.utils")

local M = {}

function M.compile()
	local python = ""
	if vim.fn.executable("python") == 1 then
		python = "python"
	elseif vim.fn.executable("python3") == 1 then
		python = "python3"
	else
		vim.notify("Python not found. Stopping.", vim.log.levels.WARN)
		return
	end

	if not utils.file_exists("build.py") then
		vim.notify("build.py not found. Are you sure you have created your app?", vim.log.levels.WARN)
		return
	end

	vim.notify("Starting compilation.", vim.log.levels.INFO)
	vim.system({ python, "build.py", "abcde" }, { text = true }, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				vim.notify("C++ app compilation finished.", vim.log.levels.INFO)
				local clients = vim.lsp.get_clients({ name = "clangd" })
				if #clients > 0 then
					if vim.version().minor >= 12 then
						vim.cmd("lsp restart clangd")
					else
						vim.cmd("LspRestart clangd")
					end
				end
			else
				vim.notify("Failed to compile. Please read build.log", vim.log.levels.ERROR)
				vim.cmd("edit ./build/build.log")
			end
		end)
	end)
end

return M
