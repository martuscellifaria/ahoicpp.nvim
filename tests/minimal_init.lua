local plugin_root = "/home/martuscellifaria/.local/share/nvim/lazy/ahoicpp.nvim"

vim.opt.runtimepath:prepend(plugin_root)
vim.opt.runtimepath:append(vim.fn.expand("~/.local/share/nvim/site/pack/vendor/start/plenary.nvim"))

vim.cmd([[
  set runtimepath+=$VIMRUNTIME
  set noswapfile
  set nobackup
  set nowritebackup
]])
