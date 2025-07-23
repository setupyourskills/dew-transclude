local neorg = require "neorg.core"
local modules = neorg.modules

local api = vim.api
local autocmd = api.nvim_create_autocmd

local module = modules.create "external.dew-transclude"

module.load = function()
  module.private.set_autocmd()
end

module.config.public = {
  block_end_marker = "==="
}

module.private = {
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

return module
