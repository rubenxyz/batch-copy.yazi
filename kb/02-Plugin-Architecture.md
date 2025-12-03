Relevant source files

-   [docs/plugins/overview.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md)

This document provides a deep dive into Yazi's plugin architecture, covering plugin structure, execution contexts, state management, and cross-thread communication patterns. For an overview of the plugin system and how to use plugins, see [Plugin System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4-plugin-system). For practical guidance on creating plugins, see [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins). For API reference documentation, see [Plugin API Reference](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3-plugin-api-reference).

## Plugin Structure

### Directory Layout

Every Yazi plugin is a self-contained directory with a `.yazi` suffix located in the `plugins` subdirectory of Yazi's configuration directory. The plugin directory must contain at minimum a `main.lua` entry point file.

```
~/.config/yazi/
├── init.lua
├── plugins/
│   ├── foo.yazi/
│   │   ├── main.lua      # Entry point (required)
│   │   ├── README.md     # Documentation
│   │   └── LICENSE       # License file
│   └── bar.yazi/
│       ├── main.lua
│       ├── helpers.lua   # Additional modules (optional)
│       └── config.lua
└── yazi.toml
```

The plugin name is derived from its directory name, excluding the `.yazi` suffix. For example, `smart-tab.yazi` has the plugin name `smart-tab`.

**Plugin Module Structure**

The `main.lua` file must return a Lua table that defines the plugin's interface. The structure depends on the plugin type:

| Plugin Type | Required Methods | Purpose |
| --- | --- | --- |
| Functional | `entry(state, job)` | User-triggered actions |
| Previewer | `peek(job)`, `seek(job)` | File content rendering |
| Preloader | `preload(job)` | Background caching |
| UI Component | Custom methods | Render components (used in init.lua) |

**Sources:** [docs/plugins/overview.md13-41](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L13-L41) [docs/plugins/overview.md216-272](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L216-L272)

___

### Entry Points and Plugin Discovery

Yazi discovers plugins by scanning the `plugins/` directory at startup. Each `.yazi` directory is treated as a potential plugin. The `main.lua` file is loaded to extract annotations and register the plugin's interface methods with the plugin registry.

**Sources:** [docs/plugins/overview.md13-41](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L13-L41) [docs/plugins/overview.md77-163](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L77-L163)

## Plugin Types and Interfaces

### Functional Plugins

Functional plugins are invoked by the `plugin` command, typically bound to a keybinding in `keymap.toml`. They must implement an `entry` method:

```lua
-- ~/.config/yazi/plugins/example.yazi/main.lua
return {
    entry = function(state, job)
        -- state: plugin-specific persistent state
        -- job.args: parsed command-line arguments
        -- job.file: currently hovered file (if applicable)
    end
}
```

The `entry` method receives two parameters:

-   `state`: Plugin-specific state table, persisted across invocations (in sync context only)
-   `job`: Job parameters including `args` (parsed arguments), `file` (hovered file), etc.

Arguments are passed using shell-style syntax: `plugin test -- foo --bar --baz=qux` results in:

-   `job.args[1]` = `"foo"` (positional)
-   `job.args.bar` = `true` (flag)
-   `job.args.baz` = `"qux"` (named)

**Sources:** [docs/plugins/overview.md49-76](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L49-L76)

___

### Previewers and Preloaders

**Previewer Interface**

Previewers render file content in the preview pane:

-   `peek(job)`: Asynchronous rendering method called when user hovers a file. Receives `job.file`, `job.area`, `job.skip`, and `job.args`.
-   `seek(job)`: Synchronous scroll handler called when user scrolls preview. Receives `job.file`, `job.area`, and `job.units`. Updates skip value and re-triggers `peek`.

**Preloader Interface**

Preloaders cache file content in the background before preview is needed:

```
function M:preload(job)
    -- Load file content or metadata
    -- job.file: File to preload
    -- job.area: Available preview area
    -- job.skip: Always 0
    
    return complete, err
    -- complete: boolean, true if done, false to retry
    -- err: optional Error object
end
```

Returning `false` marks the task as incomplete, causing Yazi to retry the preloader at the next opportunity (e.g., page scroll).

**Sources:** [docs/plugins/overview.md216-295](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L216-L295)

## Execution Contexts

Yazi's plugin system implements a dual-context execution model to balance performance with concurrency.

### Context Architecture

**Sources:** [docs/plugins/overview.md77-178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L77-L178)

___

### Sync Context

The sync context is a single, persistent Lua state created at application startup and maintained throughout the application lifecycle. It is active during:

1.  **UI Rendering**: When Yazi renders the terminal interface
2.  **Sync Plugin Execution**: Plugins annotated with `@sync`
3.  **init.lua Execution**: User configuration initialization

**Characteristics:**

| Property | Description |
| --- | --- |
| **Lifecycle** | Created once at startup, destroyed at shutdown |
| **State Sharing** | All sync plugins share the same Lua state |
| **Global Access** | Can access `cx` global (application context) |
| **Concurrency** | Single-threaded, blocks UI rendering |
| **Performance** | Fast, no context switching overhead |

**State Management in Sync Context:**

Each plugin receives an isolated `state` table parameter to prevent global namespace pollution:

```
--- @sync entry
return {
    entry = function(state, job)
        state.counter = state.counter or 0
        state.counter = state.counter + 1
        -- state persists across invocations
    end
}
```

Yazi initializes a unique `state` table for each sync plugin. The table persists for the application's lifetime, enabling stateful plugin behavior.

**Sources:** [docs/plugins/overview.md103-131](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L103-L131)

___

### Async Context

When a plugin executes asynchronously (default behavior), Yazi creates an isolated async context:

**Characteristics:**

| Property | Description |
| --- | --- |
| **Lifecycle** | Created per invocation, destroyed after completion |
| **Isolation** | Each execution has its own Lua state |
| **Global Access** | Cannot directly access `cx` |
| **Concurrency** | Runs concurrently with main thread |
| **Use Case** | I/O operations, network requests, heavy computation |

Async plugins cannot directly access the global context (`cx`). To retrieve data from the sync context, they must use `ya.sync()` bridge functions.

**Sources:** [docs/plugins/overview.md132-163](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L132-L163)

___

### Cross-Context Communication: `ya.sync()`

The `ya.sync()` function creates a bridge between async and sync contexts:

**Key Constraints:**

1.  **Top-level Definition**: `ya.sync()` must be called at module top level, not inside conditionals or functions
2.  **Sendable Values**: Only primitives, strings, numbers, booleans, nil, Url, and tables of these types can cross contexts
3.  **Ownership Transfer**: Userdata (like `Url`) transfers ownership when passed, becoming invalid in the sender's context

**Example:**

```lua
-- Top-level definition (required)
local get_hovered = ya.sync(function(state)
    local h = cx.active.current.hovered
    return h and tostring(h.url) or nil
end)

return {
    entry = function(state, job)
        -- Call from async context
        local path = get_hovered()
        -- Do async work with path
    end
}
```

**Sources:** [docs/plugins/overview.md138-178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L138-L178)

## Annotations

Annotations control plugin behavior at runtime. They must appear at the very beginning of `main.lua` with no content before them.

### Annotation Syntax

```
--- @annotation_name value
--- @another_annotation value
return {
    -- plugin implementation
}
```

### `@sync` Annotation

Forces specific plugin methods to execute in sync context instead of async context:

| Value | Effect |
| --- | --- |
| `entry` | Run `entry` method in sync context |
| `peek` | Run `peek` method in sync context |

**Use Cases:**

-   Direct UI manipulation requiring immediate rendering
-   Accessing application state without bridge overhead
-   Synchronous state updates

**Example:**

```
--- @sync entry
return {
    entry = function(state, job)
        -- Runs in sync context
        -- Can access cx directly
        -- Blocks UI until complete
    end
}
```

**Warning:** Sync plugins block the UI rendering thread. Avoid long-running operations like I/O or network requests in sync context.

**Sources:** [docs/plugins/overview.md187-201](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L187-L201)

___

### `@since` Annotation

Specifies the minimum Yazi version required by the plugin:

```
--- @since 25.2.13
return {
    -- plugin implementation
}
```

If the user's Yazi version is lower than specified, execution fails with an error prompting the user to upgrade. This prevents compatibility issues with older Yazi versions.

**Sources:** [docs/plugins/overview.md203-214](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L203-L214)

## Data Model and Memory Safety

### Sendable Values

Cross-context data transfer is restricted to "sendable" types to ensure thread safety:

| Type | Sendable | Notes |
| --- | --- | --- |
| `nil` | ✅ |  |
| `boolean` | ✅ |  |
| `number` | ✅ |  |
| `string` | ✅ |  |
| `table` | ✅ | Must contain only sendable values |
| `Url` userdata | ✅ | Ownership transfers |
| Other userdata | ❌ | Not sendable |
| Functions | ❌ | Not sendable |

**Sources:** [docs/plugins/overview.md297-307](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L297-L307)

___

### Ownership Transfer

Yazi's plugin system inherits Rust's ownership model. Userdata types like `Url` have ownership semantics:

**Ownership Transfer Example:**

```
local target = Url("/tmp")
ya.emit("cd", { target })  -- Ownership transferred

-- ERROR: userdata has been destructed
ya.dbg(tostring(target))
```

**Avoiding Transfer with Cloning:**

```
local target = Url("/tmp")
ya.emit("cd", { Url(target) })  -- Clone passed, original retained

-- Works: original still valid
ya.dbg(tostring(target))
```

**Optimal Pattern (Use Before Transfer):**

```
local target = Url("/tmp")
local target_str = tostring(target)  -- Extract data first

ya.emit("cd", { target })  -- Transfer ownership
ya.dbg(target_str)  -- Works: string was extracted before transfer
```

**Sources:** [docs/plugins/overview.md309-340](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L309-L340)

## Plugin Lifecycle

**Lifecycle Stages:**

1.  **Startup**: Yazi creates sync context, executes `init.lua`, loads plugins, parses annotations
2.  **Initialization**: Plugin `setup()` methods run in sync context, allowing configuration
3.  **Registration**: Plugins register their interfaces (entry, peek, seek, preload) with Yazi core
4.  **Execution**: Plugins execute in sync or async context based on annotations and plugin type
5.  **Cleanup**: On shutdown, async tasks are cancelled and sync context is destroyed

**Sources:** [docs/plugins/overview.md77-178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L77-L178) [docs/plugins/overview.md216-295](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L216-L295)

___

## State Management Patterns

### Plugin-Specific State

Each sync plugin receives an isolated `state` table parameter:

```
--- @sync entry
return {
    entry = function(state, job)
        -- Initialize state on first run
        state.history = state.history or {}
        state.counter = state.counter or 0
        
        -- Update state
        table.insert(state.history, job.args[1])
        state.counter = state.counter + 1
    end
}
```

The `state` table:

-   Persists for the application's lifetime (sync context only)
-   Is unique per plugin (prevents namespace collisions)
-   Is only available in sync context
-   Cannot be accessed from async context (use `ya.sync()` to bridge)

### Configuration Pattern

Plugins typically use a `setup()` method for user configuration:

```lua
-- init.lua (sync context)
require("my-plugin"):setup({
    option1 = "value1",
    option2 = 42
})
```

```lua
-- my-plugin.yazi/main.lua
return {
    setup = function(state, opts)
        -- Save config to plugin state
        state.option1 = opts.option1
        state.option2 = opts.option2
    end,
    
    entry = function(state, job)
        -- Use configured options
        ya.dbg(state.option1)
    end
}
```

The `setup()` method runs during `init.lua` execution, which is synchronous, allowing plugins to store configuration in their persistent state.

**Sources:** [docs/plugins/overview.md82-101](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L82-L101) [docs/plugins/overview.md103-131](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L103-L131)

___

## Summary

Yazi's plugin architecture provides a sophisticated system for extending functionality while maintaining safety and performance:

-   **Modular Structure**: Plugins are self-contained `.yazi` directories with `main.lua` entry points
-   **Dual Contexts**: Sync context for UI operations, async context for concurrent tasks
-   **State Isolation**: Each plugin has its own persistent state table in sync context
-   **Cross-Context Bridge**: `ya.sync()` enables controlled data exchange between contexts
-   **Memory Safety**: Ownership transfer and sendable value constraints prevent data races
-   **Flexible Interfaces**: Support for functional plugins, previewers, preloaders, and UI components
-   **Version Control**: `@since` annotation ensures compatibility with plugin requirements

This architecture balances extensibility with performance, enabling complex plugins while maintaining responsive UI and thread safety.