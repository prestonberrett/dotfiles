vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set expandtab")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.loaded_matchparen = 1

vim.opt.guicursor = ""

vim.opt.conceallevel = 0

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.hidden = true
vim.opt.errorbells = false

vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- vim.opt.tabstop = 2
-- vim.opt.softtabstop = 2
-- vim.opt.shiftwidth = 2
-- vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.swapfile = false
vim.opt.backup = false

-- if utils.OS() == 'unix' then
--   vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- end

vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.showmatch = true

vim.opt.wildmenu = true

vim.opt.termguicolors = true

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Give more space for displaying messages.
vim.opt.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50

vim.opt.colorcolumn = "120"

vim.opt.clipboard = "unnamedplus"
vim.opt.encoding = "UTF-8"
vim.opt.modifiable = true
-- vim.opt.background = "dark"
vim.opt.guicursor =
	"n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

--Copilot setup
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.opt.splitright = true

--Options that I don't know how to toggle with lua
vim.cmd([[
  syntax on
  highlight Normal guibg=none

  filetype indent on
  filetype plugin on
]])
