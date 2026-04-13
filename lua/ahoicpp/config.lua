-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

local M = {}

M.defaults = {
	autocompile_on_create = true,
	git_init = true,
	keymaps = {
		group_c = "<leader>c",
		group_cp = "<leader>cp",
		create_app = "<leader>cpa",
		help = "<leader>cph",
		create_module = "<leader>cpm",
		compile = "<leader>cpc",
		create_module_dir = "<leader>cpd",
		clone_external = "<leader>cpe",
		toggle_autocompile = "<leader>cpt",
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

function M.toggle_autocompile()
	M.options.autocompile_on_create = not M.options.autocompile_on_create
	local status = M.options.autocompile_on_create and "activated" or "deactivated"
	vim.notify("Autocompile on create " .. status, vim.log.levels.INFO)
end

return M
