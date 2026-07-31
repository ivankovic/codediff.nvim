local M = {}

---@class CodeDiffConfig
---@field bin string Path to (or name of) the codediff binary, looked up on $PATH by default.
local defaults = {
  bin = "codediff",
}

M.config = vim.deepcopy(defaults)

---@param opts CodeDiffConfig|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

-- Highlight groups, linked (not hardcoded colors) to standard diff highlights so any colorscheme
-- that already styles DiffAdd/DiffDelete/DiffChange/DiffText looks right here with no extra work.
-- `default = true` means these never clobber a user's or colorscheme's own override.
local HIGHLIGHT_LINKS = {
  CodeDiffInsert = "DiffAdd",
  CodeDiffDelete = "DiffDelete",
  CodeDiffUpdate = "DiffChange",
  CodeDiffMove = "DiffText",
}

local function ensure_highlights()
  for name, link in pairs(HIGHLIGHT_LINKS) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

-- codediff's `--mode json` operation strings (see codediff's own `src/tui/json_output.rs`) map
-- 1:1 onto the highlight groups above. `identical`/unchanged text never appears in the JSON at
-- all, so there is no entry for it here.
local HIGHLIGHT_BY_OPERATION = {
  insert = "CodeDiffInsert",
  delete = "CodeDiffDelete",
  update = "CodeDiffUpdate",
  move = "CodeDiffMove",
}

local NAMESPACE = vim.api.nvim_create_namespace("codediff")

---Paints one side's hunks as extmarks on `bufnr`. `range` is already 0-indexed row/col, the same
---convention `nvim_buf_set_extmark` itself uses, so no translation is needed either direction.
---@param bufnr integer
---@param hunks table[]
local function render_hunks(bufnr, hunks)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
  for _, hunk in ipairs(hunks) do
    local hl_group = HIGHLIGHT_BY_OPERATION[hunk.operation]
    if hl_group then
      local range = hunk.range
      vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range.start_row, range.start_column, {
        end_row = range.end_row,
        end_col = range.end_column,
        hl_group = hl_group,
      })

      -- Only `move` hunks carry a real cross-file jump target - see json_output.rs's own
      -- doc comment on why every other operation's `destination` is a bookkeeping anchor, not a
      -- real position, and so is never exposed as `move_target` at all.
      if hunk.move_target then
        vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range.start_row, 0, {
          virt_text = { { (" » moved to line %d"):format(hunk.move_target.start_row + 1), "Comment" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

---Runs `codediff --mode json before after` and calls `on_done(diff)` with the decoded result.
---Notifies and returns (without calling `on_done`) on a missing binary, non-zero exit, or
---unparseable output - there is no partial/degraded diff to fall back to in any of those cases.
---@param before string
---@param after string
---@param on_done fun(diff: table)
local function run_diff(before, after, on_done)
  local bin = M.config.bin
  if vim.fn.executable(bin) == 0 then
    vim.notify(
      ("codediff.nvim: `%s` not found on $PATH - see :checkhealth codediff"):format(bin),
      vim.log.levels.ERROR
    )
    return
  end

  vim.system({ bin, "--mode", "json", before, after }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(
          ("codediff exited with code %d: %s"):format(result.code, vim.trim(result.stderr or "")),
          vim.log.levels.ERROR
        )
        return
      end

      local ok, diff = pcall(vim.json.decode, result.stdout)
      if not ok then
        vim.notify("codediff.nvim: failed to parse codediff's JSON output: " .. tostring(diff), vim.log.levels.ERROR)
        return
      end

      on_done(diff)
    end)
  end)
end

---Opens `before` and `after` in a new tab, side by side, and highlights their diff.
---@param before string
---@param after string
function M.open_diff(before, after)
  ensure_highlights()
  run_diff(before, after, function(diff)
    vim.cmd.tabnew(vim.fn.fnameescape(before))
    local before_buf = vim.api.nvim_get_current_buf()
    vim.cmd.vsplit(vim.fn.fnameescape(after))
    local after_buf = vim.api.nvim_get_current_buf()

    render_hunks(before_buf, diff.before.hunks)
    render_hunks(after_buf, diff.after.hunks)
  end)
end

---Diffs the current buffer's on-disk content against its unsaved edits, by writing the buffer's
---current lines to a temp file and diffing that against the real path. Order matters: `before` is
---the saved file (what's on disk), `after` is the temp file (what you're currently editing) - the
---same "old vs. new" convention `codediff`'s own CLI and `git difftool` use.
function M.diff_this()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.notify("codediff.nvim: current buffer has no file name", vim.log.levels.ERROR)
    return
  end
  if not vim.bo[bufnr].modified then
    vim.notify("codediff.nvim: buffer has no unsaved changes", vim.log.levels.INFO)
    return
  end

  local tmp = vim.fn.tempname() .. "_" .. vim.fn.fnamemodify(path, ":t")
  vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), tmp)

  M.open_diff(path, tmp)
end

return M
