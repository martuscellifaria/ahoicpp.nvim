local M = {}

function M.get_ahoi_template()
	return [[Ahoi Cap'n!]]
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


{{CLASS_NAME}}::{{CLASS_NAME}}() {}

{{CLASS_NAME}}::~{{CLASS_NAME}}() {}


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
    std::println("AhoiCpp is an A.H.O.I. (Alex's Heavily Opinionated Interfaces)");
    std::println("tool for setting a C++ 23 environment in Neovim.");
    std::println("");
    std::println("C++ is a challenging language, specially for newcomers.");
    std::println("This is my take on making it easier to hop along.");
    std::println("");
    std::println("AhoiCpp can set up classes, cmake files, app entrypoints and");
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
set(DESCRIPTION "Your project is owned by A.H.O.I Labs")
set(PRODUCT ${PROJECT_NAME})
set(COPYRIGHT "Copyright 2026")

string(TIMESTAMP BUILD_TIMESTAMP "%Y-%m-%dT%H:%M:%SZ" UTC)
string(TIMESTAMP BUILD_DATE "%Y%m%d")

include(AhoiCppProject.cmake)
include(AhoiCppExternals.cmake)
add_library(ahoicpp_externals INTERFACE)

foreach(PATH ${AHOICPP_EXTERNALS_INCLUDE_PATHS})
    file(GLOB EXPANDED_PATHS ${PATH})
    foreach(EXPANDED ${EXPANDED_PATHS})
        if(IS_DIRECTORY ${EXPANDED})
            target_include_directories(ahoicpp_externals INTERFACE ${EXPANDED})
        endif()
    endforeach()
    if(NOT PATH MATCHES "\\*")
        if(EXISTS ${PATH})
            target_include_directories(ahoicpp_externals INTERFACE ${PATH})
        endif()
    endif()
endforeach()
add_subdirectory(App)
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

target_link_libraries({{PROJECT_NAME}} ahoicpp_externals)
target_compile_features({{PROJECT_NAME}} PUBLIC cxx_std_23)
include(AhoiCppSubdirs.cmake)

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
target_link_libraries({{MODULE_NAME}} ahoicpp_externals)
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_23)
target_include_directories({{MODULE_NAME}} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/{{MODULE_NAME}})
]]
end

function M.get_ahoi_externals_template()
	return [[#Created automagically by AhoiCpp. You can modify this file to add new external libraries to your project. You just have to follow the pattern:
set(AHOICPP_EXTERNALS_INCLUDE_PATHS
    "${CMAKE_CURRENT_SOURCE_DIR}/externals"
    "${CMAKE_CURRENT_SOURCE_DIR}/externals/*/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/externals/*/src"
)
]]
end

function M.get_buildscript()
	return [[import os
import sys
import platform
import shutil


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
    if shutil.which("ninja") is not None:
        build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -G Ninja -D VERSION_ARG="{version}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        ninja > build.log 2>&1
        """
    
    status = os.system(build_command)
    if status != 0:
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
        cd build && cmake .. -D VERSION_ARG="{version}"
        """
    if shutil.which("ninja") is not None:
        build_command = f"""
            cd build && cmake .. -G Ninja -DCMAKE_BUILD_TYPE={build_type} -D VERSION_ARG="{version}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ninja > build.log 2>&1
            """
    else:
        print("Ninja not found. Will produce Visual Studio Solution. Please open in Visual Studio or compile it with MSBuild")
    status = os.system(build_command)
    if status != 0:
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

function M.get_externals_readme()
	return [[# External dependencies

This directory is intended for third-party libraries cloned from Git.

## How to use

1. Clone a dependency (use `<leader>cpe on Neovim` and paste the git url, or clone manually from externals directory).

2. Integrate into your build:
- If it uses CMake: add `add_subdirectory(externals/<library-name>)` to the CMakeLists.txt file of the module that needs the external library.
- If it is a header-only library: add `target_include_directories(your_target PRIVATE externals/<library-name>/include)` or the path to the correspondent header.
- Due to C++ complexity and lack of standardization, some external libraries may need extra work to be integrated. Even in modern commercial IDEs it is not supposed to work out of the box.

## Example with nlohmann-json (header-only):
- Run `<leader>cpe`.
- Paste `https://github.com/nlohmann/json.git` to the dialog prompt.
- Then add the following to the target modules CMakeLists.txt: `target_include_directories(<YourTargetModuleName> PUBLIC ${CMAKE_SOURCE_DIR}/externals/json/include)`.
- If everything is fine, you can go to `<YourTargetModuleName>.cpp` and put `#include "nlohmann/json.hpp"` at the top of it.
- Now compile it with `<leader>cpc`.
- Note: For other libraries that need extra compilation, you may have to also paste `target_link_libraries(<YourTargetModuleName> <YourClonedExternalLibrary>)`
]]
end

function M.get_gitignore()
	return [[build/
compile_commands.json

externals/*
!externals/README.md

.vscode/
.idea/
*.swp
*.swo
*~

.DS_Store
Thumbs.db

*.o
*.obj
*.exe
*.out
*.app
*.so
*.dylib
*.dll

CMakeCache.txt
CMakeFiles/
cmake_install.cmake
*.cmake
!AhoiCppProject.cmake
!AhoiCppSubdirs.cmake

App/version.h
App/version.c
App/version.rc

__pycache__/
*.pyc
]]
end

function M.get_readme_template()
	return [[# {{PROJECT_NAME}}

Bootstrapped with AhoiCpp
]]
end

return M
