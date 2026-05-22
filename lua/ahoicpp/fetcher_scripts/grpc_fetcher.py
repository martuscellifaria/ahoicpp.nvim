import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    grpc_dir = clone_or_update_submodule(root, "grpc", 
                                        "https://github.com/grpc/grpc.git", 
                                        "v1.60.0")
    run(["git", "submodule", "update", "--init"], cwd=grpc_dir)
    
    add_to_git(root, ["externals/grpc"])
    
    grpc_output = grpc_dir / "build-output"
    
    if not (grpc_output / "lib" / "libgrpc++.a").exists() and \
       not (grpc_output / "lib" / "libgrpc++.dylib").exists() and \
       not (grpc_output / "lib" / "grpc++.lib").exists():
        configure_cmake(grpc_dir, grpc_output, [
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
            "-DgRPC_ABSL_PROVIDER=module"
        ])
    
    write_cmake_config(root / "externals", "grpc_config.cmake", f"""set(absl_DIR "{grpc_output / "lib" / "cmake" / "absl"}")
find_package(absl REQUIRED PATHS "${{absl_DIR}}" NO_DEFAULT_PATH)
set(Protobuf_DIR "{grpc_output / "lib" / "cmake" / "protobuf"}")
find_package(Protobuf REQUIRED PATHS "${{Protobuf_DIR}}" NO_DEFAULT_PATH)
set(gRPC_DIR "{grpc_output / "lib" / "cmake" / "grpc"}")
find_package(gRPC REQUIRED PATHS "${{gRPC_DIR}}" NO_DEFAULT_PATH)
set(utf8_range_DIR "{grpc_output / "lib" / "cmake" / "utf8_range"}")
find_package(utf8_range REQUIRED PATHS "${{utf8_range_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/grpc_config.cmake")')
    
    append_to_project_cmake(root, "gRPC::grpc++", """target_include_directories(ahoicpp_externals INTERFACE ${Protobuf_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE gRPC::grpc++)
""")


if __name__ == "__main__":
    main()
