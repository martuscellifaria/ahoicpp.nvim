import sys
from pathlib import Path
import fetcher

def main():
    root = Path(__file__).resolve().parent.parent
    
    curl_dir = clone_or_update_submodule(root, "curl", 
                                        "https://github.com/curl/curl.git", 
                                        "curl-8_11_0")
    
    add_to_git(root, ["externals/curl"])
    
    curl_output = curl_dir / "build-output"
    cmake_args = [
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
    
    if not (curl_output / "lib" / "libcurl.so").exists() and \
       not (curl_output / "lib" / "libcurl.dylib").exists() and \
       not (curl_output / "lib" / "libcurl.lib").exists():
        configure_cmake(curl_dir, curl_output, cmake_args)
    
    write_cmake_config(root / "externals", "curl_config.cmake", f"""set(CURL_INCLUDE_DIR "{curl_output / "include"}")
set(CURL_LIB_DIR "{curl_output / "lib"}")
find_library(CURL_LIBRARY curl PATHS "${{CURL_LIB_DIR}}" NO_DEFAULT_PATH)
if(NOT CURL_LIBRARY)
    find_library(CURL_LIBRARY libcurl PATHS "${{CURL_LIB_DIR}}" NO_DEFAULT_PATH)
endif()
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/curl_config.cmake")')
    
    append_to_project_cmake(root, "CURL_INCLUDE_DIR", f"""target_include_directories(ahoicpp_externals INTERFACE ${{CURL_INCLUDE_DIR}})
target_link_directories(ahoicpp_externals INTERFACE ${{CURL_LIB_DIR}})
target_link_libraries(ahoicpp_externals INTERFACE ${{CURL_LIBRARY}})
""")


if __name__ == "__main__":
    main()
