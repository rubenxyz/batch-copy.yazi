Relevant source files

-   [docs/plugins/types.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md)
-   [docs/plugins/utils.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md)

This document provides an overview of Yazi's Lua plugin API architecture, introducing the four main API namespaces (`ya`, `ps`, `fs`, `Command`) and explaining how they provide different capabilities to plugins. For complete method-level documentation, see [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)). For information on data types used by these APIs, see [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system). For UI construction, see [Layout and UI API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.3-layout-and-ui-api).

## API Namespace Overview

Yazi's plugin API is organized into four distinct namespaces, each serving a specific purpose:

| Namespace | Purpose | Primary Use Cases | Context Availability |
| --- | --- | --- | --- |
| `ya` | Core application interface | UI rendering, user input, notifications, previews, caching, system info | Both sync and async (with restrictions) |
| `ps` | Publish-subscribe messaging | Inter-plugin communication, DDS integration, event handling | Sync context only |
| `fs` | Filesystem operations | File/directory I/O, metadata queries, path manipulation | Async context only |
| `Command` | External process execution | Running shell commands, piping data, process management | Async context only |

### Namespace Capabilities Breakdown

**ya Namespace**

The `ya` namespace provides the primary interface to Yazi's core functionality. It is divided into several capability groups:

**ps Namespace**

The `ps` namespace implements the publish-subscribe pattern for Yazi's Data Distribution Service (DDS):

**fs Namespace**

The `fs` namespace provides async filesystem operations:

**Command Namespace**

The `Command` namespace provides external process execution with a builder pattern:

Sources: [docs/plugins/utils.md1-1166](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1-L1166)

## Execution Context Model

Yazi plugins operate in two distinct execution contexts with different API availability and guarantees:

### Context Comparison

### API Availability Matrix

| API Method | Sync Context | Async Context | Notes |
| --- | --- | --- | --- |
| `ya.render()` | ✓ | ✗ | Only meaningful in sync context where UI state is accessible |
| `ya.hide()` | ✗ | ✓ | Requires exclusive terminal control resource |
| `ya.emit()` | ✓ | ✓ | Sends commands to manager layer |
| `ya.input()` | ✗ | ✓ | Blocks for user input |
| `ya.sync(fn)` | ✗ | ✓ | Bridges async → sync, executes `fn` in sync context |
| `ps.pub()` | ✓ | ✗ | Requires sync context to access cx state |
| `ps.sub()` | ✓ | ✗ | Callbacks run in sync context |
| `fs.*` | ✗ | ✓ | All filesystem ops are async-only |
| `Command` | ✗ | ✓ | Process execution is async-only |

### Context Transition: ya.sync()

Async plugins can access sync context state through `ya.sync()`, which takes a function and executes it in the sync context:

```lua
-- In async plugin
local update_state = ya.sync(function(self, new_value)
    -- This runs in sync context, can access cx and call ya.render()
    self.state = new_value
    ya.render()
end)

-- Later, call it from async context
update_state("updated value")
```

The `ya.sync()` pattern enables async plugins to trigger UI updates or access shared state while performing long-running operations asynchronously.

Sources: [docs/plugins/utils.md57-66](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L57-L66) [docs/plugins/utils.md325-333](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L325-L333) [docs/plugins/utils.md503-602](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L503-L602)

## Common API Usage Patterns

### Pattern 1: Async File Processing with Sync UI Update

### Pattern 2: Cross-Instance Communication via ps

### Pattern 3: External Command with Output Processing

Sources: [docs/plugins/utils.md748-915](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L748-L915) [docs/plugins/utils.md916-1161](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L916-L1161)

## Data Flow Through API Layers

## API Integration Points

The four API namespaces integrate with different parts of Yazi's core architecture:

| API Namespace | Core System Integration | Key Data Structures |
| --- | --- | --- |
| `ya` | UI renderer, task manager, cache system | `cx` (context), `Rect`, `Url`, `File` |
| `ps` | DDS router, event dispatcher | Message payloads (Sendable values) |
| `fs` | Async filesystem layer | `Url`, `Cha`, `File[]` |
| `Command` | Async process executor | `Child`, `Output`, `Status` |

### Type System Integration

All API namespaces use common types from Yazi's type system:

-   **Url**: File/directory paths, used across `ya`, `fs` namespaces
-   **Cha**: File characteristics (metadata), returned by `fs.cha()`
-   **File**: File object combining Url + Cha, used in preview/preload contexts
-   **Error**: Error reporting across all namespaces
-   **Sendable**: Values that can be passed through `ps.pub()` or `ya.emit()`

For complete type documentation, see [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system).

Sources: [docs/plugins/types.md1-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L1-L454)

## Next Steps

-   For detailed method signatures and examples, see [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command))
-   For data type specifications, see [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system)
-   For UI construction APIs, see [Layout and UI API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.3-layout-and-ui-api)
-   For practical plugin development guidance, see [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins)
-   For understanding execution contexts in depth, see [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture)