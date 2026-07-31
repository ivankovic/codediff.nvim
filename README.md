# codediff.nvim

Syntax-aware diffing in Neovim, backed by the [codediff](https://github.com/ivankovic/codediff)
CLI. Renders `codediff --mode json`'s full-range-precision hunk data directly onto Neovim buffers
with extmarks, instead of parsing ANSI text out of a terminal diff tool.

## Requirements

* Neovim >= 0.10 (uses `vim.system()`).
* The [`codediff`](https://github.com/ivankovic/codediff) binary, on `$PATH` or pointed at
  explicitly (see Setup below), built with `--mode json` support.

Run `:checkhealth codediff` to confirm both are in place.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ivankovic/codediff.nvim",
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "ivankovic/codediff.nvim",
  config = function()
    require("codediff").setup()
  end,
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'ivankovic/codediff.nvim'
```
```lua
require('codediff').setup()
```

## Setup

```lua
require('codediff').setup({
  -- Path to (or name of) the codediff binary. Default: 'codediff'.
  bin = 'codediff',
})
```

`setup()` is optional - the default above is used if it's never called.

## Usage

* `:CodeDiff {before} {after}` - diff two files, opened side by side in a new tab.
* `:CodeDiffThis` - diff the current buffer's unsaved edits against the on-disk file.

## Highlights

Linked (not hardcoded) to standard diff highlights, so any colorscheme that already styles
`DiffAdd`/`DiffDelete`/`DiffChange`/`DiffText` looks right immediately:

| Group             | Linked to    |
|-------------------|--------------|
| `CodeDiffInsert`  | `DiffAdd`    |
| `CodeDiffDelete`  | `DiffDelete` |
| `CodeDiffUpdate`  | `DiffChange` |
| `CodeDiffMove`    | `DiffText`   |

## License

MIT - see [LICENSE](LICENSE).
