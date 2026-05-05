local M = {}

M.defaults = {
	autocompile_on_create = true,
	compile_as_debug = false,
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

function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

function M.toggle_autocompile()
	M.options.autocompile_on_create = not M.options.autocompile_on_create
	local status = M.options.autocompile_on_create and "activated" or "deactivated"
	vim.notify("Autocompile on create " .. status, vim.log.levels.INFO)
end

function M.toggle_debug_compilation()
	M.options.compile_as_debug = not M.options.compile_as_debug
	local build_type = M.options.compile_as_debug and "debug" or "release"
	vim.notify("Changed compilation to " .. build_type, vim.log.levels.INFO)
end

function M.toggle_escafandro_debug_assist()
	M.options.escafandro.debug_assist = not M.options.escafandro.debug_assist
	local assist = M.options.escafandro.debug_assist and "activated" or "deactivated"
	vim.notify("Escafandro debug assist " .. assist, vim.log.levels.INFO)
end

return M
