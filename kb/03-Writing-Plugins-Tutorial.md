Relevant source files

-   [docs/plugins/overview.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md)
-   [docs/plugins/utils.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md)

This page provides a practical tutorial for creating custom Yazi plugins in Lua. It covers implementing the setup method for configuration, handling job parameters, building previewers and preloaders, and debugging techniques.

For architectural concepts like sync/async contexts and state management, see [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture). For complete API reference documentation, see [Plugin API Reference](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3-plugin-api-reference).

___

## Plugin Structure

Every Yazi plugin is a directory ending in `.yazi` containing at minimum a `main.lua` file. The plugin must return a table with one or more interface methods depending on its type.

### Basic Functional Plugin

A functional plugin implements an `entry` method that receives a `job` parameter:

```lua
-- ~/.config/yazi/plugins/hello.yazi/main.lua
return {
  entry = function(self, job)
    ya.notify {
      title = "Hello Plugin",
      content = "Executing with args: " .. tostring(job.args[1]),
      timeout = 3,
    }
  end,
}
```

Bind it in `keymap.toml`:

```
[[manager.prepend_keymap]]
on = [ "h", "e" ]
run = "plugin hello --foo=bar"
```

The plugin runs in an async context by default, allowing time-consuming operations without blocking the UI.

**Sources:** [docs/plugins/overview.md43-76](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L43-L76)

___

## Setup Method for Configuration

Plugins can expose a `setup` method to accept user configuration from `init.lua`. This method runs synchronously during Yazi initialization.

### Implementation Pattern

```lua
-- ~/.config/yazi/plugins/my-plugin.yazi/main.lua
local state = {}

local function setup(st, opts)
  st.max_items = opts.max_items or 10
  st.show_icons = opts.show_icons ~= false
  st.custom_handler = opts.handler
end

return {
  setup = setup,
  entry = function(self, job)
    -- Access configuration via self
    local max = self.max_items
    if self.custom_handler then
      self.custom_handler()
    end
  end,
}
```

### User Configuration

```lua
-- ~/.config/yazi/init.lua
require("my-plugin"):setup {
  max_items = 20,
  show_icons = true,
  handler = function()
    -- Custom logic
  end,
}
```

The `state` parameter in `setup` provides isolated storage per plugin, preventing namespace pollution in the global sync context.

**Sources:** [docs/plugins/overview.md82-101](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L82-L101) [docs/plugins/overview.md103-131](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L103-L131)

___

## Handling Job Parameters

The `job` parameter passed to plugin methods contains different fields depending on plugin type. Understanding its structure is essential for accessing file information, preview areas, and user arguments.

### Functional Plugin Arguments

Arguments are parsed from the command line in `keymap.toml`:

```
run = "plugin my-cmd arg1 arg2 --named --flag=value"
```

Access them via `job.args`:

```
return {
  entry = function(self, job)
    -- Positional arguments
    local first = job.args[1]  -- "arg1"
    local second = job.args[2]  -- "arg2"
    
    -- Named arguments
    local has_named = job.args.named  -- true
    local flag_value = job.args.flag  -- "value"
    
    -- Validation example
    if not first then
      ya.err("Missing required argument")
      return
    end
  end,
}
```

**Note:** Shorthand arguments like `-a` are not supported. They are treated as positional arguments and may cause conflicts in future versions.

**Sources:** [docs/plugins/overview.md51-76](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L51-L76)

### Previewer/Preloader File Access

The `file` field is a [File](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/File) userdata containing:

```
function M:peek(job)
  local url = job.file.url        -- Url userdata
  local name = job.file.name      -- String filename
  local size = job.file.size      -- Integer bytes
  local cha = job.file.cha         -- Cha (metadata)
  
  if cha.is_dir then
    -- Handle directory
  elseif cha.is_link then
    -- Handle symlink
  end
end
```

The `area` field is a [Rect](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/Rect) defining the preview dimensions:

```
function M:peek(job)
  local width = job.area.w
  local height = job.area.h
  local x = job.area.x
  local y = job.area.y
  
  -- Render content to fit area
end
```

**Sources:** [docs/plugins/overview.md220-255](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L220-L255) [docs/plugins/overview.md261-282](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L261-L282)

___

## Implementing Previewers

A previewer renders file content in the preview pane. It must implement `peek` (render) and `seek` (scroll) methods.

### Complete Previewer Example

```lua
-- ~/.config/yazi/plugins/json-preview.yazi/main.lua
local M = {}

function M:peek(job)
  -- Read file content
  local limit = job.area.h
  local lines, i = {}, 0
  
  local child, err = Command("cat")
    :arg(tostring(job.file.url))
    :stdout(Command.PIPED)
    :spawn()
  
  if not child then
    return ya.preview_widget(job, {
      ui.Text("Error: " .. tostring(err)):area(job.area)
    })
  end
  
  -- Read and skip lines
  local skip = job.skip
  while skip > 0 do
    child:read_line()
    skip = skip - 1
  end
  
  -- Read visible lines
  while i < limit do
    local line = child:read_line()
    if not line then break end
    
    i = i + 1
    lines[#lines + 1] = ui.Line(line)
  end
  
  child:start_kill()
  
  -- Render preview
  ya.preview_widget(job, {
    ui.Text(lines):area(job.area)
  })
end

function M:seek(job)
  -- Calculate new skip value
  local h = cx.active.current.hovered
  if not h or h.url ~= job.file.url then
    return
  end
  
  local step = job.units
  local skip = cx.active.preview.skip + step
  
  -- Trigger re-peek with new skip
  ya.manager_emit("peek", { math.max(0, skip), only_if = tostring(job.file.url) })
end

return M
```

### Key Concepts

1.  **`peek` is async**: Can use `Command`, file I/O, and async APIs. Does not have access to `cx`.
2.  **`seek` is sync**: Has access to `cx` for current state. Should be fast—just update skip and trigger re-peek.
3.  **Skip handling**: The `job.skip` value indicates how many units (lines, pages, etc.) to skip from the top.

### Using Built-in Preview Helpers

For code files, use `ya.preview_code()`:

```
function M:peek(job)
  local err, bound = ya.preview_code {
    area = job.area,
    file = job.file,
    mime = "application/json",
    skip = job.skip,
  }
  
  if err then
    ya.err("Preview failed: " .. err)
  end
end
```

For custom widgets, use `ya.preview_widget()`:

```
function M:peek(job)
  local widgets = {
    ui.Border(ui.Rect { x = job.area.x, y = job.area.y, w = job.area.w, h = 3 }),
    ui.Text("Header"):area(job.area),
  }
  
  ya.preview_widget(job, widgets)
end
```

**Sources:** [docs/plugins/overview.md218-258](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L218-L258) [docs/plugins/utils.md264-323](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L264-L323)

___

## Implementing Preloaders

A preloader fetches/caches file content in the background before the file is previewed. It must implement a `preload` method that returns `(complete, err)`.

### Complete Preloader Example

```lua
-- ~/.config/yazi/plugins/video-preload.yazi/main.lua
local M = {}

function M:preload(job)
  local cache_url = ya.file_cache { file = job.file, skip = 0 }
  if not cache_url then
    return true, nil  -- File not cacheable
  end
  
  -- Check if already cached
  local cha = fs.cha(cache_url)
  if cha then
    return true, nil  -- Already preloaded
  end
  
  -- Generate thumbnail with ffmpeg
  local child, err = Command("ffmpegthumbnailer")
    :args({
      "-i", tostring(job.file.url),
      "-o", tostring(cache_url),
      "-s", "0",  -- Auto size
      "-q", "5",  -- Quality
    })
    :spawn()
  
  if not child then
    return false, err  -- Retry later
  end
  
  local status = child:wait()
  if not status or not status.success then
    fs.remove("file", cache_url)
    return false, Err("ffmpegthumbnailer failed")
  end
  
  return true, nil  -- Success
end

return M
```

### Return Values

| Return | Type | Description |
| --- | --- | --- |
| `complete = true` | `boolean` | Task finished successfully. Will not be called again. |
| `complete = false` | `boolean` | Task incomplete. Will retry on next page change. |
| `err = nil` | `Error?` | No error occurred. |
| `err = Err(msg)` | `Error?` | Error to log (does not prevent retry if `complete = false`). |

### Common Patterns

**Pattern 1: Check cache first**

```
function M:preload(job)
  local cache = ya.file_cache { file = job.file, skip = 0 }
  if fs.cha(cache) then
    return true  -- Already cached
  end
  
  -- Generate cache...
  return true
end
```

**Pattern 2: Retry on failure**

```
function M:preload(job)
  local ok, err = some_operation()
  if not ok then
    return false, err  -- Retry later
  end
  return true  -- Success
end
```

**Pattern 3: Using `ya.image_precache()`**

```
function M:preload(job)
  local cache = ya.file_cache { file = job.file, skip = 0 }
  if not cache then
    return true
  end
  
  -- Downscale image to configured max_width/max_height
  ya.image_precache(job.file.url, cache)
  return true
end
```

**Sources:** [docs/plugins/overview.md260-296](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L260-L296) [docs/plugins/utils.md31-50](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L31-L50) [docs/plugins/utils.md96-106](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L96-L106)

___

## Sync Context Plugins

By default, plugins run in async contexts. For plugins that need immediate access to application state (`cx`) or UI rendering capabilities, use the `@sync` annotation.

### When to Use Sync Context

Use sync context when:

-   **Reading application state**: Need `cx.active`, `cx.tabs`, etc.
-   **Rendering UI immediately**: No time-consuming operations
-   **Sharing state across invocations**: Persistent plugin state

Do not use sync context when:

-   **Performing I/O**: File reading, network requests
-   **Running external commands**: Use async context with `Command`
-   **Time-consuming operations**: Would block the UI

### Sync Functional Plugin

```
--- @sync entry
return {
  entry = function(state, job)
    -- Direct access to cx
    local h = cx.active.current.hovered
    if not h then
      ya.notify { title = "No file", content = "Nothing hovered" }
      return
    end
    
    -- Access persistent state
    state.count = (state.count or 0) + 1
    
    ya.notify {
      title = "File Info",
      content = string.format("%s (viewed %d times)", h.name, state.count),
    }
  end,
}
```

### Accessing Sync Context from Async

Use `ya.sync()` to create sync blocks within async plugins:

```lua
-- Must be at top level
local get_hovered = ya.sync(function(state)
  local h = cx.active.current.hovered
  return h and tostring(h.url) or nil
end)

local set_result = ya.sync(function(state, result)
  state.last_result = result
  ya.render()  -- Update UI
end)

return {
  entry = function(state, job)
    -- In async context
    local url = get_hovered()
    if not url then return end
    
    -- Do async work
    local output = Command("file"):arg(url):output()
    
    -- Update sync state
    set_result(output.stdout)
  end,
}
```

**Important:** `ya.sync()` calls must be at the top level, not inside conditionals or functions.

**Sources:** [docs/plugins/overview.md77-178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L77-L178) [docs/plugins/overview.md187-202](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L187-L202)

___

## State Management Patterns

Each plugin has isolated state storage to prevent conflicts. The state mechanism differs between sync and async contexts.

### Sync State Pattern

```
--- @sync entry
return {
  entry = function(state, job)
    -- Initialize on first run
    state.counter = state.counter or 0
    state.history = state.history or {}
    
    -- Modify state
    state.counter = state.counter + 1
    table.insert(state.history, os.time())
    
    -- State persists across invocations
    ya.dbg("Called " .. state.counter .. " times")
  end,
}
```

### Async State Pattern

```
local state = {}

local update_cache = ya.sync(function(st, key, value)
  st.cache = st.cache or {}
  st.cache[key] = value
end)

local get_cache = ya.sync(function(st, key)
  return st.cache and st.cache[key]
end)

return {
  entry = function(self, job)
    -- Each async execution has independent 'self'
    -- Use sync blocks to share data
    local cached = get_cache("result")
    
    if not cached then
      -- Expensive operation
      local result = Command("..."):output()
      update_cache("result", result.stdout)
    end
  end,
}
```

### Configuration State Pattern

Combine `setup` with state for user configuration:

```
local M = {}

function M.setup(state, opts)
  state.config = {
    enabled = opts.enabled ~= false,
    max_size = opts.max_size or 1024,
    format = opts.format or "default",
  }
end

function M.entry(state, job)
  if not state.config or not state.config.enabled then
    return
  end
  
  local max = state.config.max_size
  -- Use configuration...
end

return M
```

**Sources:** [docs/plugins/overview.md103-131](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L103-L131) [docs/plugins/overview.md132-163](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L132-L163)

___

## Debugging Techniques

### Logging

Use `ya.dbg()` and `ya.err()` to write to the log file:

```
return {
  entry = function(self, job)
    ya.dbg("Entry called with args:", job.args)
    
    local h = ya.sync(function()
      return cx.active.current.hovered
    end)()
    
    if h then
      ya.dbg("Hovered file:", {
        name = h.name,
        size = h.size,
        url = tostring(h.url),
      })
    else
      ya.err("No file hovered")
    end
  end,
}
```

Log file location:

-   Unix-like: `~/.local/state/yazi/yazi.log`
-   Windows: `%AppData%\yazi\state\yazi.log`

Enable logging with environment variable:

```
YAZI_LOG=debug yazi
```

**Log levels** (descending verbosity): `debug` → `info` → `warn` → `error`

### Common Debugging Patterns

**Pattern 1: Inspect job structure**

```
function M:peek(job)
  ya.dbg("Job structure:", {
    file_name = job.file.name,
    area = { w = job.area.w, h = job.area.h },
    skip = job.skip,
    args = job.args,
  })
end
```

**Pattern 2: Trace execution flow**

```
function M:entry(state, job)
  ya.dbg("=== Entry start ===")
  
  local result = some_operation()
  ya.dbg("Operation result:", result)
  
  if not result then
    ya.err("Operation failed")
    return
  end
  
  ya.dbg("=== Entry end ===")
end
```

**Pattern 3: Validate Sendable values**

```lua
-- This will fail - function is not Sendable
ya.emit("cd", { callback = function() end })  -- ERROR

-- This works - only Sendable types
ya.emit("cd", { target = Url("/tmp") })  -- OK
```

### Error Handling

Async functions return `(result, error)` tuples:

```
function M:entry(state, job)
  local child, err = Command("ls"):spawn()
  if not child then
    ya.err("Failed to spawn:", err)
    return
  end
  
  local output, err = child:wait_with_output()
  if not output then
    ya.err("Command failed:", err)
    return
  end
  
  ya.dbg("Success:", output.stdout)
end
```

### Debugging Preset Plugins

To debug built-in plugins:

1.  Clone repository: `git clone https://github.com/yazi-rs/yazi.git`
2.  Navigate to: `yazi-plugin/preset/plugins/`
3.  Modify plugin (add logging, etc.)
4.  Build debug binary: `cargo build`
5.  Run with logging: `YAZI_LOG=debug ./target/debug/yazi`

**Sources:** [docs/plugins/overview.md342-390](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L342-L390) [docs/plugins/utils.md234-262](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L234-L262)

___

## Complete Plugin Examples

### Example 1: File Counter (Functional)

```
--- @sync entry
return {
  entry = function(state, job)
    local files = cx.active.current.files
    local count = 0
    local size = 0
    
    for _, file in ipairs(files) do
      if not file.cha.is_dir then
        count = count + 1
        size = size + file.cha.length
      end
    end
    
    ya.notify {
      title = "Statistics",
      content = string.format("%d files, %d bytes", count, size),
      timeout = 5,
    }
  end,
}
```

Bind in `keymap.toml`:

```
[[manager.prepend_keymap]]
on = [ "c", "f" ]
run = "plugin file-counter"
```

### Example 2: Markdown Previewer

```
local M = {}

function M:peek(job)
  -- Use Glow to render markdown
  local child, err = Command("glow")
    :args({
      "-s", "dark",
      "-w", tostring(job.area.w),
      tostring(job.file.url)
    })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()
  
  if not child then
    return ya.preview_code(job)  -- Fallback
  end
  
  local limit = job.area.h
  local i, lines = 0, {}
  local skip = job.skip
  
  while i < skip + limit do
    local line, event = child:read_line()
    if event ~= 0 then break end
    
    i = i + 1
    if i > skip then
      lines[#lines + 1] = ui.Line(line)
    end
  end
  
  child:start_kill()
  ya.preview_widget(job, { ui.Text(lines):area(job.area) })
end

function M:seek(job)
  local h = cx.active.current.hovered
  if not h or h.url ~= job.file.url then return end
  
  local step = job.units
  local skip = cx.active.preview.skip + step
  ya.manager_emit("peek", { math.max(0, skip), only_if = tostring(job.file.url) })
end

return M
```

Configure in `yazi.toml`:

```
[[plugin.prepend_previewers]]
mime = "text/markdown"
run = "markdown"
```

### Example 3: Image Preloader with Cache

```
local M = {}

function M:preload(job)
  local cache = ya.file_cache { file = job.file, skip = 0 }
  if not cache then
    return true  -- Not cacheable
  end
  
  -- Check if cached
  if fs.cha(cache) then
    return true
  end
  
  -- Generate thumbnail
  ya.image_precache(job.file.url, cache)
  
  -- Verify cache was created
  if fs.cha(cache) then
    return true, nil
  else
    return false, Err("Cache generation failed")
  end
end

return M
```

Configure in `yazi.toml`:

```
[[plugin.prepend_preloaders]]
mime = "image/*"
run = "image-cache"
```

**Sources:** [docs/plugins/overview.md43-76](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L43-L76) [docs/plugins/overview.md218-296](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L218-L296)

___

## Annotations Reference

Annotations control plugin behavior and requirements. They must appear at the top of `main.lua` before any code.

| Annotation | Values | Description |
| --- | --- | --- |
| `@sync` | `entry`, `peek`, `seek` | Run specified method in sync context |
| `@since` | Version string (e.g., `25.2.13`) | Minimum required Yazi version |

### Example with Multiple Annotations

```
--- @since 25.2.13
--- @sync entry
return {
  entry = function(state, job)
    -- Runs in sync context on Yazi >= 25.2.13
  end,
}
```

### Annotation Rules

1.  Must be at the very top of the file
2.  Use triple-dash comment syntax: `--- @annotation value`
3.  No code or non-annotation comments before annotations
4.  Multiple annotations are allowed
5.  Order does not matter

**Sources:** [docs/plugins/overview.md179-215](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L179-L215)

___

## Best Practices

### Plugin Naming

-   Use kebab-case: `my-plugin.yazi`
-   Descriptive names: `markdown-preview.yazi` not `md.yazi`
-   Avoid conflicts with built-in plugins

### Code Organization

```lua
-- Separate concerns
local M = {}

-- Configuration
local default_config = {
  enabled = true,
  timeout = 5,
}

-- Helper functions
local function validate_file(file)
  return file and file.cha and not file.cha.is_dir
end

-- Sync blocks at top level
local get_state = ya.sync(function(st)
  return st.data
end)

-- Public interface
function M.setup(state, opts)
  state.config = vim.tbl_extend("force", default_config, opts)
end

function M.entry(state, job)
  if not validate_file(job.file) then
    return
  end
  -- Implementation...
end

return M
```

### Error Handling

Always check return values and handle errors gracefully:

```
function M:entry(state, job)
  local url, err = fs.cwd()
  if not url then
    ya.err("Failed to get cwd:", err)
    ya.notify { title = "Error", content = tostring(err), level = "error" }
    return
  end
  
  -- Continue with url...
end
```

### Performance

-   **Minimize sync block calls**: Each `ya.sync()` invocation has overhead
-   **Batch sync operations**: Combine multiple state reads/writes
-   **Cache expensive operations**: Use plugin state to store results
-   **Respect job.skip**: Don't process more data than needed for preview

### Documentation

Include in your plugin directory:

-   `README.md`: Usage, configuration, requirements
-   `LICENSE`: License terms
-   Inline comments: Explain complex logic

**Sources:** [docs/plugins/overview.md297-340](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L297-L340) [docs/plugins/utils.md1-1165](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1-L1165)