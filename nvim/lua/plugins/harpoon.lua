return {
	"theprimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup()

		-- basic telescope configuration
		-- local conf = require("telescope.config").values
		-- local function toggle_telescope(harpoon_files)
		--     local file_paths = {}
		--     for _, item in ipairs(harpoon_files.items) do
		--         table.insert(file_paths, item.value)
		--     end

		--     require("telescope.pickers").new({}, {
		--         prompt_title = "Harpoon",
		--         finder = require("telescope.finders").new_table({
		--             results = file_paths,
		--         }),
		--         previewer = conf.file_previewer({}),
		--         sorter = conf.generic_sorter({}),
		--     }):find()
		-- end

		-- NOTE: Harpoon Key Bindings
		-- vim.keymap.set('n', '<leader>hs', function() toggle_telescope(harpoon:list()) end, { desc = "Open harpoon window" })
		vim.keymap.set("n", "<leader>ha", function()
			harpoon:list():add()
		end, { desc = "Add file to harpoon" })
		vim.keymap.set("n", "<leader>hs", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Show harpoon list"})
		vim.keymap.set("n", "<leader>hn", function()
			harpoon:list():select(1)
		end, { desc = "Select file 1 from harpoon"})
		vim.keymap.set("n", "<leader>he", function()
			harpoon:list():select(2)
		end, { desc = "Select file 2 from harpoon"})
		vim.keymap.set("n", "<leader>hi", function()
			harpoon:list():select(3)
		end, { desc = "Select file 3 from harpoon"})
		vim.keymap.set("n", "<leader>ho", function()
			harpoon:list():select(4)
		end, { desc = "Select file 4 from harpoon"})
		vim.keymap.set("n", "<leader>hp", function()
			harpoon:list():prev()
		end, { desc = "Select previous file from harpoon"})
		vim.keymap.set("n", "<leader>ht", function()
			harpoon:list():next()
		end, { desc = "Select next file from harpoon"})
	end,
}
