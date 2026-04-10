# AhoiCpp

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.11+-blue.svg)](https://neovim.io/)

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
      require('ahoicpp').setup({keymaps = {compile = "<leader>cc",}})
    end,

}
```

### Project structure

After running `<leader>cpa YourApp`:

```
YourApp/
├── .ahoicpp
├── .gitignore
├── CMakeLists.txt
├── AhoiCppProject.cmake
├── build.py
├── App/
│   ├── CMakeLists.txt
│   ├── src/
│   │   └── YourApp.cpp
│   └── version.h.in (or version.rc.in)
├── Modules/           (created when you add modules)
└── externals/         (created for Git dependencies)
    └── README.md
```

## Troubleshooting

| Error                        | Solution                               |
| ---------------------------- | -------------------------------------- |
| "AhoiCpp is not initialized" | Run `<leader>cpa` first                |
| "Python not found"           | Install Python and ensure it's in PATH |
| Compilation fails            | Check `build/build.log`                |

## License

MIT (see LICENSE file for details)
