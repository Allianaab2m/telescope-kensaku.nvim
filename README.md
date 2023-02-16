# telescope-kensaku.nvim

kensaku.vimを利用して全文検索を行うTelescope extensionです。

## Dependencies

- [denops.vim](https://github.com/vim-denops/denops.vim)
- [kensaku.vim](https://github.com/lambdalisue/kensaku.vim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Usage

[Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "Allianaab2m/telescope-kensaku.nvim",
      config = function()
        require("telescope").load_extension("kensaku") -- :Telescope kensaku
      end
    }
  }
}
```


