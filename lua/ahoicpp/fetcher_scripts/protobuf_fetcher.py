import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    protobuf_dir = clone_or_update_submodule(root, "protobuf", 
                                            "https://github.com/protocolbuffers/protobuf.git", 
                                            "v27.0")
    run(["git", "submodule", "update", "--init"], cwd=protobuf_dir)
    
    add_to_git(root, ["externals/protobuf"])
    
    protobuf_output = protobuf_dir / "build-output"
    
    if not (protobuf_output / "lib" / "libprotobuf.a").exists() and \
       not (protobuf_output / "lib" / "libprotobuf.dylib").exists() and \
       not (protobuf_output / "lib" / "libprotobuf.lib").exists():
        configure_cmake(protobuf_dir, protobuf_output, [
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
            "-Dprotobuf_BUILD_TESTS=OFF",
            "-Dprotobuf_BUILD_SHARED_LIBS=OFF",
            "-Dprotobuf_BUILD_PROTOC_BINARIES=ON",
            "-Dprotobuf_ABSL_PROVIDER=module"
        ])
    
    write_cmake_config(root / "externals", "protobuf_config.cmake", f"""set(Protobuf_DIR "{protobuf_output / "lib" / "cmake" / "protobuf"}")
find_package(Protobuf REQUIRED PATHS "${{Protobuf_DIR}}" NO_DEFAULT_PATH)
set(absl_DIR "{protobuf_output / "lib" / "cmake" / "absl"}")
find_package(absl REQUIRED PATHS "${{absl_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/protobuf_config.cmake")')
    
    append_to_project_cmake(root, "protobuf::libprotobuf", """target_include_directories(ahoicpp_externals INTERFACE ${Protobuf_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE protobuf::libprotobuf)
""")


if __name__ == "__main__":
    main()
