# AhoiCpp

A.H.O.I. Labs (Alex's Heavily Opinionated Interfaces) presents you `AhoiCpp`.

AhoiCpp consists of an opinionated way of starting cross platform C++ projects in Neovim.
AhoiCpp lets you create classes, libraries and your own app entrypoint with the respective build process.

AhoiCpp assumes you are using cmake and have python installed. If not, you should do it first.


&nbsp;
## Installation

If your Neovim distro is based on Lazy ([lazy.nvim](https://github.com/folke/lazy.nvim), you can follow the steps below. Otherwise, you might have to do things manually, which is also perfectly fine.

Create an `ahoicpp.lua` file with the following contents at the plugins directory of your Neovim distro. For me, it is `kickstart`, so at `.config/nvim/lua/custom/plugins`

```lua
return {
  {
    'martuscellifaria/ahoicpp.nvim',
    config = function()
      local opts = { noremap = true, silent = true }
      require 'ahoicpp'
    end,
  },
}
```

&nbsp;
## Usage

### Commands

| Command       | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `<leader>cph` | Opens the about/help menu from AhoiCpp                              |
| `<leader>cpa` | Creates C++ application with respective CMake files and scripts     |
| `<leader>cpm` | Creates C++ class within Modules directory and add CMake files      |
| `<leader>cpd` | Creates C++ class within custom named directory and add CMake files |
| `<leader>cpc` | Compiles the current C++ project                                    |

### License

AhoiCpp is licensed under MIT License
