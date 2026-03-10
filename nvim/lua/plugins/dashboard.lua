return {
	-- Dashboard when opening nvim
	"goolord/alpha-nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},

	config = function()
		-- require("alpha").setup(require("alpha.themes.dashboard").config)
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		dashboard.section.header.val = {
			[[            __                                 ]],
			[[ .-.__      \ .-.  ___  __                     ]],
			[[ |_|  '--.-.-(   \/\;;\_\.-._______.-.         ]],
			[[ (-)___     \ \ .-\ \;;\(   \       \ \        ]],
			[[  Y    '---._\_((Q)) \;;\\ .-\     __(_)       ]],
			[[  I           __'-' / .--.((Q))---'    \,      ]],
			[[  I     ___.-:    \|  |   \'-'_          \     ]],
			[[  A  .-'      \ .-.\   \   \ \ '--.__     '\   ]],
			[[  |  |____.----((Q))\   \__|--\_      \     '  ]],
			[[     ( )        '-'  \_  :  \-' '--.___\       ]],
			[[      Y                \  \  \       \(_)      ]],
			[[      I                 \  \  \         \,     ]],
			[[      I                  \  \  \          \    ]],
			[[      A                   \  \  \          '\  ]],
			[[      |                    \  \__|           ' ]],
			[[                            \_:.  \            ]],
			[[                              \ \  \           ]],
			[[                               \ \  \          ]],
			[[                                \_\_|          ]],
		}
		dashboard.section.buttons.val = {
			dashboard.button("e", "  New file", "<cmd>ene <CR>"),
      dashboard.button("SPC f f", "Find files"),
      dashboard.button("SPC f g", "Live grep for files"),
			dashboard.button("SPC f o", "󰈞  Recently opened files"),
			dashboard.button("q", "󰅚  Quit NVIM", ":qa<CR>"),
		}
		local handle = io.popen("fortune")
		local fortune = handle:read("*a")
		handle:close()
		dashboard.section.footer.val = fortune

		dashboard.config.opts.noautocmd = true

		vim.cmd([[autocmd User AlphaReady echo 'ready']])

		alpha.setup(dashboard.config)
	end,
}
