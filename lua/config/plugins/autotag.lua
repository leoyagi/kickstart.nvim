---@diagnostic disable: missing-fields
return {
  'windwp/nvim-ts-autotag',

  config = function()
    local options = {
      -- Defaults
      enable_close = true, -- Auto close tags
      enable_rename = true, -- Auto rename pairs of tags
      enable_close_on_slash = false, -- Auto close on trailing </
    }

    require('nvim-ts-autotag').setup {
      opts = options,

      aliases = {
        ['rust'] = 'html',
      },

      -- Also override individual filetype configs, these take priority.
      -- Empty by default, useful if one of the "opts" global settings
      -- doesn't work well in a specific filetype
      -- per_filetype = {
      --   ['rust'] = {
      --     enable_close = true,
      --     enable_rename = true,
      --   },
      -- },
    }
  end,
}
