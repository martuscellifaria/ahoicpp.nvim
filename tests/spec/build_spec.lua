local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("ahoicpp.build", function()
	local build
	local mock_utils
	local original_require
	local original_vim_fn

	before_each(function()
		mock_utils = {
			file_exists = function()
				return true
			end,
		}

		original_vim_fn = _G.vim.fn
		_G.vim.fn = {
			executable = function(name)
				return name == "python3"
			end,
		}

		_G.vim = _G.vim or {}
		_G.vim.notify = spy.new(function() end)
		_G.vim.schedule = spy.new(function(fn)
			fn()
		end)
		_G.vim.system = spy.new(function(_, _, cb)
			if cb then
				cb({ code = 0 })
			end
		end)
		_G.vim.cmd = spy.new(function() end)
		_G.vim.version = function()
			return { minor = 12 }
		end
		_G.vim.lsp = {
			get_clients = stub.new(function()
				return { { name = "clangd" } }
			end),
		}
		_G.vim.log = { levels = { INFO = 2, WARN = 3, ERROR = 4 } }

		original_require = _G.require
		_G.require = function(name)
			if name == "ahoicpp.utils" then
				return mock_utils
			else
				return original_require(name)
			end
		end

		package.loaded["ahoicpp.build"] = nil
		build = require("ahoicpp.build")
	end)

	after_each(function()
		_G.require = original_require
		_G.vim.fn = original_vim_fn
	end)

	describe("compile", function()
		it("checks for Python", function()
			build.compile()
			assert.stub(_G.vim.fn.executable).was_called_with("python3")
		end)

		it("warns if Python not found", function()
			_G.vim.fn.executable = stub.new(function()
				return false
			end)
			build.compile()
			assert.spy(_G.vim.notify).was_called_with(match.matches("Python not found"), _G.vim.log.levels.WARN)
		end)

		it("warns if build.py missing", function()
			mock_utils.file_exists.returns(false)
			build.compile()
			assert.spy(_G.vim.notify).was_called_with(match.matches("build.py not found"), _G.vim.log.levels.WARN)
		end)

		it("runs build.py with python", function()
			build.compile()
			assert.spy(_G.vim.system).was_called()
		end)
	end)
end)
