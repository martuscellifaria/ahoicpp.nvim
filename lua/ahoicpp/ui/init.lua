local build = require("ahoicpp.build")
local config = require("ahoicpp.config")
local dialogs = require("ahoicpp.ui.dialogs")
local prompts = require("ahoicpp.ui.prompts")

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

	local function map_if_vis(key, func, desc)
		if key and key ~= false then
			vim.keymap.set("v", key, func, { desc = desc })
		end
	end

	map_if(km.create_app, prompts.create_main_input, "Create C++ [a]pp")
	map_if(km.help, dialogs.create_about, "Open Ahoicpp [h]elp")
	map_if(km.create_module, prompts.create_module_input, "Create C++ [m]odule")
	map_if(km.compile, build.compile, "[c]ompile C++ app")
	map_if(km.execute_app, build.execute_compiled_binary, "E[x]ecute compiled C++ app")
	map_if(km.create_module_dir, prompts.create_module_directory_input, "Create custom module with [d]irectory")
	map_if(km.clone_external, prompts.clone_external, "Clone [e]xternal dependency from Git")
	map_if(km.toggle_autocompile, config.toggle_autocompile, "[t]oggle autocompile app")
	map_if(km.toggle_debug_compilation, config.toggle_debug_compilation, "Toggle compile as de[b]ug")
	map_if(km.escafandro_coding, prompts.escafandro_code_prompt, "Generate [e]scafandro [c]ode")
	map_if_vis(km.escafandro_coding, prompts.escafandro_code_refactor, "Refactor Escafandro [c]ode")
	map_if_vis(km.escafandro_explain, prompts.escafandro_explain, "Escafandro [e]xplains selected code")
	map_if(km.toggle_escafandro_debug_assist, config.toggle_escafandro_debug_assist, "[t]oggle Escafandro debug assist")
end

return M
