--  This file is part of the CodeDiff code diffing tool.
--
--  Copyright (C) 2026 Marko Ivankovic
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU Affero General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Affero General Public License for more details.
--
--  You should have received a copy of the GNU Affero General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

local M = {}

function M.check()
  vim.health.start("codediff.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10 found (needed for vim.system)")
  else
    vim.health.error("Neovim >= 0.10 is required (codediff.nvim uses vim.system)")
  end

  local bin = require("codediff").config.bin

  if vim.fn.executable(bin) == 0 then
    vim.health.error(("`%s` not found on $PATH"):format(bin), {
      "Install codediff: https://github.com/ivankovic/codediff#installation",
      "Or point codediff.nvim at it: require('codediff').setup({ bin = '/path/to/codediff' })",
    })
    return
  end
  vim.health.ok(("found `%s` on $PATH"):format(bin))

  -- Best-effort only: `--help` doesn't need real files, so this confirms the installed binary
  -- recognizes `--mode json` at all without needing a real diff to run. A missing/older codediff
  -- build (from before json_output.rs existed) is the main thing this is meant to catch.
  local result = vim.system({ bin, "--help" }, { text = true }):wait()
  if result.code == 0 and result.stdout:lower():find("json", 1, true) then
    vim.health.ok("installed codediff appears to support `--mode json`")
  else
    vim.health.warn("could not confirm `--mode json` support - you may need a newer codediff build")
  end
end

return M
