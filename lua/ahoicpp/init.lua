local M = {}

local function create_dialog(dialog_title, dialog_width, dialog_height, buf)
	local width = dialog_width
	local height = dialog_height
	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = dialog_title,
		title_pos = "center",
	})
	return win
end

function M.create_module_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Module", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Module Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and input ~= "" then
			M.create_module(input)
		else
			vim.notify("No input provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_class_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Class", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "Class Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and input ~= "" then
			M.create_class(input, ".")
		else
			vim.notify("No input provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_main_input()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = create_dialog("Ahoi C++ Add Main", 40, 1, buf)

	vim.api.nvim_set_option_value("buftype", "prompt", { buf = buf })
	vim.fn.prompt_setprompt(buf, "App Name: ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		vim.api.nvim_win_close(win, true)
		if input and input ~= "" then
			M.create_main(input)
		else
			vim.notify("No input provided.\n")
		end

		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end)
	end)

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.create_about_ahoicpp()
	local lines = {
		"",
		"Ahoi C++ is an A.H.O.I. (Alex's Heavily Opinionated Interfaces)",
		"tool for setting a C++ 23 environment in NeoVim.",
		"",
		"C++ is a terrible language, but it pays my bills since 2016.",
		"This is my take on making it not so disfunctional.",
		"",
		"Ahoi C++ can set up classes, cmake files, app entrypoints and",
		"even creates a python script for building your project.",
		"",
		"",
		"                                     Press <ENTER> to close",
	}

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "HelpBuffer",
		callback = function()
			vim.keymap.set("n", "<CR>", ":bd!<CR>", { buffer = true, silent = true })
		end,
	})

	local buf = vim.api.nvim_create_buf(false, true)
	-- local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "HelpBuffer")

	local width = 0
	for _, s in ipairs(lines) do
		width = math.max(width, #s)
	end
	local height = #lines

	local win = create_dialog("Ahoi C++ Add Main", width, height, buf)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(buf)
end

function M.compile_app()
	if M.file_exists("build.py") then
		vim.notify("Starting compilation.")
		vim.fn.jobstart({ "python", "build.py", "abcde" }, {
			on_exit = function(_, code)
				if code == 0 then
					vim.notify("C++ app compilation finished.")
				else
					vim.notify("Failed to compile. Please read build.log")
					vim.cmd("edit" .. "./build/build.log")
				end
			end,
		})
	else
		vim.notify("build.py not found.")
	end
end

function M.create_class(class_name, output_dir)
	local header_path = output_dir .. "/" .. class_name .. ".h"
	local header_template = M.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", class_name)
	M.write_file(header_path, header_template)
	vim.cmd("edit" .. header_path)
	local cpp_path = output_dir .. "/" .. class_name .. ".cpp"
	local cpp_template = M.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", class_name)
	M.write_file(cpp_path, cpp_template)
	vim.cmd("edit" .. cpp_path)
end

function M.create_main(main_name)
	local app_path = "./App/src"
	M.create_dir(app_path)
	local main_path = app_path .. "/" .. main_name .. ".cpp"
	local main_template = M.get_main_template()
	M.write_file(main_path, main_template)
	vim.cmd("edit" .. main_path)
	app_path = "./App"
	local version_path = app_path .. "/version.c.in"
	local version_template = M.get_version_c_in()
	M.write_file(version_path, version_template)
	version_path = app_path .. "/version.h.in"
	version_template = M.get_version_h_in()
	M.write_file(version_path, version_template)
	version_path = app_path .. "/version.rc.in"
	version_template = M.get_version_rc_in()
	M.write_file(version_path, version_template)
	local cmake_path = "./CMakeLists.txt"
	local cmake_template = M.get_parent_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	M.write_file(cmake_path, cmake_template)
	cmake_path = "./App/CMakeLists.txt"
	cmake_template = M.get_app_cmake_template()
	cmake_template = cmake_template:gsub("{{PROJECT_NAME}}", main_name)
	M.write_file(cmake_path, cmake_template)
	local build_path = "./build.py"
	local build_template = M.get_buildscript()
	M.write_file(build_path, build_template)
end

function M.create_module(module_name)
	local modules_path = "./Modules/" .. module_name .. "/include/" .. module_name
	M.create_dir(modules_path)
	modules_path = "./Modules/" .. module_name .. "/src"
	M.create_dir(modules_path)
	local cmake_path = "./Modules/CMakeLists.txt"
	local mode = M.file_exists(cmake_path) and "a" or "w"
	local file, err = io.open(cmake_path, mode)
	if not file then
		error("Error opening file: " .. tostring(err))
	end
	file:write("add_subdirectory(" .. module_name .. ")\n")
	file:close()
	cmake_path = "./Modules/" .. module_name .. "/CMakeLists.txt"
	local cmake_template = M.get_module_cmake_template()
	cmake_template = cmake_template:gsub("{{MODULE_NAME}}", module_name)
	M.write_file(cmake_path, cmake_template)
	local header_path = "./Modules/" .. module_name .. "/include/" .. module_name .. "/" .. module_name .. ".h"
	local header_template = M.get_header_template()
	header_template = header_template:gsub("{{CLASS_NAME}}", module_name)
	M.write_file(header_path, header_template)
	vim.cmd("edit" .. header_path)
	local cpp_path = "./Modules/" .. module_name .. "/src/" .. module_name .. ".cpp"
	local cpp_template = M.get_cpp_template()
	cpp_template = cpp_template:gsub("{{CLASS_NAME}}", module_name)
	M.write_file(cpp_path, cpp_template)
	vim.cmd("edit" .. cpp_path)
end

function M.get_header_template()
	return [[#pragma once

class {{CLASS_NAME}} {
public:
	{{CLASS_NAME}}();
	virtual ~{{CLASS_NAME}}();

private:

};]]
end

function M.get_cpp_template()
	return [[#include "{{CLASS_NAME}}.h"


{{CLASS_NAME}}::{{CLASS_NAME}}(){}

{{CLASS_NAME}}::~{{CLASS_NAME}}(){}


]]
end

function M.get_main_template()
	return [[#include <print>
#include "version.h"

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embeddedVersion;

int main() {
	std::println("Ahoi C++ is an A.H.O.I. (Alex's Heavily Opinionated Interfaces)");
	std::println("tool for setting a C++ 23 environment in NeoVim.");
	std::println("");
	std::println("C++ is a terrible language, but it pays my bills since 2016.");
	std::println("This is my take on making it not so disfunctional.");
	std::println("");
	std::println("Ahoi C++ can set up classes, cmake files, app entrypoints and");
	std::println("even creates a python script for building your project.");
	return 0;
}
]]
end

function M.get_parent_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

if(DEFINED VERSION_ARG)
	set(PROJECT_VERSION ${VERSION_ARG})
else()
	set(PROJECT_VERSION "99.99.99.99") 
endif()

project({{PROJECT_NAME}} VERSION ${PROJECT_VERSION})
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(VER_MAJOR ${PROJECT_VERSION_MAJOR})
set(VER_MINOR ${PROJECT_VERSION_MINOR})
set(VER_PATCH ${PROJECT_VERSION_PATCH})
set(VER_REVISION ${PROJECT_VERSION_TWEAK})
set(VERSION ${PROJECT_VERSION})
set(COMPANY "AHOI Labs")
set(DESCRIPTION "AHOI Labs own your project")
set(PRODUCT ${PROJECT_NAME})
set(COPYRIGHT "Copyright 2026")

string(TIMESTAMP BUILD_TIMESTAMP "%Y-%m-%dT%H:%M:%SZ" UTC)
string(TIMESTAMP BUILD_DATE "%Y%m%d")

add_subdirectory(App)
# add_subdirectory(Modules) # Placeholder for adding Modules directory
]]
end

function M.get_app_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
	${CMAKE_CURRENT_SOURCE_DIR}/version.h
    @ONLY
)

add_executable({{PROJECT_NAME}} src/{{PROJECT_NAME}}.cpp)
target_include_directories({{PROJECT_NAME}} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_compile_features({{PROJECT_NAME}} PUBLIC cxx_std_23)
# target_link_libraries({{PROJECT_NAME}} PlaceholderForSomeLibrary)

if(WIN32)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/version.rc.in
		${CMAKE_CURRENT_SOURCE_DIR}/version.rc
        @ONLY
	)
	target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.rc)
else()
	configure_file(
		${CMAKE_CURRENT_SOURCE_DIR}/version.c.in
		${CMAKE_CURRENT_SOURCE_DIR}/version.c
		@ONLY
	)
	target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.c)
endif()
]]
end

function M.get_module_cmake_template()
	return [[add_library({{MODULE_NAME}} STATIC src/{{MODULE_NAME}}.cpp)
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_23)
target_include_directories({{MODULE_NAME}} PUBLIC
${CMAKE_CURRENT_SOURCE_DIR}/include/{{MODULE_NAME}}
)
]]
end

function M.write_file(path, content)
	if M.file_exists(path) then
		return false
	end
	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
		return true
	end
	return false
end

function M.file_exists(name)
	local file_exists = vim.uv.fs_stat(name) and vim.uv.fs_stat(name).type == "file"
	return file_exists
end

function M.create_dir(path)
	if M.dir_exists(path) then
		return
	end
	vim.fn.mkdir(path, "p")
end

function M.dir_exists(path)
	local dir_exists = vim.uv.fs_stat(path) and vim.uv.fs_stat(path).type == "directory"
	return dir_exists
end

function M.get_buildscript()
	return [[import os
import sys
import platform


def run_cmake_on_linux(build_type: str, version: str):
    if version == "":
        version = "99.99.99.99"
    build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -D VERSION_ARG="{version}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        make -j8 > build.log 2>&1
        """
    if (os.system("command -v ninja > /dev/null") == 0):
        build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -G Ninja -D VERSION_ARG="{version}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        ninja > build.log 2>&1
        """
    
    status = os.system(build_command)
    if (status != 0):
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)
    sys.exit(0)


def run_cmake_on_windows(build_type: str, version: str):
    if version == "":
        version = "99.99.99.99"
    pre_build_command = f"""
    if not exist build mkdir build;
    """
    os.system(pre_build_command)
    build_command = f"""
    cd build && cmake .. -DCMAKE_BUILD_TYPE={build_type} -D VERSION_ARG="{version}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON;
    """
    status = os.system(build_command)
    if (status != 0):
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)
    sys.exit(0)


def run_app(build_type: str, version: str):
    operating_system = platform.system()
    match operating_system:
        case "Linux":
            print("Linux detected, let us run the build.")
            run_cmake_on_linux(build_type, version)
        case "Windows":
            print("Windows detected, let us generate a Visual Studio Solution file.")
            run_cmake_on_windows(build_type, version)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Welcome to A.H.O.I. (Alex's Heavily Opinionated Interfaces) C++ build process. Pick your build or just press enter to go fast.")
        print("[Enter]  FastBuild")
        print("[0]      Release")
        print("[1]      Debug")
        build_selection = input()

        match(build_selection):
            case "":
                run_app("Release", "")
            case "0":
                print("You selected Release. Please add a version to your build. Format recommended: XX.XX.XX.XX. Hint: you can just press enter and leave it empty.")
                version = input()
                run_app("Release", version)
            case "1":
                print("Build as Debug")
                run_app("RelWithDebInfo", "")
            case _:
                print("Invalid input. Bye.")
    else:
        run_app("Release", "")
]]
end

function M.get_version_c_in()
	return [[
const char* embeddedVersion =
    "@PROJECT_NAME@ version: @VERSION@\n"
    "Build type: @CMAKE_BUILD_TYPE@\n"
    "Copyright: @COPYRIGHT@\n"
    "Company: @COMPANY@\n";
]]
end

function M.get_version_h_in()
	return [[#pragma once

#define PROJECT_VERSION "@VERSION@"
#define PROJECT_VERSION_MAJOR @PROJECT_VERSION_MAJOR@
#define PROJECT_VERSION_MINOR @PROJECT_VERSION_MINOR@
#define PROJECT_VERSION_PATCH @PROJECT_VERSION_PATCH@
#define PROJECT_VERSION_REVISION @PROJECT_VERSION_TWEAK@]]
end

function M.get_version_rc_in()
	return [[#include <windows.h>

VS_VERSION_INFO VERSIONINFO
FILEVERSION    @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@,@VER_REVISION@
PRODUCTVERSION @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@,@VER_REVISION@
FILEFLAGSMASK 0x3fL
FILEFLAGS 0x0L
FILEOS VOS_NT_WINDOWS32
FILETYPE VFT_APP
FILESUBTYPE 0x0L
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904b0"
        BEGIN
            VALUE "CompanyName", "@COMPANY@"
            VALUE "FileDescription", "@DESCRIPTION@"
            VALUE "FileVersion", "@VERSION@"
            VALUE "ProductName", "@PRODUCT@"
            VALUE "ProductVersion", "@VERSION@"
            VALUE "LegalCopyright", "@COPYRIGHT@"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1200
    END
END
]]
end

return M
