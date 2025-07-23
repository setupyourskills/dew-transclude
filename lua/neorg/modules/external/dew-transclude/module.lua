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
}

module.private = {
  enable = function()
  end,

  disable = function()
  end,

  toggle = function()
  end,

  refresh = function()
  end,

  set_autocmd = function()
    autocmd({ "BufEnter", "CursorMoved" }, {
      callback = function()
        if vim.bo.filetype == "norg" then
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

          for i = #lines, 1, -1 do
            local line = lines[i]

            local disable_and_get_number = string.match(line, "%{:.-:%}%[.-%]:>%s(%d+)")

            if disable_and_get_number and not string.match(line, "!%{") then
              local new_line = line:gsub("%]:>%s%d+$", "]")

              vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
              vim.api.nvim_buf_set_lines(0, i, i + disable_and_get_number, false, {})

              goto continue
            end

            local title = string.match(line, "!%{:(.-):%}%[.-%]")

            if title then
              local file_name = neorg.modules.get_module("core.dirman.utils").expand_path(title)
              local block_lines = {}

              if line:find(":> ", 1, true) then
                goto continue
              end

              local content = modules.get_module("external.neorg-dew").read_file(file_name)

              if content then
                local inside_block = false

                for _, line2 in ipairs(content) do
                  local is_match_title = line2:match "^%*%s"
                  if inside_block then
                    local new_line = modules.get_module("external.neorg-dew").level_up(line2)
                    table.insert(block_lines, new_line)
                  end

                  if is_match_title then
                    if inside_block then
                      break
                    end
                    inside_block = true
                  elseif line2:match(module.config.public.block_end_marker) then
                    break
                  end
                end

                vim.api.nvim_buf_set_lines(0, i, i + 1, false, block_lines)
              end

              vim.api.nvim_buf_set_lines(0, i - 1, i, false, { line .. ":> " .. #block_lines - 1 })
            end
            ::continue::
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
