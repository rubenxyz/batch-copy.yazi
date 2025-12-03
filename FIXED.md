# Plugin Repair Summary

## Issues Fixed

### 1. **File Structure**
- ✅ Renamed `init.lua` to `main.lua` (required by Yazi)
- Yazi plugins must have a `main.lua` entry point, not `init.lua`

### 2. **API Usage Corrections**

#### `ya.which()` Return Value
- **Problem**: Code assumed `ya.which()` returns the destination object
- **Fix**: `ya.which()` returns a 1-based index, used to access the sorted destinations array
```lua
-- Before (incorrect):
local dest = state.destinations[choice]

-- After (correct):
local cands, sorted = build_destination_menu(state.destinations)
local choice = ya.which({ cands = cands, silent = false })
local dest = sorted[choice]  -- Use index to get from sorted array
```

#### `cx.active.selected` Access
- **Problem**: Async functions cannot directly access `cx` context
- **Fix**: Created a top-level `ya.sync()` function to bridge async and sync contexts
```lua
-- Added at top level (before any functions):
local get_selected = ya.sync(function()
	local files = {}
	for _, file in pairs(cx.active.selected) do
		table.insert(files, file)
	end
	return files
end)

-- Then use in async entry function:
local selected = get_selected()
```

#### Confirmation Dialog
- **Problem**: Used `ya.confirm()` with incorrect parameters
- **Fix**: Used `ya.input()` for y/n confirmation (more compatible)
```lua
-- Before (incorrect API usage):
local confirmed = ya.confirm({
	title = "Confirm Batch Move",
	content = "...",
	yes = 1, no = 2,
})

-- After (correct):
local value, event = ya.input({
	title = "Move N file(s) to destination? (y/n)",
	position = { "top-center", w = 50 }
})
if not value or (value:lower() ~= "y" and value:lower() ~= "yes") or event ~= 1 then
	return
end
```

### 3. **Menu Building**
- Modified `build_destination_menu()` to return both candidates and sorted destinations
- This ensures the index from `ya.which()` correctly maps to destinations

### 4. **Plugin Naming**
- Updated all references from "batch-copy" to "destination-copy"
- Updated README.md with correct plugin name
- Updated examples/config.lua with correct plugin name
- Updated error messages and reports

## How to Use

### 1. Installation
```bash
cd ~/.config/yazi/plugins
ln -s "/path/to/destination_copy.yazi" destination-copy.yazi
```

### 2. Configuration
Add to `~/.config/yazi/init.lua`:
```lua
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Destination 1", path = "/path/to/dest1" },
    { key = "2", name = "Destination 2", path = "/path/to/dest2" },
    { key = "a", name = "Archive", path = "/path/to/archive" },
  }
}
```

### 3. Key Binding
Add to `~/.config/yazi/keymap.toml`:
```toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin destination-copy"
desc = "Batch move to configured destination"
```

### 4. Usage
1. Select files in Yazi (Space key)
2. Press `s` (or your configured key)
3. Choose destination by pressing its key (0-9, a-z)
4. Confirm with `y`
5. Files are moved!

## Testing
To test the plugin:
```bash
YAZI_LOG=debug yazi
```

Watch logs:
```bash
tail -f ~/.local/state/yazi/yazi.log
```

## Key Changes from Original

| Aspect | Original | Fixed |
|--------|----------|-------|
| Entry file | `init.lua` | `main.lua` |
| Plugin name | `batch-copy` | `destination-copy` |
| `ya.which()` usage | Direct object access | Index-based access |
| `cx.active.selected` | Direct access in async | Via `ya.sync()` bridge |
| Confirmation | `ya.confirm()` | `ya.input()` y/n |
| Menu function | Returns only cands | Returns cands + sorted |

## Architecture Notes

- **Execution Context**: Plugin runs in async context by default
- **Sync Bridge**: Uses `ya.sync()` at top level to access `cx.active.selected`
- **State Management**: Configuration stored in plugin state via `setup()` method
- **Error Handling**: Comprehensive validation and error reporting
- **Safe Operations**: Uses macOS `trash` command instead of `rm`

The plugin should now work correctly within Yazi!
