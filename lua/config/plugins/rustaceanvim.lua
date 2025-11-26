return {
  'mrcjkb/rustaceanvim',
  version = '^6', -- Recommended
  lazy = false, -- This plugin is already lazy
  init = function()
    -- Use rustaceanvim as the LSP provider
    vim.g.rustaceanvim = {
      server = {
        on_attach = function(_, bufnr)
          --   -- Example keymaps
          --   local opts = { buffer = bufnr }
          --   vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          --   vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          --   vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          --if client.server_capabilities.documentFormattingProvider then
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format { bufnr = bufnr, timeout_ms = 2000 }
            end,
          })
        end,
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              -- features = 'all',
              -- features = { 'web' },
              -- target = 'aarch64-linux-android',
            },
            checkOnSave = true,
          },
        },
      },
    }
  end,
}
