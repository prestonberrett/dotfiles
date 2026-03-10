local map = vim.api.nvim_set_keymap

map("n", "<Space>", "", {})
vim.g.mapleader = " "

local noremap_options = { noremap = true }

--NOTE: Sensible remaps, some from the Primeagen
map("v", "K", ":m '<-2<CR>gv=gv", noremap_options) -- move selected code up
map("v", "J", ":m '>+1<CR>gv=gv", noremap_options) -- move selected code down
map("i", "<C-j>", "<esc>:m .+1<CR>==", noremap_options) -- 
map("i", "<C-k>", "<esc>:m .-2<CR>==", noremap_options) -- 

--map("i", "<C-g>", "")
map("n", "<leader>k", ":m .-2<CR>==", noremap_options) -- move current line up
map("n", "<leader>j", ":m .+1<CR>==", noremap_options) -- move current line down
map("n", "Y", "y$", noremap_options) -- yank to end of line
map("n", "n", "nzz", noremap_options) -- go to next found occurrence

--NOTE: Lua output date for zettels
-- map("n", "<leader>z", ":lua print_current_date()<cr>", noremap_options)
-- function print_current_date()
-- 	local current_date = os.date("%Y%m%d%H%M%S")
-- 	local r, c = unpack(vim.api.nvim_win_get_cursor(0))
-- 	local lines = vim.api.nvim_buf_get_lines(0, r - 1, r, false)
-- 	local line = unpack(lines)
-- 	vim.api.nvim_buf_set_lines(0, r - 1, r, -1, { current_date .. line })
-- end
-- map("n", "<leader>zn", ":ObsidianNew ", noremap_options)
-- map("n", "<leader>zt", ":ObsidianTemplate<cr>", noremap_options)

--NOTE: Helix inspired mappings
map("n", "gl", "$", noremap_options) -- go to end of line
map("n", "gh", "^", noremap_options) -- go to beginning of line
map("n", "ge", "GG", noremap_options) -- go to end of file

--NOTE: My sensible remap for deleting words backwards
--This will delete the character under the cursor when deleting backwards
--Then it will place the cursor on the left of the single or double quotes
map("n", 'dT"', 'dT"dlh', noremap_options)
map("n", "dT'", "dT'dlh", noremap_options)
map("n", 'cT"', 'dT"dlha', noremap_options)
map("n", "cT'", "dT'dlha", noremap_options)

--NOTE: Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", noremap_options) -- find files by filename
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", noremap_options) -- find files by text content
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", noremap_options) -- list open buffers
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", noremap_options) -- find help tags
map("n", "<leader>fm", "<cmd>Telescope marks<cr>", noremap_options) -- find marks

--NOTE: Emacs window hopping
map("n", "<leader>wh", ":wincmd h<CR>", noremap_options) -- move to left window
map("n", "<leader>wj", ":wincmd j<CR>", noremap_options) -- move to bottom window
map("n", "<leader>wk", ":wincmd k<CR>", noremap_options) -- move to top window
map("n", "<leader>wl", ":wincmd l<CR>", noremap_options) -- move to right window

--NOTE: Window sizing
map("n", "<leader>+", ":vertical resize +5<CR>", noremap_options)
map("n", "<leader>-", ":vertical resize -5<CR>", noremap_options)

-- show keymaps
vim.keymap.set( {"n", "v", "i"}, "<M-k>", "<cmd>Telescope keymaps<cr>", { desc = "[P]Key Maps" }) -- show keymaps

--NOTE: Disable Escape p for Auto Pairs. Escape p trigger auto pairs to toggle
map("n", "<M-p>", "<Nop>", noremap_options)

--NOTE Added navigation remaps to recenter the cursor
map("n", "<C-u>", "<C-u>zz", noremap_options) -- recenter after half page up
map("n", "<C-d>", "<C-d>zz", noremap_options) -- recenter after half page down
map("n", "<C-f>", "<C-f>zz", noremap_options) -- recenter after full page down
map("n", "<C-b>", "<C-b>zz", noremap_options) -- recenter after full page up

--NOTE: GoTo Preview Keybindings
-- DO NOT USE THE LEADER KEY!!!
-- I have <leader>gp mapped to vim.diagnostic.goto_prev
map("n", "gpd", ':lua require("goto-preview").goto_preview_definition()<CR>', noremap_options)
map("n", "gpt", ':lua require("goto-preview").goto_preview_type_definition()<CR>', noremap_options)
map("n", "gpi", ':lua require("goto-preview").goto_preview_implementation()<CR>', noremap_options)
map("n", "gP", ':lua require("goto-preview").close_all_win()<CR>', noremap_options)
--NOTE: Only set if you have telescope installed
map("n", "gpr", ':lua require("goto-preview").goto_preview_references()<CR>', noremap_options)

-- copilot keybindings
--
map('i', '<C-j>', 'copilot#Accept("\\<CR>")', {
          expr = true,
          replace_keycodes = false
        })
map('i', '<C-b>', 'copilot#AcceptWord()', {
          expr = true,
          silent = true,
          replace_keycodes = false
        })

map('i', '<C-l>', 'copilot#AcceptLine()', {
          expr = true,
          silent = true,
          replace_keycodes = false
        })

map('n', '<leader>cp', ':CopilotChatOpen<CR>', noremap_options)
map('n', '<leader>cc', ':CopilotChatClose<CR>', noremap_options)

--NOTE: Autocommands
vim.cmd([[
  autocmd FileType markdown setlocal wrap
  autocmd FileType markdown setlocal linebreak
]])
