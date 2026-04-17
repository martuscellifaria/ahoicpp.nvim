local uv = vim.uv or vim.loop

describe("ahoicpp.utils", function()
	local utils
	local tmp_dir
	local original_cwd

	before_each(function()
		-- Create temp directory for filesystem tests
		tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir)
		original_cwd = vim.fn.getcwd()
		vim.cmd("cd " .. tmp_dir)

		-- Fresh require for isolation
		package.loaded["ahoicpp.utils"] = nil
		utils = require("ahoicpp.utils")
	end)

	after_each(function()
		vim.cmd("cd " .. original_cwd)
		vim.fn.delete(tmp_dir, "rf")
		package.loaded["ahoicpp.utils"] = nil
	end)

	describe("file_exists", function()
		it("returns true for existing file", function()
			local fd = uv.fs_open(tmp_dir .. "/test.txt", "w", 420)
			uv.fs_write(fd, "content", 0)
			uv.fs_close(fd)

			assert.is_true(utils.file_exists(tmp_dir .. "/test.txt"))
		end)

		it("returns false for non-existent file", function()
			assert.is_false(utils.file_exists(tmp_dir .. "/does_not_exist.txt"))
		end)

		it("returns false for directories", function()
			vim.fn.mkdir(tmp_dir .. "/subdir")
			assert.is_false(utils.file_exists(tmp_dir .. "/subdir"))
		end)
	end)

	describe("dir_exists", function()
		it("returns true for existing directory", function()
			vim.fn.mkdir(tmp_dir .. "/subdir")
			assert.is_true(utils.dir_exists(tmp_dir .. "/subdir"))
		end)

		it("returns false for non-existent directory", function()
			assert.is_false(utils.dir_exists(tmp_dir .. "/no_such_dir"))
		end)

		it("returns false for files", function()
			local fd = uv.fs_open(tmp_dir .. "/file.txt", "w", 420)
			uv.fs_close(fd)
			assert.is_false(utils.dir_exists(tmp_dir .. "/file.txt"))
		end)
	end)

	describe("write_file", function()
		it("writes content to new file", function()
			local ok = utils.write_file(tmp_dir .. "/new.txt", "hello world")
			assert.is_true(ok)

			local fd = uv.fs_open(tmp_dir .. "/new.txt", "r", 438)
			local stat = uv.fs_fstat(fd)
			local content = uv.fs_read(fd, stat.size, 0)
			uv.fs_close(fd)

			assert.are.equal("hello world", content)
		end)

		it("returns false if file already exists", function()
			local fd = uv.fs_open(tmp_dir .. "/exists.txt", "w", 420)
			uv.fs_close(fd)

			local ok = utils.write_file(tmp_dir .. "/exists.txt", "new content")
			assert.is_false(ok)
		end)

		it("returns false for invalid path", function()
			local ok = utils.write_file("/invalid/path/file.txt", "content")
			assert.is_false(ok)
		end)
	end)

	describe("read_file", function()
		it("reads entire file content", function()
			local fd = uv.fs_open(tmp_dir .. "/readme.txt", "w", 420)
			uv.fs_write(fd, "line1\nline2\nline3", 0)
			uv.fs_close(fd)

			local content = utils.read_file(tmp_dir .. "/readme.txt")
			assert.are.equal("line1\nline2\nline3", content)
		end)

		it("returns nil for non-existent file", function()
			local content = utils.read_file(tmp_dir .. "/nope.txt")
			assert.is_nil(content)
		end)
	end)

	describe("update_file", function()
		it("overwrites existing file", function()
			local fd = uv.fs_open(tmp_dir .. "/update.txt", "w", 420)
			uv.fs_write(fd, "old content", 0)
			uv.fs_close(fd)

			local ok = utils.update_file(tmp_dir .. "/update.txt", "new content")
			assert.is_true(ok)

			local content = utils.read_file(tmp_dir .. "/update.txt")
			assert.are.equal("new content", content)
		end)

		it("returns false if file does not exist", function()
			local ok = utils.update_file(tmp_dir .. "/no_file.txt", "content")
			assert.is_false(ok)
		end)
	end)

	describe("append_file", function()
		it("appends content to existing file", function()
			local fd = uv.fs_open(tmp_dir .. "/append.txt", "w", 420)
			uv.fs_write(fd, "line1\n", 0)
			uv.fs_close(fd)

			local ok = utils.append_file(tmp_dir .. "/append.txt", "line2\n")
			assert.is_true(ok)

			local content = utils.read_file(tmp_dir .. "/append.txt")
			assert.are.equal("line1\nline2\n", content)
		end)

		it("creates file if it does not exist", function()
			local ok = utils.append_file(tmp_dir .. "/new_append.txt", "content")
			assert.is_true(ok)

			local content = utils.read_file(tmp_dir .. "/new_append.txt")
			assert.are.equal("content", content)
		end)
	end)

	describe("create_dir", function()
		it("creates single directory", function()
			utils.create_dir(tmp_dir .. "/newdir")
			assert.is_true(utils.dir_exists(tmp_dir .. "/newdir"))
		end)

		it("creates nested directories", function()
			utils.create_dir(tmp_dir .. "/a/b/c")
			assert.is_true(utils.dir_exists(tmp_dir .. "/a/b/c"))
		end)

		it("does nothing if directory exists", function()
			vim.fn.mkdir(tmp_dir .. "/exists")
			utils.create_dir(tmp_dir .. "/exists")
			assert.is_true(utils.dir_exists(tmp_dir .. "/exists"))
		end)
	end)

	describe("is_valid_class_name", function()
		it("accepts valid class names", function()
			assert.is_true(utils.is_valid_class_name("MyClass"))
			assert.is_true(utils.is_valid_class_name("MyClass123"))
			assert.is_false(utils.is_valid_class_name("_MyClass"))
			assert.is_true(utils.is_valid_class_name("My_Class"))
		end)

		it("rejects C++ keywords", function()
			assert.is_false(utils.is_valid_class_name("class"))
			assert.is_false(utils.is_valid_class_name("struct"))
			assert.is_false(utils.is_valid_class_name("virtual"))
			assert.is_false(utils.is_valid_class_name("namespace"))
		end)

		it("rejects names starting with digit", function()
			assert.is_false(utils.is_valid_class_name("123Class"))
		end)

		it("rejects names with special characters", function()
			assert.is_false(utils.is_valid_class_name("My-Class"))
			assert.is_false(utils.is_valid_class_name("My.Class"))
			assert.is_false(utils.is_valid_class_name("My Class"))
		end)

		it("rejects names with double underscore", function()
			assert.is_false(utils.is_valid_class_name("My__Class"))
		end)

		it("rejects empty or nil", function()
			assert.is_false(utils.is_valid_class_name(""))
			assert.is_false(utils.is_valid_class_name(nil))
		end)
	end)

	describe("is_valid_directory_name", function()
		it("accepts valid names", function()
			assert.is_true(utils.is_valid_directory_name("MyModule"))
			assert.is_true(utils.is_valid_directory_name("Utils"))
		end)

		it("rejects reserved names", function()
			assert.is_false(utils.is_valid_directory_name("App"))
			assert.is_false(utils.is_valid_directory_name("build"))
			assert.is_false(utils.is_valid_directory_name("externals"))
		end)

		it("rejects hidden directories", function()
			assert.is_false(utils.is_valid_directory_name(".git"))
			assert.is_false(utils.is_valid_directory_name(".config"))
		end)
	end)

	describe("get_directories", function()
		it("returns sorted list of valid directories", function()
			vim.fn.mkdir(tmp_dir .. "/src")
			vim.fn.mkdir(tmp_dir .. "/include")
			vim.fn.mkdir(tmp_dir .. "/App")
			vim.fn.mkdir(tmp_dir .. "/.git")
			vim.fn.mkdir(tmp_dir .. "/build")

			local dirs = utils.get_directories()
			assert.are.same({ "include", "src" }, dirs)
		end)

		it("returns empty table when no valid directories", function()
			local dirs = utils.get_directories()
			assert.are.same({}, dirs)
		end)
	end)
end)
