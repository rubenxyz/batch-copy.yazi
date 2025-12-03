# Yazi Plugin Development Knowledge Base

This knowledge base contains comprehensive documentation for building plugins for Yazi, the terminal file manager. The files are organized in a logical learning sequence from basic concepts to advanced topics.

## 📚 Documentation Structure

### Getting Started (Read First)

**01-Plugin-System-Overview.md**
- Introduction to Yazi's plugin system
- Plugin types (Functional, Previewer, Preloader, Fetcher)
- Plugin structure and directory layout
- Execution contexts (sync vs async)
- Configuration and registration

**02-Plugin-Architecture.md**
- Deep dive into plugin architecture
- Sync/async context model
- State management patterns
- Cross-context communication with `ya.sync()`
- Annotations (`@sync`, `@since`)
- Memory safety and ownership transfer
- Plugin lifecycle

### Building Your Plugin

**03-Writing-Plugins-Tutorial.md**
- Practical step-by-step guide
- Setup method for configuration
- Handling job parameters
- Implementing previewers with `peek()` and `seek()`
- Implementing preloaders with `preload()`
- State management patterns
- Complete working examples
- Debugging techniques

### API References

**04-Type-System-Reference.md**
- Core data types: `Url`, `Cha`, `File`, `Icon`, `Error`, `Window`
- Type properties and methods
- Type conversion and construction
- Usage patterns

**05-API-Reference-Overview.md**
- Overview of API namespaces
- `ya` - Core application interface
- `ps` - Publish-subscribe messaging
- `fs` - Filesystem operations
- `Command` - Process execution
- Context availability and restrictions

**06-Core-Utilities-API.md**
- Complete reference for all API methods
- `ya.*` - UI control, previews, user interaction, system info
- `ps.*` - DDS messaging system
- `fs.*` - Async filesystem operations
- `Command` - External process execution
- `Child` - Process control
- Usage examples for each API

**07-Layout-UI-API.md**
- Spatial components: `ui.Rect`, `ui.Pad`, `ui.Pos`
- Text components: `ui.Span`, `ui.Line`, `ui.Text`, `ui.Style`
- Renderable components: `ui.List`, `ui.Bar`, `ui.Border`, `ui.Gauge`, `ui.Clear`
- Layout system: `ui.Layout`, `ui.Constraint`
- Complete UI building example

### Learning from Examples

**08-Built-in-Plugins.md**
- Documentation of Yazi's built-in plugins
- `fzf.lua` - Fuzzy file finding
- `zoxide.lua` - Smart directory navigation
- `dds.lua` - DDS command bridge
- `session.lua` - Cross-instance clipboard
- `extract.lua` - Archive extraction
- Configuration patterns
- External tool integration

**09-Plugin-Ecosystem.md**
- Community-contributed plugins catalog
- Previewers for various file types
- Functional plugins for navigation, bookmarks, file operations
- UI enhancements
- Editor integrations
- Plugin naming conventions

## 🎯 Learning Path

### For First-Time Plugin Developers

1. **Start here**: 01-Plugin-System-Overview.md
   - Understand what plugins are and how they work
   - Learn about plugin types

2. **Learn the architecture**: 02-Plugin-Architecture.md
   - Understand sync vs async contexts
   - Learn about state management

3. **Build your first plugin**: 03-Writing-Plugins-Tutorial.md
   - Follow practical examples
   - Learn debugging techniques

4. **Reference as needed**:
   - 04-Type-System-Reference.md - When working with files/paths
   - 06-Core-Utilities-API.md - When calling API methods
   - 07-Layout-UI-API.md - When building custom UI

5. **Get inspired**: 08-Built-in-Plugins.md & 09-Plugin-Ecosystem.md

### For Specific Plugin Types

#### Building a Functional Plugin
→ Read: 01, 02, 03 (sections on functional plugins), 06

#### Building a Previewer
→ Read: 01, 02, 03 (previewer section), 04, 06, 07

#### Building a Preloader
→ Read: 01, 02, 03 (preloader section), 04, 06

#### Building UI Components
→ Read: 01, 02, 07

## 🔍 Quick Reference Guide

### Common Tasks

**Access current file**
```lua
--- @sync entry
return {
  entry = function(state, job)
    local h = cx.active.current.hovered
    if h then
      ya.dbg(tostring(h.url))
    end
  end
}
```
→ See: 02-Plugin-Architecture.md, 06-Core-Utilities-API.md

**Run external command**
```lua
local child, err = Command("ls")
  :args({"-la"})
  :stdout(Command.PIPED)
  :spawn()
```
→ See: 06-Core-Utilities-API.md (Command section)

**Show notification**
```lua
ya.notify {
  title = "Title",
  content = "Message",
  timeout = 5,
}
```
→ See: 06-Core-Utilities-API.md (ya.notify)

**Create UI components**
```lua
local components = {
  ui.Text("Hello"):area(rect),
  ui.Border(ui.Edge.ALL):area(rect)
}
```
→ See: 07-Layout-UI-API.md

## 📋 Plugin Template

```lua
--- @sync entry
--- @since 25.2.13

local M = {}

-- Configuration defaults
local default_config = {
  enabled = true,
}

-- Setup function (optional)
function M.setup(state, opts)
  state.config = opts or default_config
end

-- Main entry point for functional plugins
function M.entry(state, job)
  if not state.config or not state.config.enabled then
    return
  end
  
  -- Your plugin logic here
  ya.notify {
    title = "My Plugin",
    content = "Hello from my plugin!",
    timeout = 3,
  }
end

return M
```

## 🐛 Debugging

Enable logging:
```bash
YAZI_LOG=debug yazi
```

Log file location:
- Unix: `~/.local/state/yazi/yazi.log`
- Windows: `%AppData%\yazi\state\yazi.log`

Use in plugin:
```lua
ya.dbg("Debug message", some_variable)
ya.err("Error message", error_object)
```

→ See: 03-Writing-Plugins-Tutorial.md (Debugging section)

## 🔗 External Resources

- [Yazi GitHub](https://github.com/sxyazi/yazi)
- [Yazi Documentation](https://yazi-rs.github.io)
- [Community Plugins](https://github.com/yazi-rs/plugins)
- [Lua Reference](https://www.lua.org/manual/5.4/)

## 📝 Notes

- All documentation is based on Yazi `HEAD` (latest development version)
- Plugin system is in active development
- Always check version compatibility with `@since` annotation
- File names use source references (e.g., "yazi-rs/yazi-rs.github.io/DeepWiki")

## 🎓 Contributing

This knowledge base is organized for optimal learning. Each file builds upon previous concepts:

1. **Conceptual files** (01-03): Learn the "what" and "why"
2. **Reference files** (04-07): Look up the "how"
3. **Example files** (08-09): See real implementations

Happy plugin development! 🚀
