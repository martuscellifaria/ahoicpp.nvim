-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

-- Utils/templates

local function get_header_template()
	return [[#pragma once

class {{CLASS_NAME}} {
public:
	{{CLASS_NAME}}();
	virtual ~{{CLASS_NAME}}();

private:

};]]
end

local function get_cpp_template()
	return [[#include "{{CLASS_NAME}}.h"


{{CLASS_NAME}}::{{CLASS_NAME}}(){}

{{CLASS_NAME}}::~{{CLASS_NAME}}(){}


]]
end

local function get_main_template()
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

local function get_parent_cmake_template()
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
#PLACEHOLDER_MODULE_IF_NOT_EXISTS#
]]
end

local function get_app_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
	${CMAKE_CURRENT_SOURCE_DIR}/version.h
    @ONLY
)

add_executable({{PROJECT_NAME}} src/{{PROJECT_NAME}}.cpp)
target_include_directories({{PROJECT_NAME}} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_compile_features({{PROJECT_NAME}} PUBLIC cxx_std_23)
#PLACEHOLDER_MODULE_IF_NOT_EXISTS#

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

local function get_module_cmake_template()
	return [[add_library({{MODULE_NAME}} STATIC src/{{MODULE_NAME}}.cpp)
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_23)
target_include_directories({{MODULE_NAME}} PUBLIC
${CMAKE_CURRENT_SOURCE_DIR}/include/{{MODULE_NAME}}
)
]]
end

local function get_buildscript()
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

local function get_version_c_in()
	return [[
const char* embeddedVersion =
    "@PROJECT_NAME@ version: @VERSION@\n"
    "Build type: @CMAKE_BUILD_TYPE@\n"
    "Copyright: @COPYRIGHT@\n"
    "Company: @COMPANY@\n";
]]
end

local function get_version_h_in()
	return [[#pragma once

#define PROJECT_VERSION "@VERSION@"
#define PROJECT_VERSION_MAJOR @PROJECT_VERSION_MAJOR@
#define PROJECT_VERSION_MINOR @PROJECT_VERSION_MINOR@
#define PROJECT_VERSION_PATCH @PROJECT_VERSION_PATCH@
#define PROJECT_VERSION_REVISION @PROJECT_VERSION_TWEAK@]]
end

local function get_version_rc_in()
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

local function file_exists(name)
	local exists = vim.uv.fs_stat(name) and vim.uv.fs_stat(name).type == "file"
	return exists
end

local function write_file(path, content)
	if file_exists(path) then
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

local function update_file(path, content)
	if file_exists(path) then
		local file = io.open(path, "w")
		if file then
			file:write(content)
			file:close()
			return true
		end
	end
	return false
end

local function dir_exists(path)
	local exists = vim.uv.fs_stat(path) and vim.uv.fs_stat(path).type == "directory"
	return exists
end

local function create_dir(path)
	if dir_exists(path) then
		return
	end
	vim.fn.mkdir(path, "p")
end

local function is_valid_class_name(class_name)
	if #class_name == 0 then
		return false
	end
	local keywords = {
		"class",
		"struct",
		"union",
		"enum",
		"virtual",
		"public",
		"private",
		"protected",
		"const",
		"static",
		"volatile",
		"mutable",
		"explicit",
		"friend",
		"operator",
		"template",
		"typename",
		"namespace",
		"using",
		"new",
		"delete",
		"this",
		"inline",
		"override",
		"final",
	}
	for _, kw in ipairs(keywords) do
		if class_name == kw then
			return false
		end
	end
	local first = class_name:sub(1, 1)
	if not first:match("[%a]") then
		return false
	end
	for i = 1, #class_name do
		if not class_name:sub(i, i):match("[%a%d_]") then
			return false
		end
	end
	if class_name:find("__") then
		return false
	end
	return true
end

return {
	get_header_template = get_header_template,
	get_cpp_template = get_cpp_template,
	get_main_template = get_main_template,
	get_parent_cmake_template = get_parent_cmake_template,
	get_module_cmake_template = get_module_cmake_template,
	get_buildscript = get_buildscript,
	get_version_c_in = get_version_c_in,
	get_version_h_in = get_version_h_in,
	get_app_cmake_template = get_app_cmake_template,
	get_version_rc_in = get_version_rc_in,
	file_exists = file_exists,
	write_file = write_file,
	update_file = update_file,
	dir_exists = dir_exists,
	create_dir = create_dir,
	is_valid_class_name = is_valid_class_name,
}
