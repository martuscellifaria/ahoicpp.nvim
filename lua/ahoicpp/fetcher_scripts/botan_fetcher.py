import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    botan_dir = clone_or_update_submodule(root, "botan", 
                                         "https://github.com/randombit/botan.git", 
                                         "3.7.0")
    
    add_to_git(root, ["externals/botan"])
    
    botan_output = botan_dir / "build-output"
    
    if not (botan_output / "lib" / "libbotan-3.a").exists():
        configure_cmd = [
            sys.executable, "./configure.py",
            f"--prefix={botan_output}",
            "--amalgamation",
            "--cc=gcc",
        ]
        run(configure_cmd, cwd=botan_dir)
        run(["make", "-j", get_nproc()], cwd=botan_dir)
        run(["make", "install"], cwd=botan_dir)
    
    write_cmake_config(root / "externals", "botan_config.cmake", f"""set(BOTAN_INCLUDE_DIR "{botan_output / "include" / "botan-3"}")
set(BOTAN_LIB_DIR "{botan_output / "lib"}")
find_library(BOTAN_LIBRARY botan-3 PATHS "${{BOTAN_LIB_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/botan_config.cmake")')
    
    append_to_project_cmake(root, "BOTAN_INCLUDE_DIR", f"""target_include_directories(ahoicpp_externals INTERFACE ${{BOTAN_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{BOTAN_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE ${{BOTAN_LIBRARY}})
""")


if __name__ == "__main__":
    main()
