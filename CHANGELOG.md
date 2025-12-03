# Changelog

## [Repaired Version] - 2024-12-03

### 🔧 Critical Fixes
- **Renamed `init.lua` to `main.lua`** - Yazi requires `main.lua` as the plugin entry point
- **Fixed `ya.which()` usage** - Now correctly uses returned 1-based index to access destinations from sorted array
- **Fixed `cx.active.selected` access** - Added top-level `ya.sync()` bridge function to access Yazi context from async plugin
- **Fixed confirmation dialog** - Replaced `ya.confirm()` with `ya.input()` for y/n confirmation (correct API)

### 🆕 Improvements
- Modified `build_destination_menu()` to return both candidates and sorted destinations list
- Added `job` parameter to `entry()` function signature
- Improved error messages with "Destination Copy" naming
- Updated all plugin references from "batch-copy" to "destination-copy"

### 📝 Documentation
- **Updated README.md** with:
  - Quick Start section for immediate usage
  - Expanded installation instructions with verification steps
  - Clearer usage instructions with confirmation step
  - Enhanced troubleshooting section with common issues
  - New Technical Details section explaining architecture
  - Improved examples and configuration notes
  
- **Created FIXED.md** - Comprehensive repair documentation
- **Created TESTING_GUIDE.md** - Step-by-step testing procedures
- **Updated examples/config.lua** - Correct plugin naming

### ✅ Validation
- Lua syntax check passed (`luac -p main.lua`)
- Plugin structure follows Yazi conventions
- All API calls use correct Yazi plugin API methods

### 🔄 Migration from Original

If you had the original broken version:

1. **Backup your config:**
   ```bash
   cp ~/.config/yazi/init.lua ~/.config/yazi/init.lua.backup
   ```

2. **Update plugin reference in init.lua:**
   ```lua
   # Change this:
   require("batch-copy"):setup { ... }
   
   # To this:
   require("destination-copy"):setup { ... }
   ```

3. **Update keybinding in keymap.toml:**
   ```toml
   # Change this:
   run = "plugin batch-copy"
   
   # To this:
   run = "plugin destination-copy"
   ```

4. **Restart Yazi**

### 📚 Files Changed
- `init.lua` → `main.lua` (renamed)
- `main.lua` (rewritten with fixes)
- `README.md` (enhanced)
- `examples/config.lua` (updated)
- `FIXED.md` (created)
- `TESTING_GUIDE.md` (created)
- `CHANGELOG.md` (this file, created)

### 🐛 Known Issues
None currently. Please report issues if found.

### 🎯 Compatibility
- **Yazi**: 0.2.0 or higher
- **Platform**: macOS (requires `trash` command)
- **Lua**: 5.1+ (Yazi's embedded Lua)

---

## Prior Versions

### [Original] - Before 2024-12-03
- Non-functional due to incorrect file naming and API usage
- See FIXED.md for detailed list of issues
