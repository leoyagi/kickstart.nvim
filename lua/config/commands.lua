local presets = {
  web = {
    target = 'wasm32-unknown-unknown',
    features = "{'web'}",
  },
  android = {
    target = 'aarch64-linux-android',
    features = "{'mobile'}",
  },
  desktop = {
    target = 'x86_64-unknown-linux-gnu',
    features = "{'desktop'}",
  },
}

local function set_ra_config(env)
  local preset = presets[env]
  if not preset then
    print('Unknown environment: ' .. env)
    return
  end

  local config_str = string.format("RustAnalyzer config { cargo = { target = '%s', features = %s } }", preset.target, preset.features)
  print(config_str)
  vim.cmd(config_str)
  vim.cmd 'RustAnalyzer restart'
end

vim.api.nvim_create_user_command('RA', function(opts)
  set_ra_config(opts.args)
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(presets)
  end,
})
