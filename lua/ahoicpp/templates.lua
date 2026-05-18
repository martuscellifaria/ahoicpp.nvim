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
        make -j$(nproc) > build.log 2>&1

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
    elif shutil.which("make") is not None:
        build_command = f"""
        cd build && cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE={build_type} -DVERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && make -j $env:NUMBER_OF_PROCESSORS > build.log 2>&1
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
	"build_path": "./build/App/",
	"execution_path": "./build/App/",
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
    cmake_config.write_text(f"""set(LIBPQXX_INCLUDE_DIR "{pqxx_output / "include"}")
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
    target_block = f"""target_include_directories(ahoicpp_externals INTERFACE ${{LIBPQXX_INCLUDE_DIR}} ${{LIBPQ_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{LIBPQXX_LIB_DIR}} ${{LIBPQ_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE pqxx pq)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "LIBPQXX_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
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
    cmake_config.write_text(f"""set(OpenCV_DIR "{opencv_output}/lib/cmake/opencv4")
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
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE ${OpenCV_LIBS})
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "OpenCV_INCLUDE_DIRS" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
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
    cmake_config.write_text(f"""set(CURL_INCLUDE_DIR "{curl_output / "include"}")
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
    target_block = f"""target_include_directories(ahoicpp_externals INTERFACE ${{CURL_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{CURL_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE ${{CURL_LIBRARY}})
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "CURL_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_botan_fetcher()
	return [[import subprocess
import sys
import os
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

    botan_dir = externals / "botan"
    if not (botan_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/randombit/botan.git",
             "externals/botan"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/botan"], cwd=root)
    run(["git", "checkout", "3.7.0"], cwd=botan_dir)

    run(["git", "add", ".gitmodules", "externals/botan"], cwd=root)

    botan_output = botan_dir / "build-output"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (botan_output / "lib" / "libbotan-3.a").exists():
        configure_cmd = [
            sys.executable, "./configure.py",
            f"--prefix={botan_output}",
            "--amalgamation",
            "--cc=gcc",
        ]
        run(configure_cmd, cwd=botan_dir)
        run(["make", "-j", nproc], cwd=botan_dir)
        run(["make", "install"], cwd=botan_dir)

    cmake_config = externals / "botan_config.cmake"
    cmake_config.write_text(f"""set(BOTAN_INCLUDE_DIR "{botan_output / "include" / "botan-3"}")
set(BOTAN_LIB_DIR "{botan_output / "lib"}")
find_library(BOTAN_LIBRARY botan-3 PATHS "${{BOTAN_LIB_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/botan_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = f"""target_include_directories(ahoicpp_externals INTERFACE ${{BOTAN_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{BOTAN_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE ${{BOTAN_LIBRARY}})
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "BOTAN_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_eigen_fetcher()
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

    eigen_dir = externals / "eigen"
    if not (eigen_dir / ".git").exists():
        run(["git", "submodule", "add", "https://gitlab.com/libeigen/eigen.git",
             "externals/eigen"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/eigen"], cwd=root)
    run(["git", "checkout", "3.4.0"], cwd=eigen_dir)

    run(["git", "add", ".gitmodules", "externals/eigen"], cwd=root)

    eigen_output = eigen_dir / "build-output"
    build_dir = eigen_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (eigen_output / "share" / "eigen3" / "cmake" / "Eigen3Config.cmake").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={eigen_output}",
             "-DBUILD_TESTING=OFF"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "eigen_config.cmake"
    cmake_config.write_text(f"""set(Eigen3_DIR "{eigen_output / "share" / "eigen3" / "cmake"}")
find_package(Eigen3 REQUIRED PATHS "${{Eigen3_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/eigen_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${EIGEN3_INCLUDE_DIR})
target_link_libraries(ahoicpp_externals INTERFACE Eigen3::Eigen)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "EIGEN3_INCLUDE_DIR" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_grpc_fetcher()
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

    grpc_dir = externals / "grpc"
    if not (grpc_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/grpc/grpc.git",
             "externals/grpc"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/grpc"], cwd=root)
    run(["git", "checkout", "v1.60.0"], cwd=grpc_dir)
    run(["git", "submodule", "update", "--init"], cwd=grpc_dir)

    run(["git", "add", ".gitmodules", "externals/grpc"], cwd=root)

    grpc_output = grpc_dir / "build-output"
    build_dir = grpc_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (grpc_output / "lib" / "libgrpc++.a").exists() and \
       not (grpc_output / "lib" / "libgrpc++.dylib").exists() and \
       not (grpc_output / "lib" / "grpc++.lib").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={grpc_output}",
             "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
             "-DgRPC_INSTALL=ON",
             "-DgRPC_BUILD_TESTS=OFF",
             "-DgRPC_BUILD_CSHARP_EXT=OFF",
             "-DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF",
             "-DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF",
             "-DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF",
             "-DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF",
             "-DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF",
             "-DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF",
             "-DgRPC_PROTOBUF_PROVIDER=module",
             "-DgRPC_ZLIB_PROVIDER=module",
             "-DgRPC_SSL_PROVIDER=module",
             "-DgRPC_ABSL_PROVIDER=module"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "grpc_config.cmake"
    cmake_config.write_text(f"""set(absl_DIR "{grpc_output / "lib" / "cmake" / "absl"}")
find_package(absl REQUIRED PATHS "${{absl_DIR}}" NO_DEFAULT_PATH)
set(Protobuf_DIR "{grpc_output / "lib" / "cmake" / "protobuf"}")
find_package(Protobuf REQUIRED PATHS "${{Protobuf_DIR}}" NO_DEFAULT_PATH)
set(gRPC_DIR "{grpc_output / "lib" / "cmake" / "grpc"}")
find_package(gRPC REQUIRED PATHS "${{gRPC_DIR}}" NO_DEFAULT_PATH)
set(utf8_range_DIR "{grpc_output / "lib" / "cmake" / "utf8_range"}")
find_package(utf8_range REQUIRED PATHS "${{utf8_range_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/grpc_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${Protobuf_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE gRPC::grpc++)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "gRPC::grpc++" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_protobuf_fetcher()
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

    protobuf_dir = externals / "protobuf"
    if not (protobuf_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/protocolbuffers/protobuf.git",
             "externals/protobuf"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/protobuf"], cwd=root)
    run(["git", "checkout", "v27.0"], cwd=protobuf_dir)
    run(["git", "submodule", "update", "--init"], cwd=protobuf_dir)

    run(["git", "add", ".gitmodules", "externals/protobuf"], cwd=root)

    protobuf_output = protobuf_dir / "build-output"
    build_dir = protobuf_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (protobuf_output / "lib" / "libprotobuf.a").exists() and \
       not (protobuf_output / "lib" / "libprotobuf.dylib").exists() and \
       not (protobuf_output / "lib" / "libprotobuf.lib").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={protobuf_output}",
             "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
             "-Dprotobuf_BUILD_TESTS=OFF",
             "-Dprotobuf_BUILD_SHARED_LIBS=OFF",
             "-Dprotobuf_BUILD_PROTOC_BINARIES=ON",
             "-Dprotobuf_ABSL_PROVIDER=module"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "protobuf_config.cmake"
    cmake_config.write_text(f"""set(Protobuf_DIR "{protobuf_output / "lib" / "cmake" / "protobuf"}")
find_package(Protobuf REQUIRED PATHS "${{Protobuf_DIR}}" NO_DEFAULT_PATH)
set(absl_DIR "{protobuf_output / "lib" / "cmake" / "absl"}")
find_package(absl REQUIRED PATHS "${{absl_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/protobuf_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${Protobuf_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE protobuf::libprotobuf)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "protobuf::libprotobuf" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_spdlog_fetcher()
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

    spdlog_dir = externals / "spdlog"
    if not (spdlog_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/gabime/spdlog.git",
             "externals/spdlog"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/spdlog"], cwd=root)
    run(["git", "checkout", "v1.14.1"], cwd=spdlog_dir)

    run(["git", "add", ".gitmodules", "externals/spdlog"], cwd=root)

    spdlog_output = spdlog_dir / "build-output"
    build_dir = spdlog_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (spdlog_output / "lib" / "libspdlog.a").exists() and \
       not (spdlog_output / "lib" / "libspdlog.dylib").exists() and \
       not (spdlog_output / "lib" / "spdlog.lib").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={spdlog_output}",
             "-DSPDLOG_BUILD_SHARED=OFF",
             "-DSPDLOG_BUILD_EXAMPLE=OFF",
             "-DSPDLOG_BUILD_TESTS=OFF",
             "-DSPDLOG_FMT_EXTERNAL=OFF"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "spdlog_config.cmake"
    cmake_config.write_text(f"""set(spdlog_DIR "{spdlog_output / "lib" / "cmake" / "spdlog"}")
find_package(spdlog REQUIRED PATHS "${{spdlog_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/spdlog_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = """target_link_libraries(ahoicpp_externals INTERFACE spdlog::spdlog)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "spdlog::spdlog" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
]]
end

function M.get_open62541_fetcher()
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

    open62541_dir = externals / "open62541"
    if not (open62541_dir / ".git").exists():
        run(["git", "submodule", "add", "https://github.com/open62541/open62541.git",
             "externals/open62541"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", "externals/open62541"], cwd=root)
    run(["git", "checkout", "v1.5.0"], cwd=open62541_dir)
    run(["git", "submodule", "update", "--init", "--recursive"], cwd=open62541_dir)

    run(["git", "add", ".gitmodules", "externals/open62541"], cwd=root)

    open62541_output = open62541_dir / "build-output"
    build_dir = open62541_dir / "build"

    nproc = str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"

    if not (open62541_output / "lib" / "libopen62541.a").exists() and \
       not (open62541_output / "lib" / "libopen62541.so").exists() and \
       not (open62541_output / "lib" / "libopen62541.dylib").exists() and \
       not (open62541_output / "lib" / "open62541.lib").exists():
        build_dir.mkdir(exist_ok=True)
        run(["cmake", "..",
             "-DCMAKE_BUILD_TYPE=Release",
             f"-DCMAKE_INSTALL_PREFIX={open62541_output}",
             "-DBUILD_SHARED_LIBS=ON",
             "-DUA_NAMESPACE_ZERO=FULL",
             "-DUA_ENABLE_AMALGAMATION=OFF",
             "-DUA_BUILD_EXAMPLES=OFF",
             "-DUA_BUILD_UNIT_TESTS=OFF",
             "-DUA_MULTITHREADING=100",
             "-DUA_ENABLE_SUBSCRIPTIONS=ON",
             "-DUA_ENABLE_METHODCALLS=ON",
             "-DUA_ENABLE_NODEMANAGEMENT=ON",
             "-DUA_ENABLE_DISCOVERY=ON",
             "-DUA_ENABLE_DISCOVERY_MULTICAST=ON",
             "-DUA_ENABLE_ENCRYPTION=OFF"], cwd=build_dir)
        run(["cmake", "--build", ".", "--parallel", nproc], cwd=build_dir)
        run(["cmake", "--install", "."], cwd=build_dir)

    cmake_config = externals / "open62541_config.cmake"
    cmake_config.write_text(f"""set(open62541_DIR "{open62541_output / "lib" / "cmake" / "open62541"}")
find_package(open62541 REQUIRED PATHS "${{open62541_DIR}}" NO_DEFAULT_PATH)
""")

    externals_cmake = root / "AhoiCppExternals.cmake"
    include_line = 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/open62541_config.cmake")'

    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")

    project_cmake = root / "CMakeLists.txt"
    target_block = """target_include_directories(ahoicpp_externals INTERFACE ${open62541_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE open62541::open62541)
"""

    if project_cmake.exists():
        content = project_cmake.read_text()
        if "open62541::open62541" not in content:
            lines = content.splitlines()
            insert_idx = 0
            for i, line in enumerate(lines):
                if "add_library(ahoicpp_externals INTERFACE)" in line:
                    insert_idx = i + 1
                    break
            if insert_idx > 0:
                while insert_idx < len(lines) and lines[insert_idx].strip() != "endforeach()":
                    insert_idx += 1
                insert_idx += 1
            lines.insert(insert_idx, target_block)
            project_cmake.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()]]
end
return M
