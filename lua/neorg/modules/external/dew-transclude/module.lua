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

  module.private.set_autocmd()
end

module.config.public = {
  block_end_marker = "===",
  no_title = true,
  colorify = true,
  colorify_options = { bg = "#2A3230", fg = "#D2DAD7" },
}

module.private = {
  enable = function()
    local row_position, line = modules.get_module("external.neorg-dew").get_line_at_cursor_position()

    if line:find("{", 1, true) and not line:find("!", 1, true) then
      local new_line = line:gsub("%{", "!{")

      api.nvim_buf_set_lines(0, row_position - 1, row_position, false, { new_line })
    end
  end,

  disable = function()
    local row_position, line = modules.get_module("external.neorg-dew").get_line_at_cursor_position()

    if line:find("!{", 1, true) then
      local new_line = line:gsub("!%{", "{")

      api.nvim_buf_set_lines(0, row_position - 1, row_position, false, { new_line })
    end
  end,

  toggle = function()
    local _, line = modules.get_module("external.neorg-dew").get_line_at_cursor_position()

    if module.private.is_enabled(line) then
      module.private.disable()
    else
      module.private.enable()
    end
  end,

  refresh = function()
    module.private.disable()

    vim.defer_fn(function()
      module.private.enable()
    end, 100)
  end,

  delete_inserted_lines = function(line, position, line_number)
    local new_line = line:gsub("%]:>%s%d+$", "]")

    api.nvim_buf_set_lines(0, position - 1, position, false, { new_line })
    api.nvim_buf_set_lines(0, position, position + line_number, false, {})
  end,

  is_enabled = function(line)
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

  transclusion_disabled = function(line, position)
    local disable_and_get_number = string.match(line, "%{:.-:%}%[.-%]:>%s(%d+)")

    if disable_and_get_number and not string.match(line, "!%{") then
      module.private.delete_inserted_lines(line, position, disable_and_get_number)

      return true
    end
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

  colorify = function(start, nb)
    api.nvim_set_hl(0, "dewTransclude", module.config.public.colorify_options)

    for lnum = start, start + nb - 1 do
      api.nvim_buf_set_extmark(0, api.nvim_create_namespace "dew-transclude", lnum, 0, {
        end_row = lnum,
        end_col = #vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1] or "",
        hl_group = "dewTransclude",
        hl_eol = true,
      })
    end
  end,

  set_autocmd = function()
    autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
      callback = function()
        if vim.bo.filetype == "norg" then
          local lines = api.nvim_buf_get_lines(0, 0, -1, false)

          for i = #lines, 1, -1 do
            local line = lines[i]

            local path = module.private.is_enabled(line)

            if path then
              local nb_of_lines = module.private.embed_note(line, i, path)

              if module.config.public.colorify then
                module.private.colorify(i, nb_of_lines)
              end
            else
              module.private.transclusion_disabled(line, i)
            end
          end
        end
      end,
    })
  end,
}

module.on_event = function(event)
  if event.split_type[2] == "dew-transclude.enable" then
    module.private.enable()
  elseif event.split_type[2] == "dew-transclude.disable" then
    module.private.disable()
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
