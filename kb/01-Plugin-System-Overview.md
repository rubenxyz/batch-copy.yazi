Relevant source files

-   [docs/plugins/overview.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md)
-   [docs/resources.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md)
-   [docs/tips.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md)

The Plugin System provides extensibility for Yazi through Lua-based plugins that can extend file management functionality, customize file previews, optimize performance through preloading, and integrate with external tools. This page provides an overview of the plugin architecture, types, and core concepts.

For detailed information about:

-   Plugin structure and annotations, see [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture)
-   Creating custom plugins, see [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins)
-   API reference documentation, see [Plugin API Reference](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3-plugin-api-reference)
-   Community-contributed plugins, see [Plugin Ecosystem](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.5-plugin-ecosystem)

## Plugin Types

Yazi supports four distinct plugin types, each serving a specific purpose in the application lifecycle:

**Sources:** [docs/plugins/overview.md44-58](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L44-L58) [docs/plugins/overview.md218-296](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L218-L296)

### Functional Plugins

Functional plugins execute user-triggered actions, bound to keybindings in `keymap.toml`. They run in response to keypresses and can perform operations like file manipulation, navigation, or integration with external tools.

| Example | Purpose | Typical Use Case |
| --- | --- | --- |
| `chmod.yazi` | Change file permissions | Modify file mode bits |
| `smart-enter.yazi` | Context-aware enter | Open files or enter directories |
| `fzf.yazi` | Fuzzy finding | Navigate using fuzzy search |

### Previewer Plugins

Previewers render file content in the preview pane. They implement `peek` (render content) and `seek` (scroll content) methods to display files as the user navigates.

| File Type | Method | Responsibility |
| --- | --- | --- |
| Images | `peek` | Decode and display image using terminal protocol |
| Code | `peek` | Syntax highlight and render text |
| Videos | `peek` | Extract thumbnail or show metadata |
| All types | `seek` | Handle scroll events (J/K keys) |

### Preloader Plugins

Preloaders run in the background to cache file metadata or thumbnails before the user hovers over files, improving perceived performance. They return a completion status indicating whether to retry.

### Fetcher Plugins

Fetchers provide metadata about files, particularly mime-types. The `mime-ext.yazi` fetcher, for example, determines mime-types from file extensions rather than content inspection for faster performance.

**Sources:** [docs/plugins/overview.md218-296](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L218-L296) [docs/resources.md14-157](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L14-L157)

## Plugin Structure

All plugins must follow a standardized directory structure for Yazi to recognize and load them:

### Directory Naming

-   Plugin directory name must use kebab-case
-   Must end with `.yazi` suffix
-   Examples: `smart-enter.yazi`, `full-border.yazi`, `chmod.yazi`

### Required Files

| File | Purpose |
| --- | --- |
| `main.lua` | Entry point containing plugin implementation |
| `README.md` | Plugin documentation |
| `LICENSE` | License information |

### Entry Point Interface

The `main.lua` file must return a table implementing one or more interface methods depending on plugin type:

```lua
-- Functional plugin
return {
  entry = function(self, job) end
}

-- Previewer plugin
return {
  peek = function(self, job) end,
  seek = function(self, job) end
}

-- Preloader plugin
return {
  preload = function(self, job) end
}
```

**Sources:** [docs/plugins/overview.md13-41](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L13-L41) [docs/plugins/overview.md216-296](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L216-L296)

## Execution Contexts

Yazi's plugin system operates in two distinct execution contexts with different capabilities and constraints:

### Sync Context

The sync context:

-   Created once at application startup
-   Active during UI rendering
-   Shared state across all sync plugins
-   Full access to `cx` (application context)
-   Used by `@sync` annotated plugins and `seek` methods

**Key characteristic:** Plugins in sync context share a persistent `state` table throughout the application lifecycle.

### Async Context

The async context:

-   Created per-execution for each async plugin
-   Isolated from other plugins
-   Concurrent execution with main thread
-   Cannot directly access `cx` without `ya.sync()` bridge
-   Used by default for functional plugins and all `peek`/`preload` methods

**Key characteristic:** Each async execution gets its own isolated context to prevent blocking the UI thread.

### Context Bridge

The `ya.sync()` function creates a bridge between async and sync contexts:

```lua
-- In async plugin
local get_hovered = ya.sync(function(state)
  return cx.active.current.hovered  -- Access sync context
end)

return {
  entry = function()
    local file = get_hovered()  -- Called from async
    -- Do async work with file data
  end
}
```

**Sources:** [docs/plugins/overview.md77-178](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L77-L178) [docs/tips.md64-102](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L64-L102)

## API Namespaces

The plugin API is organized into four primary namespaces, each providing specific capabilities:

### `ya` - Core Application Interface

Primary namespace for interacting with Yazi's core functionality:

-   Emit application events (`ya.emit`)
-   Access sync context from async (`ya.sync`)
-   UI rendering and notifications
-   File preview and caching
-   System information queries

### `ps` - Publish-Subscribe System

Enables event-based communication:

-   Publish events locally (`ps.pub`)
-   Subscribe to event kinds (`ps.sub`)
-   Cross-instance messaging (`ps.pub_to`, `ps.sub_remote`)
-   Integrates with DDS (Data Distribution Service)

### `fs` - Filesystem Operations

Provides async filesystem access:

-   Read/write file contents
-   Directory traversal
-   File metadata queries
-   CWD operations

### `Command` - Process Execution

Spawns and manages external processes:

-   Execute shell commands
-   Capture stdout/stderr
-   Stream output handling
-   Exit status checking

For complete API documentation, see [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)).

**Sources:** [docs/plugins/overview.md1-390](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L1-L390) Diagram 3 from high-level overview

## Plugin Lifecycle

The following diagram illustrates how plugins are loaded, initialized, and executed within Yazi:

### Initialization

1.  **Application Start:** Yazi loads all plugin directories ending in `.yazi`
2.  **Init Execution:** User's `init.lua` executes in sync context
3.  **Plugin Setup:** Plugins' `setup` methods called to initialize configuration
4.  **State Creation:** Each plugin receives isolated `state` table

### Execution

1.  **Trigger Event:** Keypress, hover, or navigation event occurs
2.  **Context Selection:** Yazi determines sync or async execution based on plugin annotations
3.  **Method Invocation:** Appropriate plugin method called with `job` parameter
4.  **API Access:** Plugin uses `ya`, `ps`, `fs`, or `Command` APIs
5.  **Result Handling:** Plugin returns values or triggers side effects

### State Management

-   **Sync plugins:** Share persistent state across all executions
-   **Async plugins:** Access sync state only via `ya.sync()` blocks
-   **State persistence:** Managed per-plugin to prevent namespace collisions

**Sources:** [docs/plugins/overview.md82-163](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L82-L163) [docs/tips.md119-141](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L119-L141)

## Configuration and Registration

Plugins are registered through two primary mechanisms depending on their type:

### Functional Plugins via keymap.toml

Functional plugins are bound to keybindings using the `plugin` command:

```
[[mgr.prepend_keymap]]
on  = "t"
run = "plugin smart-tab"
desc = "Create tab in hovered directory"

[[mgr.prepend_keymap]]
on  = "<C-f>"
run = "plugin fzf -- --preview"
desc = "Fuzzy find with preview"
```

Arguments after `--` are passed to the plugin via `job.args`.

### Preview Plugins via yazi.toml

Previewers, preloaders, and fetchers are configured in the `[plugin]` section:

```
[[plugin.prepend_previewers]]
name = "*.md"
run  = "custom-markdown"

[[plugin.prepend_preloaders]]
mime = "image/*"
run  = "image-preloader"

[[plugin.prepend_fetchers]]
id   = "mime"
name = "*"
run  = "mime-ext"
```

Matching rules use `name` (glob patterns) or `mime` (mime-types) to determine when plugins activate.

**Sources:** [docs/plugins/overview.md42-75](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L42-L75) [docs/tips.md143-165](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L143-L165)

## Annotations

Plugins use annotations at the file's top to declare runtime behavior:

| Annotation | Purpose | Example |
| --- | --- | --- |
| `@sync` | Run method in sync context | `--- @sync entry` |
| `@since` | Minimum Yazi version required | `--- @since 25.2.13` |

Annotations must appear before any code with no gaps:

```
--- @sync entry
--- @since 25.2.13
return {
  entry = function() end
}
```

The `@sync` annotation forces execution in the sync context, enabling direct `cx` access but potentially blocking the UI thread. Use sparingly for performance-critical operations.

**Sources:** [docs/plugins/overview.md179-214](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/overview.md#L179-L214)

## Built-in Plugins

Yazi ships with several built-in plugins demonstrating best practices:

| Plugin | Type | Purpose |
| --- | --- | --- |
| `chmod.yazi` | Functional | Change file permissions |
| `diff.yazi` | Functional | Compare files and generate patches |
| `smart-enter.yazi` | Functional | Context-aware open/enter action |
| `smart-filter.yazi` | Functional | Enhanced filtering with auto-enter |
| `smart-paste.yazi` | Functional | Paste into hovered directory |
| `full-border.yazi` | UI | Add complete border around interface |
| `git.yazi` | UI | Display git status in linemode |

For documentation on built-in plugins, see [Built-in Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.4-built-in-plugins).

For community-contributed plugins, see [Plugin Ecosystem](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.5-plugin-ecosystem).

**Sources:** [docs/resources.md52-145](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L52-L145) [docs/tips.md16-387](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L16-L387)