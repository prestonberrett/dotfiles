return require'packer'.startup(function(use)
  use 'wbthomason/packer.nvim' -- this is essential.

  -- Refacortoring nvim
  use {
      "ThePrimeagen/refactoring.nvim",
      requires = {
          {"nvim-lua/plenary.nvim"},
          {"nvim-treesitter/nvim-treesitter"}
      }
  }

  -- Github copilot
  use 'github/copilot.vim'

  -- Webdev icons
  use 'kyazdani42/nvim-web-devicons'

  -- Obsidian plugin
  use({
    "epwalsh/obsidian.nvim",
    requires = {
      -- Required.
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("obsidian").setup({
        dir = "~/Zettelkasten-v2",
        notes_subdir = "Fleeting Notes",
        note_id_func = function(title)
          -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
          -- In this case a note with the title 'My new note' will given an ID that looks
          -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
          local suffix = ""
          if title ~= nil then
            -- If title is given, transform it into valid file name.
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            -- If title is nil, just add 4 random uppercase letters to the suffix.
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.time()) .. "-" .. suffix
        end,
        daily_notes = {
          folder = "Journal",
        },
        completion={
          nvim_cmp = true,
          min_chars=2,
          new_notes_location="current_dir",
        },
        templates = {
          subdir="Resources/Templates"
        },
        finder="telescope.nvim",
        open_notes_in="current",
        disable_frontmatter=true,
      })
    end,
  })

  -- A pretty list for showing diagnostics, references telescope results, qf, and location lists
 use({
      "folke/trouble.nvim",
      config = function()
          require("trouble").setup {
              icons = true,
          }
      end
  })


  -- Pretty Landing Screen for Nvim
  use {
      'goolord/alpha-nvim',
      requires = { 'nvim-tree/nvim-web-devicons' },
      config = function ()
          require'alpha'.setup(require'alpha.themes.dashboard'.config)
      end
  }

  -- Colorschemes
  use { 'Mofiqul/dracula.nvim' }
  use "gruvbox-community/gruvbox"
  use "EdenEast/nightfox.nvim"
  use "folke/tokyonight.nvim"

  -- Austin Wilcox Plugins
  use "austinwilcox/hex2rgba"

  -- To get Telescope live grep working you need ripgrep
  -- Ubuntu/Debian based
  -- sudo apt install ripgrep
  use "nvim-telescope/telescope.nvim"
  use {'nvim-telescope/telescope-ui-select.nvim' }

  -- Emmet for working with html files
  use "mattn/emmet-vim"
  use "dense-analysis/ale" -- TODO: Might not need
  use "nvim-lua/popup.nvim" -- TODO Might not need
  use "ap/vim-css-color" -- TODO Might not need

  -- Colorizer, provided color highlights
  use { 'norcalli/nvim-colorizer.lua' }

  -- NVIM Todo Comments
  use {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup{}
    end
  }

  --Zen Mode
  use {
    "folke/zen-mode.nvim",
    config = function()
      require("zen-mode").setup{}
    end
  }

  -- experimental plugin that changes the UI for nvim
  -- BUG: Currently there's a bug when I am navigating around in normal mode in my nvim config
  use{
    "folke/noice.nvim",
    config = function()
      require("noice").setup{}
    end,
    requires = {'MunifTanjim/nui.nvim', "rcarriga/nvim-notify"}
  }

  -- Harpoon
  use {
    "ThePrimeagen/harpoon",
    requires = "nvim-lua/plenary.nvim"
  }

  use {
	  'VonHeikemen/lsp-zero.nvim',
	  branch = 'v1.x',
	  requires = {
		  -- LSP Support
		  {'neovim/nvim-lspconfig'},
		  {'williamboman/mason.nvim'},
		  {'williamboman/mason-lspconfig.nvim'},

		  -- Autocompletion
		  {'hrsh7th/nvim-cmp'},
		  {'hrsh7th/cmp-buffer'},
		  {'hrsh7th/cmp-path'},
		  {'saadparwaiz1/cmp_luasnip'},
		  {'hrsh7th/cmp-nvim-lsp'},
		  {'hrsh7th/cmp-nvim-lua'},
	  }
  }

  -- LSP Setup
  use "neovim/nvim-lspconfig"
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/nvim-cmp"
  use "lukas-reineke/lsp-format.nvim"
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use { 'tjdevries/nlua.nvim', requires = { 'nvim-lua/completion-nvim', 'euclidianAce/BetterLua.vim' } }
  use { 'onsails/lspkind.nvim' } -- Vscode like pictograms

  -- Snippet Managers
  use "SirVer/ultisnips"
  use "honza/vim-snippets"

  -- Auto Pairs
  use {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup{} end
  }

  -- TPOPE
  use "tpope/vim-fugitive"
  use "tpope/vim-commentary"

  -- GIT
  use "mhinz/vim-signify"
  use "junegunn/gv.vim"

  -- Chentoast Marks - A better experience with Marks in NVIM
  use { 'chentoast/marks.nvim' }

  -- Prettier - Currently do not like any of the solutions
  use { 'jose-elias-alvarez/null-ls.nvim' }
  use { 'MunifTanjim/prettier.nvim' }

  --Lualine
  use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt=true }}

  --Rainbow for ( [ {  } ] )
  use { 'luochen1990/rainbow' }

  --Beautiful Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = function()
    local ts_update = require('nvim-treesitter.install').update({ with_sync = true})
    ts_update()
  end}

  use({
    "kylechui/nvim-surround",
    tag = "*", -- Use for stability; omit to use `main` branch for the latest features
    config = function()
        require("nvim-surround").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
  })

  --Goto Preview, use lsp and show information in a popup window
  use {
    'rmagatti/goto-preview',
    config = function()
      require('goto-preview').setup {}
    end
  }
end)