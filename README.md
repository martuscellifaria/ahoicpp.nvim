# AhoiCpp

A.H.O.I. Labs (Alex's Heavily Opinionated Interfaces) presents you `AhoiCpp`.

AhoiCpp consists of an opinionated way of starting cross platform C++ projects in NeoVim.
AhoiCpp lets you create classes, libraries and your own app entrypoint with the respective build process.

AhoiCpp assumes you are using cmake and have python installed. If not, you should do it first.


&nbsp;
## Installation

If your NeoVim distro is based on Lazy ([lazy.nvim](https://github.com/folke/lazy.nvim), you can follow the steps below. Otherwise, you might have to do things manually, which is also perfectly fine.

Create an `ahoicpp.lua` file with the following contents at the plugins directory of your neovim distro. For me, it is `kickstart`, so at `.config/nvim/lua/custom/plugins`

```lua
return {
  {
    'martuscellifaria/ahoicpp.nvim',
    config = function()
      local opts = { noremap = true, silent = true }
      local ahoicpp = require 'ahoicpp'
      vim.keymap.set('n', '<leader>cpp', ahoicpp.create_class_input, { desc = 'Create C++ [c]lass' })
      vim.keymap.set('n', '<leader>cpa', ahoicpp.create_main_input, { desc = 'Create C++ [a]pp' })
      vim.keymap.set('n', '<leader>cph', ahoicpp.create_about_ahoicpp, { desc = 'Open AhoiCpp [h]elp' })
      vim.keymap.set('n', '<leader>cpm', ahoicpp.create_module_input, { desc = 'Create C++ [m]odule' })
    end,
  },
}
```

&nbsp;
## Usage

After installation:
Run `<leader>cph` (or your custom mapping for AhoiCpp help) in normal mode.
You should get a message on a floating buffer. If it happens, you are good to go.
