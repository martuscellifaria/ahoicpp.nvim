local M = {}

function M.file_exists(name)
	local stat = vim.uv.fs_stat(name)
	return stat and stat.type == "file" or false
end

function M.write_file(path, content)
	if M.file_exists(path) then
		return false
	end
	local fd = vim.uv.fs_open(path, "w", 420)
	if not fd then
		return false
	end
	local ok = vim.uv.fs_write(fd, content, 0)
	vim.uv.fs_close(fd)
	return ok and true or false
end

function M.update_file(path, content)
	if not M.file_exists(path) then
		return false
	end
	local fd = vim.uv.fs_open(path, "w", 420)
	if not fd then
		return false
	end
	local ok = vim.uv.fs_write(fd, content, 0)
	vim.uv.fs_close(fd)
	return ok and true or false
end

function M.read_file(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end
	local stat = vim.uv.fs_fstat(fd)
	if not stat then
		vim.uv.fs_close(fd)
		return nil
	end
	local data = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)
	return data
end

function M.append_file(path, content)
	local fd = vim.uv.fs_open(path, "a", 420)
	if not fd then
		return false
	end
	local ok = vim.uv.fs_write(fd, content, -1)
	vim.uv.fs_close(fd)
	return ok and true or false
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
		return true
	end
	local ok = vim.fn.mkdir(path, "p") == 1
	if not ok then
		vim.notify("Failed to create " .. path)
	end
	return ok
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
		"typedef",
		"constexpr",
		"consteval",
		"constinit",
		"noexcept",
		"thread_local",
		"export",
		"concept",
		"requires",
		"pre",
		"post",
		"contract_assert",
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
