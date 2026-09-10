-- Neovim's Lua runtime injects `vim` as a global; without this every file is one warning per line.
globals = { "vim" }
-- stylua owns line length (column_width = 120 in .stylua.toml); luacheck complaining about it too
-- would just be two tools disagreeing about the same thing.
max_line_length = false
