local dialogs = require("ahoicpp.ui.dialogs")
local prompts = require("ahoicpp.ui.prompts")
local config = require("ahoicpp.config")

local M = {
	dialogs = dialogs,
	prompts = prompts,
}

function M.setup_keymaps()
	local km = config.options.keymaps

	if km.group_c then
		vim.keymap.set("n", km.group_c, "<Nop>", { desc = "+C++" })
	end

	if km.group_cp then
		vim.keymap.set("n", km.group_cp, "<Nop>", { desc = "+AhoiCpp" })
	end

	local function map_if(key, func, desc)
		if key and key ~= false then
			vim.keymap.set("n", key, func, { desc = desc })
		end
	end

	map_if(km.create_app, prompts.create_main_input, "Create C++ [a]pp")
	map_if(km.help, dialogs.create_about, "Open Ahoicpp [h]elp")
	map_if(km.create_module, prompts.create_module_input, "Create C++ [m]odule")
	map_if(km.compile, require("ahoicpp.build").compile, "[c]ompile C++ app")
	map_if(km.create_module_dir, prompts.create_module_directory_input, "Create custom module with [d]irectory")
	map_if(km.clone_external, prompts.clone_external, "Clone [e]xternal dependency from Git")
	map_if(km.toggle_autocompile, config.toggle_autocompile, "[t]oggle autocompile app")
end

return M
