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

local function set_features(features_str)
  local features_value

  if features_str == 'all' then
    features_value = '"all"'
  else
    -- Split by comma and create array
    local features = {}
    for feature in features_str:gmatch '[^,]+' do
      table.insert(features, string.format('"%s"', feature:match '^%s*(.-)%s*$')) -- trim whitespace
    end
    features_value = '{ ' .. table.concat(features, ', ') .. ' }'
  end

  local config_table = string.format('{ cargo = { features = %s } }', features_value)
  vim.cmd.RustAnalyzer { 'config', config_table }
  vim.cmd 'RustLsp reloadWorkspace'
  -- vim.cmd 'RustAnalyzer restart'
end

vim.api.nvim_create_user_command('SetFeatures', function(opts)
  set_features(opts.args)
end, { nargs = 1 })
