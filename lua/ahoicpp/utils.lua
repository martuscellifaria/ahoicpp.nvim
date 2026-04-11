-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

local M = {}

function M.file_exists(name)
	local stat = vim.uv.fs_stat(name)
	return stat and stat.type == "file" or false
end

function M.write_file(path, content)
	if M.file_exists(path) then
		return false
	end
	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
		return true
	end
	return false
end

function M.update_file(path, content)
	if M.file_exists(path) then
		local file = io.open(path, "w")
		if file then
			file:write(content)
			file:close()
			return true
		end
	end
	return false
end

function M.read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

function M.dir_exists(path)
	local stat = vim.uv.fs_stat(path)
	return stat and stat.type == "directory" or false
end

function M.get_directories()
	local dirs = {}
	local cwd = vim.fn.getcwd()
	local handle = vim.uv.fs_scandir(cwd)
	if handle then
		while true do
			local name, type = vim.uv.fs_scandir_next(handle)
			if not name then
				break
			end
			if
				type == "directory"
				and not name:match("^%.")
				and name ~= "App"
				and name ~= "build"
				and name ~= "externals"
			then
				table.insert(dirs, name)
			end
		end
	end
	table.sort(dirs)
	return dirs
end

function M.create_dir(path)
	if M.dir_exists(path) then
		return
	end
	vim.fn.mkdir(path, "p")
end

function M.is_valid_class_name(class_name)
	if not class_name or #class_name == 0 then
		return false
	end

	local keywords = {
		"class",
		"struct",
		"union",
		"enum",
		"virtual",
		"public",
		"private",
		"protected",
		"const",
		"static",
		"volatile",
		"mutable",
		"explicit",
		"friend",
		"operator",
		"template",
		"typename",
		"namespace",
		"using",
		"new",
		"delete",
		"this",
		"inline",
		"override",
		"final",
	}

	for _, kw in ipairs(keywords) do
		if class_name == kw then
			return false
		end
	end

	local first = class_name:sub(1, 1)
	if not first:match("[%a_]") then
		return false
	end

	for i = 1, #class_name do
		if not class_name:sub(i, i):match("[%a%d_]") then
			return false
		end
	end

	if class_name:find("__") then
		return false
	end

	if class_name:match("^_") or class_name:match("_$") then
		return false
	end

	return true
end

function M.is_valid_directory_name(name)
	return name
		and M.is_valid_class_name(name)
		and name ~= "App"
		and name ~= "build"
		and name ~= "externals"
		and not name:match("^%.")
end

return M
