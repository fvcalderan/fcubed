# Fcubed
Fcubed (Felipe's Fuzzy Finder) is a lightweight plugin I created to explore and understand the integration of Lua within Neovim.

## Setup

```lua
require("fcubed").setup({
    width_ratio = 0.8,
    height_ratio = 0.8
})
```

## Functions

```
:FcubedFile   - Search for file
:FcubedString - Search for string
:FcubedCursor - Search for string below cursor
```
