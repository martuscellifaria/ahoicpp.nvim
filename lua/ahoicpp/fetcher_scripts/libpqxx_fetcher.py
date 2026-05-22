import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    postgres_dir = clone_or_update_submodule(root, "postgres", 
                                            "https://github.com/postgres/postgres.git", 
                                            "REL_16_2")
    
    libpqxx_dir = clone_or_update_submodule(root, "libpqxx", 
                                           "https://github.com/jtv/libpqxx.git", 
                                           "7.9.2")
    
    add_to_git(root, ["externals/libpqxx", "externals/postgres"])
    
    pq_output = postgres_dir / "build-output"
    if not (pq_output / "lib" / "libpq.so").exists() and \
       not (pq_output / "lib" / "libpq.dylib").exists() and \
       not (pq_output / "lib" / "libpq.lib").exists():
        run(["./configure", f"--prefix={pq_output}", "--without-readline",
             "--without-zlib", "CFLAGS=-std=c17"], cwd=postgres_dir)
        nproc = get_nproc()
        run(["make", "-C", "src/interfaces/libpq", "-j", nproc], cwd=postgres_dir)
        run(["make", "-C", "src/interfaces/libpq", "install"], cwd=postgres_dir)
        run(["make", "-C", "src/include", "install"], cwd=postgres_dir)
        run(["make", "-C", "src/port", "install"], cwd=postgres_dir)
    
    pqxx_output = libpqxx_dir / "build-output"
    if not (pqxx_output / "lib" / "libpqxx-7.9.so").exists() and \
       not (pqxx_output / "lib" / "libpqxx-7.9.dylib").exists():
        configure_cmake(libpqxx_dir, pqxx_output, [
            f"-DCMAKE_PREFIX_PATH={pq_output}",
            "-DBUILD_SHARED_LIBS=ON",
            "-DSKIP_BUILD_TEST=ON"
        ])
    
    write_cmake_config(root / "externals", "libpqxx_config.cmake", f"""set(LIBPQXX_INCLUDE_DIR "{pqxx_output / "include"}")
set(LIBPQ_INCLUDE_DIR "{pq_output / "include"}")
set(LIBPQXX_LIB_DIR "{pqxx_output / "lib"}")
set(LIBPQ_LIB_DIR "{pq_output / "lib"}")
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/libpqxx_config.cmake")')
    
    append_to_project_cmake(root, "LIBPQXX_INCLUDE_DIR", f"""target_include_directories(ahoicpp_externals INTERFACE ${{LIBPQXX_INCLUDE_DIR}} ${{LIBPQ_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{LIBPQXX_LIB_DIR}} ${{LIBPQ_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE pqxx pq)
""")

if __name__ == "__main__":
    main()
