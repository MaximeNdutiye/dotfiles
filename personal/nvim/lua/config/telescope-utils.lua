local telescope_global_state = require "telescope.state"
local conf = require("telescope.config").values
local telescope_utils = {}

function telescope_utils.is_telescope_open() return next(telescope_global_state.get_existing_prompt_bufnrs()) ~= nil end

function telescope_utils.toggle_telescope(file_paths)
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Telescope",
      finder = require("telescope.finders").new_table {
        results = file_paths,
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

return telescope_utils
