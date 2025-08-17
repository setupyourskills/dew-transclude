local neorg = require "neorg.core"
local modules = neorg.modules

local api = vim.api
local autocmd = api.nvim_create_autocmd

local module = modules.create "external.dew-transclude"

module.setup = function()
  return {
    requires = {
      "core.neorgcmd",
    },
  }
end

module.load = function()
  module.required["core.neorgcmd"].add_commands_from_table {
    dew_transclude = {
      args = 1,
      subcommands = {
        enable = { args = 0, name = "dew-transclude.enable" },
        disable = { args = 0, name = "dew-transclude.disable" },
        refresh = { args = 0, name = "dew-transclude.refresh" },
        toggle = { args = 0, name = "dew-transclude.toggle" },
      },
    },
  }

  module.config.private.name_space = api.nvim_create_namespace "dew-transclude"

  module.private.set_autocmd()
end

module.config.public = {
  block_end_marker = "===",
  no_title = true,
  colorify = false,
}

module.config.private = {
  name_space = nil
}

module.private = {
  toggle = function(state)
    local row_position, line = modules.get_module("external.neorg-dew").get_line_at_cursor_position()
    local is_inserted = module.private.is_inserted(line)

    local new_line

    if not state or (is_inserted and state == "disable") or (not is_inserted and state == "enable") then
      new_line = is_inserted and line:gsub("!%{", "{") or line:gsub("%{", "!{")
      api.nvim_buf_set_lines(0, row_position - 1, row_position, false, { new_line })
    end
  end,

  refresh = function()
    module.private.toggle "disable"

    vim.defer_fn(function()
      module.private.toggle "enable"
    end, 100)
  end,

  delete_inserted_lines = function(line, position)
    if module.private.is_inserted(line) then
      local get_number_of_inserted_lines = module.private.get_number_of_inserted_lines(line)
      local new_line = line:gsub("%]:>%s%d+$", "]")

      api.nvim_buf_set_lines(0, position - 1, position, false, { new_line })
      api.nvim_buf_set_lines(0, position, position + get_number_of_inserted_lines, false, {})
    end
  end,

  get_note_name_to_insert = function(line)
    return string.match(line, "!%{:(.-):%}%[.-%]")
  end,

  is_inserted = function(line)
    if line:find(":> ", 1, true) then
      return true
    end
  end,

  get_number_of_inserted_lines = function(line)
    return string.match(line, "%{:.-:%}%[.-%]:>%s(%d+)")
  end,

  embed_note = function(line, position, path)
    local file_name = neorg.modules.get_module("core.dirman.utils").expand_path(path)
    local block_lines = {}

    if module.private.is_inserted(line) then
      return module.private.get_number_of_inserted_lines(line)
    end

    local content = modules.get_module("external.neorg-dew").read_file(file_name)

    if content then
      local inside_block = false

      for _, line2 in ipairs(content) do
        local is_match_title = line2:match "^%*%s"

        if is_match_title then
          if inside_block then
            break
          end
          inside_block = true
        elseif line2:match(module.config.public.block_end_marker) then
          break
        end

        if inside_block and not (is_match_title and module.config.public.no_title) then
          local new_line = modules.get_module("external.neorg-dew").level_up(line2)
          table.insert(block_lines, new_line)
        end
      end

      api.nvim_buf_set_lines(0, position, position, false, block_lines)
    end

    api.nvim_buf_set_lines(0, position - 1, position, false, { line .. ":> " .. #block_lines })

    return #block_lines
  end,

  set_autocmd = function()
    autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
      callback = function()
        if vim.bo.filetype == "norg" then
          local lines = api.nvim_buf_get_lines(0, 0, -1, false)

          for i = #lines, 1, -1 do
            local line = lines[i]

            local note_name = module.private.get_note_name_to_insert(line)

            if note_name then
              local nb_of_lines = module.private.embed_note(line, i, note_name)

              if module.config.public.colorify then
                require("neorg.core.modules").get_module("external.neorg-dew").colorify(
                  0,
                  module.config.private.name_space,
                  "dewTransclude",
                  i + 1,
                  nb_of_lines
                )
              end
            else
              module.private.delete_inserted_lines(line, i)
            end
          end
        end
      end,
    })
  end,
}

module.on_event = function(event)
  if event.split_type[2] == "dew-transclude.enable" then
    module.private.toggle "enable"
  elseif event.split_type[2] == "dew-transclude.disable" then
    module.private.toggle "disable"
  elseif event.split_type[2] == "dew-transclude.refresh" then
    module.private.refresh()
  elseif event.split_type[2] == "dew-transclude.toggle" then
    module.private.toggle()
  end
end

module.events.subscribed = {
  ["core.neorgcmd"] = {
    ["dew-transclude.enable"] = true,
    ["dew-transclude.disable"] = true,
    ["dew-transclude.refresh"] = true,
    ["dew-transclude.toggle"] = true,
  },
}

return module
