import subprocess
import sys
from pathlib import Path


def run(cmd, cwd=None, ok_codes=(0,)):
    result = subprocess.run(cmd, cwd=cwd)
    if result.returncode not in ok_codes:
        sys.exit(result.returncode)
    return result


def get_nproc():
    return str(Path("/proc/cpuinfo").read_text().count("processor")) if Path("/proc/cpuinfo").exists() else "4"


def clone_or_update_submodule(root, lib_name, repo_url, tag):
    externals = root / "externals"
    externals.mkdir(exist_ok=True)
    
    lib_dir = externals / lib_name
    if not (lib_dir / ".git").exists():
        run(["git", "submodule", "add", repo_url, f"externals/{lib_name}"], cwd=root)
    else:
        run(["git", "submodule", "update", "--init", f"externals/{lib_name}"], cwd=root)
    run(["git", "checkout", tag], cwd=lib_dir)
    
    return lib_dir


def add_to_git(root, items):
    run(["git", "add", ".gitmodules"] + items, cwd=root)


def configure_cmake(lib_dir, output_dir, cmake_args):
    build_dir = lib_dir / "build"
    build_dir.mkdir(exist_ok=True)
    
    cmake_cmd = [
        "cmake", "..",
        "-DCMAKE_BUILD_TYPE=Release",
        f"-DCMAKE_INSTALL_PREFIX={output_dir}",
    ] + cmake_args
    
    run(cmake_cmd, cwd=build_dir)
    run(["cmake", "--build", ".", "--parallel", get_nproc()], cwd=build_dir)
    run(["cmake", "--install", "."], cwd=build_dir)


def write_cmake_config(externals, config_name, content):
    cmake_config = externals / config_name
    cmake_config.write_text(content)


def append_to_externals_cmake(root, include_line):
    externals_cmake = root / "AhoiCppExternals.cmake"
    if externals_cmake.exists():
        content = externals_cmake.read_text()
        if include_line not in content:
            with externals_cmake.open("a") as f:
                f.write(f"\n{include_line}\n")


def append_to_project_cmake(root, check_string, target_block):
    project_cmake = root / "CMakeLists.txt"
    if project_cmake.exists():
        content = project_cmake.read_text()
        if check_string not in content:
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
