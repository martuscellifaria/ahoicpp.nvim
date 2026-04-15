local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

describe("ahoicpp.project", function()
	local project
	local mock_fs
	local mock_templates
	local mock_config
	local mock_build
	local original_require

	before_each(function()
		mock_fs = {
			create_dir = spy.new(function() end),
			write_file = spy.new(function()
				return true
			end),
			update_file = spy.new(function()
				return true
			end),
			append_file = spy.new(function()
				return true
			end),
			file_exists = function()
				return false
			end,
			dir_exists = function()
				return false
			end,
			read_file = function()
				return nil
			end,
		}
		mock_templates = {
			get_header_template = function()
				return "class {{CLASS_NAME}} {};"
			end,
			get_cpp_template = function()
				return '#include "{{CLASS_NAME}}.h"'
			end,
			get_main_template = function()
				return "int main() { return 0; }"
			end,
			get_externals_readme = function()
				return "# README"
			end,
			get_readme_template = function()
				return "# {{PROJECT_NAME}}"
			end,
			get_version_c_in = function()
				return ""
			end,
			get_version_h_in = function()
				return ""
			end,
			get_version_rc_in = function()
				return ""
			end,
			get_ahoi_template = function()
				return ""
			end,
			get_gitignore = function()
				return ""
			end,
			get_parent_cmake_template = function()
				return "project({{PROJECT_NAME}})"
			end,
			get_app_cmake_template = function()
				return "add_executable({{PROJECT_NAME}})"
			end,
			get_ahoi_externals_template = function()
				return ""
			end,
			get_buildscript = function()
				return ""
			end,
			get_module_cmake_template = function()
				return "add_library({{MODULE_NAME}})"
			end,
		}

		mock_config = {
			options = {
				autocompile_on_create = false,
				git_init = false,
			},
		}

		mock_build = {
			compile = spy.new(function() end),
		}

		_G.vim = {
			cmd = spy.new(function() end),
			notify = spy.new(function() end),
			schedule = spy.new(function(fn)
				fn()
			end),
			defer_fn = spy.new(function(fn, _)
				fn()
			end),
			system = spy.new(function(_, _, cb)
				if cb then
					cb({ code = 0 })
				end
			end),
			log = { levels = { INFO = 2, WARN = 3, ERROR = 4 } },
		}

		_G.package = { config = "/" }

		original_require = _G.require
		_G.require = function(name)
			if name == "ahoicpp.utils" then
				return mock_fs
			elseif name == "ahoicpp.templates" then
				return mock_templates
			elseif name == "ahoicpp.config" then
				return mock_config
			elseif name == "ahoicpp.build" then
				return mock_build
			else
				return original_require(name)
			end
		end

		package.loaded["ahoicpp.project"] = nil
		project = require("ahoicpp.project")
	end)

	after_each(function()
		_G.require = original_require
		_G.vim = nil
		_G.package = nil
	end)

	describe("create_class", function()
		it("creates header and cpp files", function()
			project.create_class("MyClass", "/tmp")
			assert.spy(mock_fs.write_file).was_called(2)
		end)

		it("uses platform separator", function()
			_G.package.config = "\\"
			project.create_class("MyClass", "C:\\tmp")
			assert.spy(mock_fs.write_file).was_called_with("C:\\tmp\\MyClass.h", match._)
		end)

		it("opens files only on successful write", function()
			mock_fs.write_file = spy.new(function()
				return false
			end)
			project.create_class("MyClass", "/tmp")
			assert.spy(_G.vim.cmd).was_called(0)
		end)
	end)

	describe("create_main", function()
		it("creates directory structure", function()
			project.create_main("MyApp")
			assert.spy(mock_fs.create_dir).was_called_with("./App/src")
			assert.spy(mock_fs.create_dir).was_called_with("./externals")
		end)

		it("does not overwrite existing README", function()
			mock_fs.file_exists.returns(true)
			project.create_main("MyApp")

			local called = false
			for _, call in ipairs(mock_fs.write_file.calls) do
				if call.refs[1]:match("README.md$") then
					called = true
				end
			end
			assert.is_false(called)
		end)

		it("defers autocompile when enabled", function()
			mock_config.options.autocompile_on_create = true
			project.create_main("MyApp")
			assert.spy(_G.vim.defer_fn).was_called()
		end)

		it("defers git init when enabled", function()
			mock_config.options.git_init = true
			project.create_main("MyApp")
			assert.spy(_G.vim.defer_fn).was_called()
		end)
	end)

	describe("create_module", function()
		it("creates parent directory when needed", function()
			mock_fs.dir_exists.returns(false)
			project.create_module("MyModule", "NewParent")
			assert.spy(mock_fs.create_dir).was_called_with("./NewParent")
		end)

		it("appends to parent CMakeLists.txt", function()
			project.create_module("MyModule", "Parent")
			assert
				.spy(mock_fs.append_file)
				.was_called_with("./Parent/CMakeLists.txt", match.matches("add_subdirectory"))
		end)

		it("reads existing project files", function()
			mock_fs.file_exists.returns(true)
			mock_fs.read_file.returns("existing content")
			project.create_module("MyModule", "NewParent")
			assert.spy(mock_fs.read_file).was_called()
		end)
	end)
end)
