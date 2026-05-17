from pathlib import Path
import fetcher

def main():
    root = Path(__file__).resolve().parent.parent
    
    eigen_dir = clone_or_update_submodule(root, "eigen", 
                                         "https://gitlab.com/libeigen/eigen.git", 
                                         "3.4.0")
    
    add_to_git(root, ["externals/eigen"])
    
    eigen_output = eigen_dir / "build-output"
    
    if not (eigen_output / "share" / "eigen3" / "cmake" / "Eigen3Config.cmake").exists():
        configure_cmake(eigen_dir, eigen_output, ["-DBUILD_TESTING=OFF"])
    
    write_cmake_config(root / "externals", "eigen_config.cmake", f"""set(Eigen3_DIR "{eigen_output / "share" / "eigen3" / "cmake"}")
find_package(Eigen3 REQUIRED PATHS "${{Eigen3_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/eigen_config.cmake")')
    
    append_to_project_cmake(root, "EIGEN3_INCLUDE_DIR", """target_include_directories(ahoicpp_externals INTERFACE ${EIGEN3_INCLUDE_DIR})
target_link_libraries(ahoicpp_externals INTERFACE Eigen3::Eigen)
""")


if __name__ == "__main__":
    main()
