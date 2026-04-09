# AhoiCpp

A.H.O.I. Labs (Alex's Heavily Opinionated Interfaces) presents you `AhoiCpp`.

AhoiCpp consists of an opinionated way of starting cross platform C++ projects in Neovim.
AhoiCpp lets you create classes, libraries and your own app entrypoint with the respective build process.

## Dependencies

AhoiCpp assumes you have a C++ 23 capable compiler (I use g++ 14.3.0 on my development environment), `cmake`, `git` and `python` installed. If not, you should do it first.
Of course you have to have `Neovim` as well, version `0.11` or higher is recommended, since some `vim.api` and `vim.fn` functions are new.

&nbsp;
## Installation

If your Neovim distro is based on Lazy ([lazy.nvim](https://github.com/folke/lazy.nvim), you can follow the steps below. Otherwise, you might have to do things manually, which is also perfectly fine.

I recommend creating an `ahoicpp.lua` file with the following contents at the plugins directory of your Neovim distro. For me, it is `kickstart`, so at `.config/nvim/lua/custom/plugins`. However, you can also paste these contents at your `init.lua` file or wherever it is more convenient to you.

```lua
{
    'martuscellifaria/ahoicpp.nvim',
    config = function()
      local opts = { noremap = true, silent = true }
      require 'ahoicpp'
    end,
}
```

&nbsp;
## Usage

### Commands

| Command       | Description                                                                  |
| ------------- | ---------------------------------------------------------------------------- |
| `<leader>cph` | Opens the about/help menu from AhoiCpp                                       |
| `<leader>cpa` | Creates C++ application with respective CMake files and scripts              |
| `<leader>cpm` | Creates C++ class within modules directory and add CMake files               |
| `<leader>cpd` | Creates C++ class within custom named directory and add CMake files          |
| `<leader>cpe` | Clones external Git repository to the externals directory of the C++ project |
| `<leader>cpt` | Toggles autocompilation at module and/or app creation (enabled by default)   |
| `<leader>cpc` | Compiles the current C++ project                                             |

### License

AhoiCpp is licensed under MIT License
