-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

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
end

return M
