local M = {}

function M.check()
	vim.health.start("AhoiCpp")

	if vim.fn.executable("python") == 1 or vim.fn.executable("python3") == 1 then
		vim.health.ok("Python found")
	else
		vim.health.error("Python not found - required for building")
	end

	if vim.fn.executable("git") == 1 then
		vim.health.ok("Git found")
	else
		vim.health.warn("Git not found - external dependency cloning will not work")
	end

	if vim.fn.executable("cmake") == 1 then
		vim.health.ok("CMake found")
	else
		vim.health.error("CMake not found - required for building")
	end

	if vim.fn.executable("clangd") == 1 then
		vim.health.ok("clangd found in PATH")
	else
		vim.health.warn("clangd not found in PATH - recommended for C++ development")
	end
	local plenary_ok, _ = pcall(require, "plenary")
	if plenary_ok then
		vim.health.ok("Plenary.nvim found - tests can be run")
	else
		vim.health.info("Plenary.nvim not found - only needed for development/testing")
	end
	local plugin_root = debug.getinfo(1, "S").source:sub(2)
	plugin_root = vim.fn.fnamemodify(plugin_root, ":p:h:h:h")
	local tests_dir = plugin_root .. "/tests"

	if vim.fn.isdirectory(tests_dir) == 1 then
		local spec_files = vim.fn.glob(tests_dir .. "/spec/*_spec.lua", false, true)
		if #spec_files > 0 then
			vim.health.ok("Test suite found (" .. #spec_files .. " spec files)")
		else
			vim.health.warn("Test directory exists but no spec files found")
		end
	else
		vim.health.info("Tests directory not found - development setup incomplete")
	end
end

return M
