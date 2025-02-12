return {
  'uga-rosa/ccc.nvim',

  config = function()
    local ccc = require 'ccc'
    --local mapping = ccc.mapping

    ccc.setup {
      highlighter = {
        auto_enable = true,
        lsp = true,
      },
    }

    vim.keymap.set('n', '<leader>cp', ':CccPick<CR>', { desc = 'Open [C]olor [P]icker' })
  end,
}
