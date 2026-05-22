import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    open62541_dir = clone_or_update_submodule(root, "open62541", 
                                             "https://github.com/open62541/open62541.git", 
                                             "v1.5.0")
    run(["git", "submodule", "update", "--init", "--recursive"], cwd=open62541_dir)
    
    add_to_git(root, ["externals/open62541"])
    
    open62541_output = open62541_dir / "build-output"
    
    if not (open62541_output / "lib" / "libopen62541.a").exists() and \
       not (open62541_output / "lib" / "libopen62541.so").exists() and \
       not (open62541_output / "lib" / "libopen62541.dylib").exists() and \
       not (open62541_output / "lib" / "open62541.lib").exists():
        configure_cmake(open62541_dir, open62541_output, [
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
            "-DUA_ENABLE_ENCRYPTION=OFF"
        ])
    
    write_cmake_config(root / "externals", "open62541_config.cmake", f"""set(open62541_DIR "{open62541_output / "lib" / "cmake" / "open62541"}")
find_package(open62541 REQUIRED PATHS "${{open62541_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/open62541_config.cmake")')
    
    append_to_project_cmake(root, "open62541::open62541", """target_include_directories(ahoicpp_externals INTERFACE ${open62541_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE open62541::open62541)
""")


if __name__ == "__main__":
    main()

