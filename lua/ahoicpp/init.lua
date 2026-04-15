local config = require("ahoicpp.config")
local ui = require("ahoicpp.ui")
local project = require("ahoicpp.project")
local build = require("ahoicpp.build")

local M = {}

function M.setup(user_config)
	config.setup(user_config)

	if not config.options.keymaps then
		return
	end

	ui.setup_keymaps()
end

M.create_main_input = ui.prompts.create_main_input
M.create_about_ahoicpp = ui.dialogs.create_about
M.create_module_input = ui.prompts.create_module_input
M.create_module_directory_input = ui.prompts.create_module_directory_input
M.compile_app = build.compile
M.clone_external_from_git = ui.prompts.clone_external
M.toggle_autocompile = config.toggle_autocompile
M.config = config.options

return M
