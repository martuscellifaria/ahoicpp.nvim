local utils = require("ahoicpp.utils")
local M = {}

M.defaults = {
	autocompile_on_create = true,
	cpp_version = 23,
	enable_popups = true,
	git_init = true,
	keymaps = {
		group_c = "<leader>c",
		group_cp = "<leader>cp",
		create_app = "<leader>cpa",
		help = "<leader>cph",
		create_module = "<leader>cpm",
		create_module_dir = "<leader>cpd",
		compile = "<leader>cpc",
		clone_external = "<leader>cpe",
		toggle_autocompile = "<leader>cpt",
		toggle_debug_compilation = "<leader>cpb",
		execute_app = "<leader>cpx",
		escafandro_coding = "<leader>cec",
		escafandro_explain = "<leader>cee",
		toggle_escafandro_debug_assist = "<leader>cet",
	},
	escafandro = {
		ip = "",
		engine = "",
		model = "",
		max_tokens = 0,
		debug_assist = false,
	},
}

M.options = vim.deepcopy(M.defaults)
M.cpp_supported_versions = { 11, 14, 17, 20, 23 }

function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

function M.toggle_autocompile()
	M.options.autocompile_on_create = not M.options.autocompile_on_create
	local status = M.options.autocompile_on_create and "activated" or "deactivated"
	vim.notify("Autocompile on create " .. status, vim.log.levels.INFO)
end

function M.toggle_debug_compilation()
	local project_data
	local json_data
	if utils.file_exists("ahoicpp_project.json") then
		project_data = utils.read_file("ahoicpp_project.json")
		if project_data and project_data ~= "" then
			json_data = vim.fn.json_decode(project_data)
			if json_data and json_data ~= "" then
				if json_data.build_as == "debug" then
					json_data.build_as = "release"
				else
					json_data.build_as = "debug"
				end
			end
			utils.update_file("ahoicpp_project.json", vim.fn.json_encode(json_data))
			vim.cmd("silent! edit!")
			vim.notify("Changed compilation to " .. json_data.build_as, vim.log.levels.INFO)
		end
	end
end

function M.toggle_escafandro_debug_assist()
	M.options.escafandro.debug_assist = not M.options.escafandro.debug_assist
	local assist = M.options.escafandro.debug_assist and "activated" or "deactivated"
	vim.notify("Escafandro debug assist " .. assist, vim.log.levels.INFO)
end

return M
