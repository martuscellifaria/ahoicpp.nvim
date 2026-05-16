local M = {}

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

function M.get_main_template(version)
	if version and version >= 23 then
		return [[#include <print>
#include <string>
#include "version.h"

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embedded_version;

int main() {
    std::string welcome_to_ahoicpp = "\nAhoiCpp is a tool for setting a C++ development environment in Neovim.\n\
\nC++ is a challenging language, specially for newcomers.\n\
This is my take on making it easier to hop along.\n\
\nAhoiCpp can set up classes, cmake files, app entrypoints and\n\
even creates a python script for building your project.";
    std::println("{}", welcome_to_ahoicpp);
    return 0;
}
]]
	end
	return [[#include <iostream>
#include <string>
#include "version.h"

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embedded_version;

int main() {
    std::string welcome_to_ahoicpp = "\nAhoiCpp is a tool for setting a C++ development environment in Neovim.\n\
\nC++ is a challenging language, specially for newcomers.\n\
This is my take on making it easier to hop along.\n\
\nAhoiCpp can set up classes, cmake files, app entrypoints and\n\
even creates a python script for building your project.";
	std::cout << welcome_to_ahoicpp << '\n';
    return 0;
}
]]
end

function M.get_parent_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

if(DEFINED VERSION_ARG)
    set(PROJECT_VERSION ${VERSION_ARG})
else()
    set(PROJECT_VERSION "99.99.99") 
endif()
if(DEFINED COMPANY_ARG)
	set(PROJECT_COMPANY ${COMPANY_ARG})
else()
	set(PROJECT_COMPANY "Ahoi Labs") 
endif()
if(DEFINED DESCRIPTION_ARG)
	set(PROJECT_DESCRIPTION ${DESCRIPTION_ARG})
else()
	set(PROJECT_DESCRIPTION "Your project is owned by Ahoi Labs") 
endif()

project({{PROJECT_NAME}} VERSION ${PROJECT_VERSION})
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(VER_MAJOR ${PROJECT_VERSION_MAJOR})
set(VER_MINOR ${PROJECT_VERSION_MINOR})
set(VER_PATCH ${PROJECT_VERSION_PATCH})
set(VERSION ${PROJECT_VERSION})
set(COMPANY ${PROJECT_COMPANY})
set(DESCRIPTION ${PROJECT_DESCRIPTION})
set(PRODUCT ${PROJECT_NAME})
string(TIMESTAMP COPYRIGHT_YEAR "%Y")
set(COPYRIGHT "Copyright ${COPYRIGHT_YEAR}")

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
target_link_libraries({{PROJECT_NAME}} ahoicpp_externals ${AHOICPP_EXTERNALS_TARGETS})
target_compile_features({{PROJECT_NAME}} PUBLIC cxx_std_{{CPP_VERSION}})
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
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_{{CPP_VERSION}})
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


def run_cmake_on_linux(build_type: str, version: str = "99.99.99", company: str = "", description: str = ""):
    if version == "":
        version = "99.99.99"
    build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -D VERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        make -j8 > build.log 2>&1

        """
    if shutil.which("ninja") is not None:
        build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -G Ninja -D VERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        ninja > build.log 2>&1
        """

    status = os.system(build_command)
    if status != 0:
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)
    sys.exit(0)


def run_cmake_on_windows(build_type: str, version: str = "99.99.99", company: str = "", description: str = ""):
    if version == "":
        version = "99.99.99"

    pre_build_command = f"""
    if not exist build mkdir build;
    """
    os.system(pre_build_command)

    build_command = f"""
        cd build && cmake .. -D VERSION_ARG="{version}"
        """

    if shutil.which("ninja") is not None:
        build_command = f"""
        cd build && cmake .. -G Ninja -DCMAKE_BUILD_TYPE={build_type} -DVERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ninja > build.log 2>&1
        """
    else:
        print("Ninja not found. Will produce Visual Studio Solution. Please open in Visual Studio or compile it with MSBuild")

    status = os.system(build_command)

    if status != 0:
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)

    sys.exit(0)


def run_app(build_type: str, version: str = "", company: str = "", description: str = ""):
    operating_system = platform.system()
    match operating_system:
        case "Linux":
            print("Linux detected, let us run the build.")
            run_cmake_on_linux(build_type, version, company, description)
        case "Windows":
            print("Windows detected, let us generate a Visual Studio Solution file.")
            run_cmake_on_windows(build_type, version, company, description)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Welcome to AhoiCpp build process. Pick your build or just press enter to go fast.")
        print("[Enter]  FastBuild")
        print("[0]      Release")
        print("[1]      Debug")
        build_selection = input()

        match(build_selection):
            case "":
                run_app("Release", "")
            case "0":
                print("You selected Release. Please add a version to your build. Format recommended: XX.XX.XX. Hint: you can just press enter and leave it empty.")
                version = input()
                run_app("Release", version)
            case "1":
                print("Build as Debug")
                run_app("RelWithDebInfo", "")
            case _:
                print("Invalid input. Bye.")
    elif (sys.argv[1] == "debug"):
        version = sys.argv[2] if len(sys.argv) > 2 else "99.99.99"
        company = sys.argv[3] if len(sys.argv) > 3 else "Ahoi Labs"
        description = sys.argv[4] if len(
            sys.argv) > 4 else "Your project is owned by Ahoi Labs."
        run_app("RelWithDebInfo", version, company, description)
    else:
        version = sys.argv[2] if len(sys.argv) > 2 else "99.99.99"
        company = sys.argv[3] if len(sys.argv) > 3 else "Ahoi Labs"
        description = sys.argv[4] if len(
            sys.argv) > 4 else "Your project is owned by Ahoi Labs."
        run_app("Release", version, company, description)
]]
end

function M.get_version_c_in()
	return [[
const char* embedded_version =
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
]]
end

function M.get_version_rc_in()
	return [[#include <windows.h>

VS_VERSION_INFO VERSIONINFO
FILEVERSION    @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@
PRODUCTVERSION @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@
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

function M.get_project_json_template()
	return [[{
	"project_name": "{{PROJECT_NAME}}",
	"build_path": ".{{SEP}}build{{SEP}}App{{SEP}}",
	"execution_path": ".{{SEP}}build{{SEP}}App{{SEP}}",
	"build_as": "release",
	"version": "99.99.99",
	"company": "Ahoi Labs",
	"description": "Your project is owned by Ahoi Labs"
}]]
end

function M.get_libpqxx_fetcher()
	return [[import subprocess
import sys
from pathlib import Path


def run(cmd, cwd=None, ok_codes=(0,)):
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode not in ok_codes:
        sys.exit(result.returncode)
    return result


def main():
    root = Path(__file__).resolve().parent.parent
    externals = root / "externals"
    externals.mkdir(exist_ok=True)

    libpqxx_dir = externals / "libpqxx"
    if not (libpqxx_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/jtv/libpqxx.git",
             "externals/libpqxx"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/libpqxx"], cwd=root)
    run(["git", "checkout", "7.9.2"], cwd=libpqxx_dir)

    postgres_dir = externals / "postgres"
    if not (postgres_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/postgres/postgres.git",
             "externals/postgres"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/postgres"], cwd=root)
    run(["git", "checkout", "REL_16_2"], cwd=postgres_dir)

    run(["git", "add", ".gitmodules", "externals/libpqxx", "externals/postgres"], cwd=root)

    pq_output = postgres_dir / "build-output"
    if not (pq_output / "lib" / "libpq.so").exists() and \
       not (pq_output / "lib" / "libpq.dylib").exists() and \
       not (pq_output / "lib" / "libpq.lib").exists():
        run(["./configure", f"--prefix={pq_output}", "--without-readline",
             "--without-zlib", "CFLAGS=-std=c17"], cwd=postgres_dir)
        nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"
        run(["make", "-C", "src/interfaces/libpq", "-j", nproc], cwd=postgres_dir)
        run(["make", "-C", "src/interfaces/libpq", "install"], cwd=postgres_dir)
        run(["make", "-C", "src/include", "install"], cwd=postgres_dir)
        run(["make", "-C", "src/port", "install"], cwd=postgres_dir)

    build_dir = libpqxx_dir / "build"
    pqxx_output = libpqxx_dir / "build-output"
    if not (pqxx_output / "lib" / "libpqxx-7.9.so").exists() and \
       not (pqxx_output / "lib" / "libpqxx-7.9.dylib").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={pqxx_output}",
             f"-DCMAKE_PREFIX_PATH={pq_output}",
             "-DBUILD_SHARED_LIBS=ON",
             "-DSKIP_BUILD_TEST=ON"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "libpqxx_config.cmake"
    cmake_config.write_text(f"""# Automagically generated by libpqxx_fetcher.py
set(LIBPQXX_INCLUDE_DIR "{pqxx_output / "include"}")
set(LIBPQ_INCLUDE_DIR "{pq_output / "include"}")
set(LIBPQXX_LIB_DIR "{pqxx_output / "lib"}")
set(LIBPQ_LIB_DIR "{pq_output / "lib"}")
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/libpqxx_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    global_block = f"""# Automagically added by libpqxx_fetcher.py
include_directories(${{LIBPQXX_INCLUDE_DIR}} ${{LIBPQ_INCLUDE_DIR}})
link_directories(${{LIBPQXX_LIB_DIR}} ${{LIBPQ_LIB_DIR}})
link_libraries(pqxx pq)
"""
    target_block = f"""target_include_directories(ahoicpp_externals INTERFACE ${{LIBPQXX_INCLUDE_DIR}} ${{LIBPQ_INCLUDE_DIR}})
"""
    
    if project_cmake.exists():
        content = project_cmake.read_text()
        if "LIBPQXX_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "include(AhoiCppExternals.cmake)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx == 0:
                for i, line in enumerate(lines):
                    if "project(" in line.lower():
                        insert_idx = i + 1
                        break
            lines.insert(insert_idx, global_block)
            
            insert_idx2 = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx2 = i + 1
                    break
            if insert_idx2 > 0:
                lines.insert(insert_idx2, target_block)
            
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_opencv_fetcher()
	return [[import subprocess
import sys
from pathlib import Path


def run(cmd, cwd=None, ok_codes=(0,)):
    print(f"[{cwd or '.'}] $ {' '.join(str(c) for c in cmd)}")
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode not in ok_codes:
        sys.exit(result.returncode)
    return result


def main():
    root = Path(__file__).resolve().parent.parent
    externals = root / "externals"
    externals.mkdir(exist_ok=True)

    opencv_dir = externals / "opencv"
    if not (opencv_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/opencv/opencv.git",
             "externals/opencv"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/opencv"], cwd=root)
    run(["git", "checkout", "4.12.0"], cwd=opencv_dir)

    contrib_dir = externals / "opencv_contrib"
    if not (contrib_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/opencv/opencv_contrib.git",
             "externals/opencv_contrib"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/opencv_contrib"], cwd=root)
    run(["git", "checkout", "4.12.0"], cwd=contrib_dir)

    run(["git", "add", ".gitmodules", "externals/opencv", "externals/opencv_contrib"], cwd=root)

    build_dir = opencv_dir / "build"
    opencv_output = opencv_dir / "build-output"
    
    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (opencv_output / "lib" / "libopencv_core.so").exists() and \
       not (opencv_output / "lib" / "libopencv_core.dylib").exists() and \
       not (opencv_output / "lib" / "opencv_core.lib").exists():
        build_dir.mkdir(exist_ok=True)
        
        cmake_args = [
            "cmake", "..",
            "-DCMAKE_BUILD_TYPE=Release",
            f"-DCMAKE_INSTALL_PREFIX={opencv_output}",
            "-DBUILD_LIST=core,imgproc,imgcodecs,highgui,video,videoio,calib3d,features2d,flann,objdetect,photo,stitching",
            "-DBUILD_EXAMPLES=OFF",
            "-DBUILD_TESTS=OFF",
            "-DBUILD_PERF_TESTS=OFF",
            "-DBUILD_DOCS=OFF",
            "-DWITH_OPENMP=ON",
            "-DCPU_BASELINE=SSE3",
            "-DCPU_DISPATCH=SSE4_1,SSE4_2,AVX",
            "-DWITH_GTK=OFF",
            "-DWITH_QT=OFF",
            "-DWITH_FFMPEG=OFF",
            "-DWITH_GSTREAMER=OFF",
        ]
        
        if contrib_dir.exists():
            cmake_args.append(f"-DOPENCV_EXTRA_MODULES_PATH={contrib_dir}/modules")
        
        run(cmake_args, cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "opencv_config.cmake"
    cmake_config.write_text(f"""# Automagically generated by opencv_fetcher.py
set(OpenCV_DIR "{opencv_output}/lib/cmake/opencv4")
find_package(OpenCV REQUIRED PATHS "${{OpenCV_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/opencv_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    global_block = """# Automagically added by opencv_fetcher.py
include_directories(${OpenCV_INCLUDE_DIRS})
link_libraries(${OpenCV_LIBS})
"""
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${OpenCV_INCLUDE_DIRS})
"""
    
    if project_cmake.exists():
        content = project_cmake.read_text()
        if "OpenCV_INCLUDE_DIRS" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "include(AhoiCppExternals.cmake)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx == 0:
                for i, line in enumerate(lines):
                    if "project(" in line.lower():
                        insert_idx = i + 1
                        break
            lines.insert(insert_idx, global_block)
            
            insert_idx2 = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx2 = i + 1
                    break
            if insert_idx2 > 0:
                lines.insert(insert_idx2, target_block)
            
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
    ]]
end

function M.get_curl_fetcher()
	return [[import subprocess
import sys
from pathlib import Path


def run(cmd, cwd=None, ok_codes=(0,)):
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode not in ok_codes:
        sys.exit(result.returncode)
    return result


def main():
    root = Path(__file__).resolve().parent.parent
    externals = root / "externals"
    externals.mkdir(exist_ok=True)

    curl_dir = externals / "curl"
    if not (curl_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/curl/curl.git",
             "externals/curl"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/curl"], cwd=root)
    run(["git", "checkout", "curl-8_11_0"], cwd=curl_dir)

    run(["git", "add", ".gitmodules", "externals/curl"], cwd=root)

    curl_output = curl_dir / "build-output"
    build_dir = curl_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (curl_output / "lib" / "libcurl.so").exists() and \
       not (curl_output / "lib" / "libcurl.dylib").exists() and \
       not (curl_output / "lib" / "libcurl.lib").exists():
        build_dir.mkdir(exist_ok=True)
        
        cmake_args = [
            "cmake", "..",
            "-DCMAKE_BUILD_TYPE=Release",
            f"-DCMAKE_INSTALL_PREFIX={curl_output}",
            "-DBUILD_SHARED_LIBS=ON",
            "-DBUILD_CURL_EXE=OFF",
            "-DBUILD_TESTING=OFF",
            "-DCURL_USE_OPENSSL=OFF",
            "-DCURL_USE_SCHANNEL=ON" if sys.platform == "win32" else "-DCURL_USE_OPENSSL=OFF",
            "-DHTTP_ONLY=OFF",
            "-DCURL_DISABLE_LDAP=ON",
            "-DCURL_DISABLE_LDAPS=ON",
            "-DCURL_ZLIB=OFF",
            "-DCURL_BROTLI=OFF",
            "-DCURL_ZSTD=OFF",
            "-DUSE_NGHTTP2=OFF",
            "-DUSE_LIBIDN2=OFF",
        ]
        
        if sys.platform == "darwin":
            cmake_args.append("-DCURL_USE_SECTRANSP=ON")
        elif sys.platform != "win32":
            cmake_args.append("-DCURL_USE_OPENSSL=ON")
        
        run(cmake_args, cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "curl_config.cmake"
    cmake_config.write_text(f"""# Automagically generated by curl_fetcher.py
set(CURL_INCLUDE_DIR "{curl_output / "include"}")
set(CURL_LIB_DIR "{curl_output / "lib"}")
find_library(CURL_LIBRARY curl PATHS "${{CURL_LIB_DIR}}" NO_DEFAULT_PATH)
if(NOT CURL_LIBRARY)
    find_library(CURL_LIBRARY libcurl PATHS "${{CURL_LIB_DIR}}" NO_DEFAULT_PATH)
endif()
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/curl_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    global_block = f"""# Automagically added by curl_fetcher.py
include_directories(${{CURL_INCLUDE_DIR}})
link_directories(${{CURL_LIB_DIR}})
link_libraries(${{CURL_LIBRARY}})
"""
    target_block = f"""target_include_directories(ahoicpp_externals INTERFACE ${{CURL_INCLUDE_DIR}})
"""
    
    if project_cmake.exists():
        content = project_cmake.read_text()
        if "CURL_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "include(AhoiCppExternals.cmake)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx == 0:
                for i, line in enumerate(lines):
                    if "project(" in line.lower():
                        insert_idx = i + 1
                        break
            lines.insert(insert_idx, global_block)
            
            insert_idx2 = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx2 = i + 1
                    break
            if insert_idx2 > 0:
                lines.insert(insert_idx2, target_block)
            
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

return M
