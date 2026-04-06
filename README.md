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

### After installation
Run `<leader>cph` (or your custom mapping for AhoiCpp help) on normal mode.
You should get a welcome message on a floating buffer. If it happens, you are good to go.

### Creating and compiling your first application
On normal mode, run `<leader>cpa`. You should be prompted to a name input. Insert a name a press enter.
After that, a `hello world` application should pop at your development environment.
Run `<leader>cpc` to compile it. If everything worked fine, you will get a confirmation message. Otherwise, the error logging of the app will be opened in a new tab on Neovim.

### Adding class modules
On normal mode again, run `<leader>cpm`. You will be prompted to input you module name. This will create a `Modules` directory on your project root directory with the respective module class and the needed CMakeLists.txt files. Here you may have to do some manual work to include the files on your project.
`Note`: after doing this, go to the CMakeLists.txt file on your project root directory and uncomment `add_subdirectory(Modules)`.
