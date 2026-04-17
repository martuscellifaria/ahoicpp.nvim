describe("ahoicpp.config", function()
	local config

	before_each(function()
		package.loaded["ahoicpp.config"] = nil
		config = require("ahoicpp.config")
	end)

	describe("defaults", function()
		it("has expected default values", function()
			assert.is_true(config.defaults.autocompile_on_create)
			assert.is_true(config.defaults.enable_popups)
			assert.is_true(config.defaults.git_init)
			assert.are.equal("<leader>c", config.defaults.keymaps.group_c)
			assert.are.equal("<leader>cpa", config.defaults.keymaps.create_app)
		end)
	end)

	describe("setup", function()
		it("merges user config with defaults", function()
			config.setup({
				autocompile_on_create = false,
				git_init = false,
			})

			assert.is_false(config.options.autocompile_on_create)
			assert.is_false(config.options.git_init)
			assert.is_true(config.options.enable_popups) -- unchanged default
		end)

		it("deep merges keymap tables", function()
			config.setup({
				keymaps = {
					create_app = "<leader>ca",
				},
			})

			assert.are.equal("<leader>ca", config.options.keymaps.create_app)
			assert.are.equal("<leader>c", config.options.keymaps.group_c) -- unchanged
		end)

		it("handles nil user_config", function()
			config.setup(nil)
			assert.are.same(config.defaults, config.options)
		end)
	end)

	describe("toggle_autocompile", function()
		it("toggles the boolean value", function()
			config.setup({ autocompile_on_create = true })
			config.toggle_autocompile()
			assert.is_false(config.options.autocompile_on_create)

			config.toggle_autocompile()
			assert.is_true(config.options.autocompile_on_create)
		end)
	end)
end)
