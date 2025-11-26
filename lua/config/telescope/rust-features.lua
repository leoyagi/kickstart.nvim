local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local M = {}

-- Function to parse Cargo.toml and extract features
local function get_cargo_features()
  local features = {}

  -- Find Cargo.toml file
  local cargo_toml_path = vim.fn.findfile('Cargo.toml', '.;')
  if cargo_toml_path == '' then
    vim.notify('No Cargo.toml found in current directory or parent directories', vim.log.levels.ERROR)
    return features
  end

  local file = io.open(cargo_toml_path, 'r')
  if not file then
    vim.notify('Could not read Cargo.toml', vim.log.levels.ERROR)
    return features
  end

  local content = file:read '*all'
  file:close()

  -- Parse features section
  local in_features = false
  local in_dependencies = false

  for line in content:gmatch '[^\r\n]+' do
    local trimmed = line:match '^%s*(.-)%s*$'

    -- Check if we're entering features section
    if trimmed:match '^%[features%]' then
      in_features = true
      in_dependencies = false
    elseif trimmed:match '^%[.*%]' then
      in_features = false
      in_dependencies = trimmed:match '^%[dependencies' or trimmed:match '^%[dev%-dependencies' or trimmed:match '^%[build%-dependencies'
    elseif in_features and trimmed ~= '' and not trimmed:match '^#' then
      -- Extract feature name (everything before = or whitespace)
      local feature_name = trimmed:match '^([%w_%-]+)'
      if feature_name then
        table.insert(features, feature_name)
      end
    elseif in_dependencies and trimmed ~= '' and not trimmed:match '^#' then
      -- Extract dependency features
      local dep_line = trimmed
      -- Look for features in dependency specification
      local features_match = dep_line:match 'features%s*=%s*%[([^%]]+)%]'
      if features_match then
        for feature in features_match:gmatch '"([^"]+)"' do
          -- Mark as dependency feature
          table.insert(features, feature .. ' (dep)')
        end
      end
    end
  end

  return features
end

-- Function to get workspace features if in a workspace
local function get_workspace_features()
  local workspace_features = {}

  -- Check if we're in a workspace
  local cargo_toml_path = vim.fn.findfile('Cargo.toml', '.;')
  if cargo_toml_path == '' then
    return workspace_features
  end

  local file = io.open(cargo_toml_path, 'r')
  if not file then
    return workspace_features
  end

  local content = file:read '*all'
  file:close()

  -- Check if this is a workspace Cargo.toml
  if content:match '%[workspace%]' then
    -- Find all member Cargo.toml files
    local members_match = content:match '%[workspace%].-members%s*=%s*%[([^%]]+)%]'
    if members_match then
      for member in members_match:gmatch '"([^"]+)"' do
        local member_cargo = member .. '/Cargo.toml'
        if vim.fn.filereadable(member_cargo) == 1 then
          local member_file = io.open(member_cargo, 'r')
          if member_file then
            local member_content = member_file:read '*all'
            member_file:close()

            -- Parse member features
            local in_features = false
            for line in member_content:gmatch '[^\r\n]+' do
              local trimmed = line:match '^%s*(.-)%s*$'
              if trimmed:match '^%[features%]' then
                in_features = true
              elseif trimmed:match '^%[.*%]' then
                in_features = false
              elseif in_features and trimmed ~= '' and not trimmed:match '^#' then
                local feature_name = trimmed:match '^([%w_%-]+)'
                if feature_name then
                  table.insert(workspace_features, feature_name .. ' (' .. member .. ')')
                end
              end
            end
          end
        end
      end
    end
  end

  return workspace_features
end

-- Function to apply selected features
local function apply_features(selected_features)
  if #selected_features == 0 then
    vim.notify('No features selected', vim.log.levels.WARN)
    return
  end

  -- Clean feature names (remove dependency/workspace markers)
  local clean_features = {}
  for _, feature in ipairs(selected_features) do
    local clean_name = feature:match '^([%w_%-]+)'
    if clean_name then
      table.insert(clean_features, clean_name)
    end
  end

  local features_value
  if #clean_features == 1 and clean_features[1] == 'all' then
    features_value = '"all"'
  else
    local quoted_features = {}
    for _, feature in ipairs(clean_features) do
      table.insert(quoted_features, string.format('"%s"', feature))
    end
    features_value = '{ ' .. table.concat(quoted_features, ', ') .. ' }'
  end

  local config_table = string.format('{ cargo = { features = %s } }', features_value)
  vim.cmd.RustAnalyzer { 'config', config_table }
  vim.cmd 'RustLsp reloadWorkspace'

  vim.notify('Applied features: ' .. table.concat(clean_features, ', '), vim.log.levels.INFO)
end

-- Main telescope picker function
function M.rust_features()
  local features = get_cargo_features()
  local workspace_features = get_workspace_features()

  -- Combine all features
  local all_features = { 'all' } -- Add "all" option at the top

  -- Add current project features
  for _, feature in ipairs(features) do
    table.insert(all_features, feature)
  end

  -- Add workspace features
  for _, feature in ipairs(workspace_features) do
    table.insert(all_features, feature)
  end

  if #all_features <= 1 then -- Only "all" option
    vim.notify('No features found in Cargo.toml', vim.log.levels.WARN)
    return
  end

  local selected_features = {}

  pickers
    .new({}, {
      prompt_title = 'Rust Features',
      finder = finders.new_table {
        results = all_features,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        -- Toggle feature selection
        local function toggle_selection()
          local selection = action_state.get_selected_entry()
          if selection then
            local feature = selection.value

            -- Check if already selected
            local index = nil
            for i, selected in ipairs(selected_features) do
              if selected == feature then
                index = i
                break
              end
            end

            if index then
              -- Remove from selection
              table.remove(selected_features, index)
              vim.notify('Removed: ' .. feature, vim.log.levels.INFO)
            else
              -- Add to selection
              table.insert(selected_features, feature)
              vim.notify('Added: ' .. feature, vim.log.levels.INFO)
            end
          end
        end

        -- Apply selected features
        local function apply_selected()
          actions.close(prompt_bufnr)
          apply_features(selected_features)
        end

        -- Single selection mode (default behavior)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          if selection then
            actions.close(prompt_bufnr)
            apply_features { selection.value }
          end
        end)

        -- Multi-selection mappings
        map('i', '<Tab>', toggle_selection)
        map('n', '<Tab>', toggle_selection)
        map('i', '<C-y>', apply_selected)
        map('n', '<C-y>', apply_selected)

        return true
      end,
    })
    :find()
end

-- -- Create command
vim.api.nvim_create_user_command('TelescopeRustFeatures', function()
  M.rust_features()
end, {})

-- Optional: Create a keymap
-- vim.keymap.set('n', '<leader>rf', M.rust_features, { desc = 'Rust Features' })

return M
