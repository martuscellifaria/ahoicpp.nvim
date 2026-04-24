# AhoiCpp

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.11+-blue.svg?logo=neovim)](https://neovim.io/)

A.H.O.I. Labs (Alex's Heavily Opinionated Interfaces) presents you `AhoiCpp`.

AhoiCpp is an opinionated way to start cross platform C++ projects in Neovim.
AhoiCpp lets you create classes, libraries and your own app entrypoint with the respective build process.

## Dependencies

AhoiCpp assumes you have a C++ 23 capable compiler (I use g++ 14.3.0 on my development environment), `cmake`, `git` and `python` installed. If not, you should do it first.
Of course you have to have `Neovim` as well, version `0.11` or higher is recommended, since some `vim.api` and `vim.fn` functions are new.

&nbsp;

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'martuscellifaria/ahoicpp.nvim',
    config = function()
      require('ahoicpp').setup()
    end,
}
```

### Manual Installation

Clone the repository and add it to your Neovim runtime path:

```bash
git clone https://github.com/martuscellifaria/ahoicpp.nvim ~/.config/nvim/pack/plugins/start/ahoicpp.nvim
```

&nbsp;

## Usage

### Default Keymaps

| Command       | Description                                                                  |
| ------------- | ---------------------------------------------------------------------------- |
| `<leader>cph` | Opens the about/help menu from AhoiCpp                                       |
| `<leader>cpa` | Creates C++ application with respective CMake files and scripts              |
| `<leader>cpm` | Creates C++ class within modules directory and add CMake files               |
| `<leader>cpd` | Creates C++ class within custom named directory and add CMake files          |
| `<leader>cpe` | Clones external Git repository to the externals directory of the C++ project |
| `<leader>cpt` | Toggles autocompilation at module and/or app creation (enabled by default)   |
| `<leader>cpc` | Compiles the current C++ project                                             |

### Configuration

AhoiCpp provides a configurable interface. The default follows:

```lua
{
    autocompile_on_create = true,
    compile_as_debug = false,
    enable_popups = true,
    git_init = true,
    keymaps = {
        group_c  = "<leader>c",
        group_cp = "<leader>cp", 
        help = "<leader>cph",
        create_app = "<leader>cpa",
        create_module = "<leader>cpm",
        create_module_dir = "<leader>cpd",
        clone_external = "<leader>cpe",
        toggle_autocompile = "<leader>cpt",
        compile = "<leader>cpc",
    },
}
```

You are also able to override the keymap bindings, for example:

```lua
{
    'martuscellifaria/ahoicpp.nvim',
    config = function()
      require('ahoicpp').setup({keymaps = {compile = "<leader>cc"}})
    end,
}
```

### Project structure

After running `<leader>cpa YourApp`:

```
YourApp/
├── .ahoicpp
├── .gitignore
├── .git/
├── CMakeLists.txt
├── AhoiCppProject.cmake
├── AhoiCppExternals.cmake
├── build.py
├── App/
│   ├── AhoiCppSubdirs.cmake
│   ├── CMakeLists.txt
│   ├── src/
│   │   └── YourApp.cpp
│   └── version.h.in (or version.rc.in)
├── Modules/           (created when you add modules)
└── externals/         (created for Git dependencies)
    └── README.md
```

## Demo

### Creating and getting your first C++ app compiled

![AhoiCpp short demo 1](./assets/01_create_first_app.gif)

### Adding new classes to your project

![AhoiCpp short demo 2](./assets/02_create_first_module.gif)

### Adding external dependencies from git repositories

![AhoiCpp short demo 3](./assets/03_clone_external_dependency.gif)

## Check Health

For health status of AhoiCpp, you can always run `:checkhealth ahoicpp` from the Neovim command line.

## Tests

### Running tests

AhoiCpp uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing. To run the tests:

    1. Ensure Plenary.nvim is installed.
    2. Navigate to the plugin directory: 
    ```bash
    cd ~/.local/share/nvim/lazy/ahoicpp.nvim
    ```
    3. Run the tests from the command line:
    ```bash
    nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/spec', { minimal_init = 'tests/minimal_init.lua' })" -c "qa"
    ```

You can of course run the tests from inside Neovim. Just navigate to the directory where ahoicpp is installed, open neovim and then run:

```vim
:lua require('plenary.test_harness').test_directory('tests/spec', { minimal_init = 'tests/minimal_init.lua' })
```

For single file testing, you can use:

```vim
:lua require('plenary.test_harness').test_file('tests/spec/utils_spec.lua', { minimal_init = 'tests/minimal_init.lua' })
```

### Test tree

The tests for AhoiCpp are structured as follows:

```
tests/
├── minimal_init.lua       # Test environment setup
└── spec/
    ├── utils_spec.lua     # Filesystem and validation tests
    ├── config_spec.lua    # Configuration tests
    ├── templates_spec.lua # Template generation tests
    ├── project_spec.lua   # Project creation tests
    └── build_spec.lua     # Build system tests
```

## Troubleshooting

| Error                        | Solution                               |
| ---------------------------- | -------------------------------------- |
| "AhoiCpp is not initialized" | Run `<leader>cpa` first                |
| "Python not found"           | Install Python and ensure it's in PATH |
| Compilation fails            | Check `build/build.log`                |

## License

MIT (see [LICENSE](LICENSE) for details)
