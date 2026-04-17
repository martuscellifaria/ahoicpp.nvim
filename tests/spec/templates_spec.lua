describe("ahoicpp.templates", function()
	local templates

	before_each(function()
		package.loaded["ahoicpp.templates"] = nil
		templates = require("ahoicpp.templates")
	end)

	it("get_header_template returns non-empty string with placeholder", function()
		local tmpl = templates.get_header_template()
		assert.is_string(tmpl)
		assert.not_equal("", tmpl)
		assert.matches("{{CLASS_NAME}}", tmpl)
	end)

	it("get_cpp_template returns non-empty string with placeholder", function()
		local tmpl = templates.get_cpp_template()
		assert.is_string(tmpl)
		assert.not_equal("", tmpl)
		assert.matches("{{CLASS_NAME}}", tmpl)
	end)

	it("get_main_template returns valid C++", function()
		local tmpl = templates.get_main_template()
		assert.matches("int main", tmpl)
		assert.matches("return 0", tmpl)
	end)

	it("get_parent_cmake_template has project placeholder", function()
		local tmpl = templates.get_parent_cmake_template()
		assert.matches("{{PROJECT_NAME}}", tmpl)
		assert.matches("cmake_minimum_required", tmpl)
	end)

	it("get_app_cmake_template has project placeholder", function()
		local tmpl = templates.get_app_cmake_template()
		assert.matches("{{PROJECT_NAME}}", tmpl)
	end)

	it("get_module_cmake_template has module placeholder", function()
		local tmpl = templates.get_module_cmake_template()
		assert.matches("{{MODULE_NAME}}", tmpl)
	end)

	it("get_ahoi_template returns marker", function()
		local tmpl = templates.get_ahoi_template()
		assert.matches("Ahoi", tmpl)
	end)

	it("get_gitignore includes common patterns", function()
		local tmpl = templates.get_gitignore()
		assert.matches("build/", tmpl)
		assert.matches("externals/", tmpl)
		assert.matches("%.o", tmpl)
	end)

	it("get_externals_readme has instructions", function()
		local tmpl = templates.get_externals_readme()
		assert.matches("External dependencies", tmpl)
		assert.matches("git", tmpl)
	end)

	it("get_buildscript is valid Python", function()
		local tmpl = templates.get_buildscript()
		assert.matches("import os", tmpl)
		assert.matches("def run_cmake", tmpl)
	end)

	it("all version templates are non-empty", function()
		assert.not_equal("", templates.get_version_c_in())
		assert.not_equal("", templates.get_version_h_in())
		assert.not_equal("", templates.get_version_rc_in())
	end)
end)
