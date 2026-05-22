import sys
from pathlib import Path
from fetcher import run, get_nproc, clone_or_update_submodule, add_to_git, configure_cmake, write_cmake_config, append_to_externals_cmake, append_to_project_cmake

def main():
    root = Path(__file__).resolve().parent.parent
    
    opencv_dir = clone_or_update_submodule(root, "opencv", 
                                          "https://github.com/opencv/opencv.git", 
                                          "4.12.0")
    
    contrib_dir = clone_or_update_submodule(root, "opencv_contrib", 
                                           "https://github.com/opencv/opencv_contrib.git", 
                                           "4.12.0")
    
    add_to_git(root, ["externals/opencv", "externals/opencv_contrib"])
    
    opencv_output = opencv_dir / "build-output"
    cmake_args = [
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
    
    if not (opencv_output / "lib" / "libopencv_core.so").exists() and \
       not (opencv_output / "lib" / "libopencv_core.dylib").exists() and \
       not (opencv_output / "lib" / "opencv_core.lib").exists():
        configure_cmake(opencv_dir, opencv_output, cmake_args)
    
    write_cmake_config(root / "externals", "opencv_config.cmake", f"""set(OpenCV_DIR "{opencv_output}/lib/cmake/opencv4")
find_package(OpenCV REQUIRED PATHS "${{OpenCV_DIR}}" NO_DEFAULT_PATH)
""")
    
    append_to_externals_cmake(root, 'include("${CMAKE_CURRENT_SOURCE_DIR}/externals/opencv_config.cmake")')
    
    append_to_project_cmake(root, "OpenCV_INCLUDE_DIRS", """target_include_directories(ahoicpp_externals INTERFACE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(ahoicpp_externals INTERFACE ${OpenCV_LIBS})
""")


if __name__ == "__main__":
    main()

