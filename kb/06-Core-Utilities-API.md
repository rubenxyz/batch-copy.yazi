Relevant source files

-   [docs/plugins/utils.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md)

## Purpose and Scope

This document provides a complete reference for Yazi's four core Lua API namespaces that plugins use to interact with the application and system:

-   **`ya`**: Core application interface for UI operations, previews, user input, notifications, and system information
-   **`ps`**: Publish-subscribe messaging system for cross-instance communication via DDS
-   **`fs`**: Asynchronous filesystem operations (read, write, create, remove, directory listing)
-   **`Command`**: External process execution with full stdio control

These APIs form the foundation of plugin development in Yazi. For information about UI components and layout types, see [Layout and UI API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.3-layout-and-ui-api). For data types used by these APIs (`Url`, `Cha`, `File`, etc.), see [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system). For architectural details about plugin execution contexts and the DDS system, see [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture) and [Data Distribution Service](https://deepwiki.com/yazi-rs/yazi-rs.github.io/5.2-data-distribution-service-(dds)).

**Sources:** [docs/plugins/utils.md1-1166](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1-L1166)

___

## API Overview and Context Model

### Execution Context Constraints

Yazi plugins execute in one of two contexts, and API availability depends on the context:

**Key Constraints:**

-   **Sync context**: Access to shared state (`cx`), can call `ya.render()`, `ya.emit()`, and all `ps` methods
-   **Async context**: Isolated concurrent execution, can perform I/O operations (`fs`, `Command`), UI interactions (`ya.input()`, `ya.hide()`)
-   **Context bridge**: `ya.sync()` allows async plugins to execute functions in sync context when state access is needed

**Sources:** [docs/plugins/utils.md29-746](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L29-L746)

### API Namespace Purposes

| Namespace | Primary Purpose | Context | Common Use Cases |
| --- | --- | --- | --- |
| `ya` | Application interface | Both | Rendering UI, showing previews, requesting input, logging |
| `ps` | Pub-sub messaging | Sync only | Cross-instance communication, event subscriptions |
| `fs` | Filesystem operations | Async only | Reading files, directory listing, file creation/removal |
| `Command` | Process execution | Async only | Running external tools, capturing output, piping data |

**Sources:** [docs/plugins/utils.md8-748](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L8-L748)

___

## ya API Reference

The `ya` namespace provides the core interface between plugins and the Yazi application. Methods are categorized by functionality.

### UI Control Methods

#### `ya.render()` {#render}

Re-render the UI to reflect state changes. Must be called after modifying plugin state to update the display.

```
local update_state = ya.sync(function(self, new_state)
    self.state = new_state
    ya.render()  -- Trigger UI update
end)
```

| Property | Value |
| --- | --- |
| Parameters | None |
| Returns | `unknown` |
| Context | Sync only |

**Sources:** [docs/plugins/utils.md52-66](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L52-L66)

#### `ya.hide()` {#hide}

Hide Yazi's TUI and return control to the terminal. Returns a `permit` object whose `drop()` method restores the UI.

```
local permit = ya.hide()
-- Terminal is now accessible
-- ... perform terminal operations ...
permit:drop()  -- Restore Yazi UI
```

**Important**: Only one `permit` can exist at a time. Calling `ya.hide()` again before dropping the previous permit throws an error, preventing deadlocks.

| Property | Value |
| --- | --- |
| Parameters | None |
| Returns | `Permit` (has `drop()` method) |
| Context | Async only |

**Sources:** [docs/plugins/utils.md10-29](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L10-L29)

#### `ya.emit(cmd, args)` {#emit}

Send a command to the manager layer (`[mgr]` in keymap) without waiting for execution. Arguments are converted to command-line format.

```
ya.emit("my-cmd", { "hello", 123, foo = true, bar_baz = "world" })
-- Equivalent to CLI: my-cmd "hello" "123" --foo --bar-baz="world"
```

| Property | Value |
| --- | --- |
| Parameters | `cmd: string`, `args: { [integer|string]: Sendable }` |
| Returns | `unknown` |
| Context | Both |
| Notes | Values must be [Sendable](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture) with ownership transfer |

**Sources:** [docs/plugins/utils.md68-83](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L68-L83)

### Preview System Methods

#### `ya.file_cache(opts)` {#file\_cache}

Calculate the cached URL for a given file, respecting user cache configuration.

```
local cache_url = ya.file_cache {
    file = file,  -- File object to cache
    skip = 1,     -- Units to skip (lines for code, % for video)
}
```

Returns `nil` if the file is not cacheable (e.g., ignored in config or already a cache file).

| Property | Value |
| --- | --- |
| Parameters | `{ file: File, skip: integer }` |
| Returns | `Url?` |
| Context | Both |

**Sources:** [docs/plugins/utils.md31-50](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L31-L50)

#### `ya.image_show(url, rect)` {#image\_show}

Display an image within the specified rectangle. The image automatically downscales to fit.

```
ya.image_show(url, rect)
```

| Property | Value |
| --- | --- |
| Parameters | `url: Url`, `rect: Rect` |
| Returns | `unknown` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md85-94](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L85-L94)

#### `ya.image_precache(src, dist)` {#image\_precache}

Pre-cache an image from `src` to `dist`, respecting configured `max_width` and `max_height`.

```
ya.image_precache(src, dist)
```

| Property | Value |
| --- | --- |
| Parameters | `src: Url`, `dist: Url` |
| Returns | `unknown` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md96-105](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L96-L105)

#### `ya.preview_code(opts)` {#preview\_code}

Preview a file as code in the specified area, using syntax highlighting.

```
local err, upper_bound = ya.preview_code {
    area = area,              -- Preview area rectangle
    file = file,              -- File to preview
    mime = "text/plain",      -- MIME type
    skip = 1,                 -- Lines to skip
}
```

Returns `(err, upper_bound)`:

-   `err`: Error string if preview fails, otherwise `nil`
-   `upper_bound`: Maximum bound if preview exceeds limits, otherwise `nil`

| Property | Value |
| --- | --- |
| Parameters | `{ area: Rect, file: File, mime: string, skip: integer }` |
| Returns | `Error?, integer?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md264-291](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L264-L291)

#### `ya.preview_widget(opts, widget)` {#preview\_widget}

Preview custom widgets in the specified area.

```lua
-- Single widget
ya.preview_widget(opts, ui.Line("Hello world"):area(area))

-- Multiple widgets
ya.preview_widget(opts, {
    ui.Line("Hello"):area(area1),
    ui.Line("world"):area(area2),
})
```

| Property | Value |
| --- | --- |
| Parameters | `opts: { area: Rect, file: File, mime: string, skip: integer }`, `widget: Renderable | Renderable[]` |
| Returns | `unknown` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md293-323](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L293-L323)

### User Interaction Methods

#### `ya.which(opts)` {#which}

Prompt users with a set of available key candidates.

```
local index = ya.which {
    cands = {
        { on = "a" },
        { on = "b", desc = "optional description" },
        { on = "<C-c>", desc = "key combination" },
        { on = { "d", "e" }, desc = "multiple keys" },
    },
    silent = false,  -- Show key indicator UI
}
-- Returns 1-based index if user selects, nil if canceled
```

| Property | Value |
| --- | --- |
| Parameters | `{ cands: { on: string|string[], desc: string? }[], silent: boolean? }` |
| Returns | `number?` (1-based index or nil) |
| Context | Async only |

**Sources:** [docs/plugins/utils.md107-134](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L107-L134)

#### `ya.input(opts)` {#input}

Request text input from the user with optional real-time updates.

```lua
-- Simple input
local value, event = ya.input {
    title = "Archive name:",
    value = "",           -- Default value
    obscure = false,      -- Hide input (password mode)
    position = { "top-center", y = 3, w = 40 },
}

-- Real-time input
local input = ya.input {
    title = "Input in realtime:",
    position = { "center", w = 50 },
    realtime = true,
    debounce = 0.3,  -- Wait 300ms after typing stops
}

while true do
    local value, event = input:recv()
    if not value then break end
    ya.dbg(value)
end
```

**Event codes:**

-   `0`: Unknown error
-   `1`: User confirmed (Enter)
-   `2`: User canceled (Esc)
-   `3`: Input changed (realtime mode only)

| Property | Value |
| --- | --- |
| Parameters | `{ title: string, value: string?, obscure: boolean?, position: AsPos, realtime: boolean?, debounce: number? }` |
| Returns | `(string?, integer)` or `Recv` (if realtime) |
| Context | Async only |

**Sources:** [docs/plugins/utils.md136-189](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L136-L189)

#### `ya.confirm(opts)` {#confirm}

Request user confirmation with a dialog.

```
local confirmed = ya.confirm {
    pos = { "center", w = 40, h = 10 },
    title = "Test",
    body = "Hello, World!",
}
```

| Property | Value |
| --- | --- |
| Parameters | `{ pos: AsPos, title: AsLine, body: AsText }` |
| Returns | `boolean` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md213-232](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L213-L232)

#### `ya.notify(opts)` {#notify}

Send a foreground notification to the user.

```
ya.notify {
    title = "Hello, World!",
    content = "This is a notification from Lua!",
    timeout = 6.5,
    level = "info",  -- "info", "warn", or "error"
}
```

| Property | Value |
| --- | --- |
| Parameters | `{ title: string, content: string, timeout: number, level: "info"|"warn"|"error"? }` |
| Returns | `unknown` |
| Context | Both |

**Sources:** [docs/plugins/utils.md191-211](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L191-L211)

### System Information Methods

**Sources:** [docs/plugins/utils.md334-502](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L334-L502)

#### `ya.target_os()` {#target\_os}

Returns the operating system name.

| Property | Value |
| --- | --- |
| Returns | `"linux"` | `"macos"` | `"ios"` | `"freebsd"` | `"dragonfly"` | `"netbsd"` | `"openbsd"` | `"solaris"` | `"android"` | `"windows"` |
| Context | Both |

**Sources:** [docs/plugins/utils.md334-340](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L334-L340)

#### `ya.target_family()` {#target\_family}

Returns the OS family.

| Property | Value |
| --- | --- |
| Returns | `"unix"` | `"windows"` | `"wasm"` |
| Context | Both |

**Sources:** [docs/plugins/utils.md342-348](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L342-L348)

#### `ya.uid()` {#uid}

Returns the current user's ID.

| Property | Value |
| --- | --- |
| Returns | `integer` |
| Context | Both |
| Available | Unix-like systems only |

**Sources:** [docs/plugins/utils.md440-447](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L440-L447)

#### `ya.gid()` {#gid}

Returns the current user's group ID.

| Property | Value |
| --- | --- |
| Returns | `integer` |
| Context | Both |
| Available | Unix-like systems only |

**Sources:** [docs/plugins/utils.md449-456](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L449-L456)

#### `ya.user_name(uid)` {#user\_name}

Get username by UID. Returns current user's name if no argument provided.

```
ya.user_name()      -- Current user
ya.user_name(1000)  -- User with UID 1000
```

| Property | Value |
| --- | --- |
| Parameters | `uid: integer?` |
| Returns | `string?` |
| Context | Both |
| Available | Unix-like systems only |

**Sources:** [docs/plugins/utils.md458-474](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L458-L474)

#### `ya.group_name(gid)` {#group\_name}

Get group name by GID. Returns current user's group if no argument provided.

```
ya.group_name()      -- Current group
ya.group_name(1000)  -- Group with GID 1000
```

| Property | Value |
| --- | --- |
| Parameters | `gid: integer?` |
| Returns | `string?` |
| Context | Both |
| Available | Unix-like systems only |

**Sources:** [docs/plugins/utils.md476-492](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L476-L492)

#### `ya.host_name()` {#host\_name}

Returns the hostname of the current machine.

| Property | Value |
| --- | --- |
| Returns | `string?` |
| Context | Both |
| Available | Unix-like systems only |

**Sources:** [docs/plugins/utils.md494-502](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L494-L502)

### Utility Methods

#### `ya.sync(fn)` {#sync}

Create a bridge function that executes in sync context from async context. See [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture) for details on context switching.

```
local update_state = ya.sync(function(self, new_state)
    self.state = new_state  -- Access plugin state
    ya.render()             -- Sync-only operation
end)

-- Call from async context
update_state(new_value)
```

| Property | Value |
| --- | --- |
| Parameters | `fn: fun(...: any): any` |
| Returns | `fun(...: any): any` |
| Context | Both |

**Sources:** [docs/plugins/utils.md325-332](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L325-L332)

#### `ya.hash(str)` {#hash}

Generate a hash string for algorithm-independent tasks like cache naming. Currently uses MD5 but may change to faster algorithms (e.g., xxHash) in the future.

```
local hash = ya.hash("Hello, World!")
```

| Property | Value |
| --- | --- |
| Parameters | `str: string` |
| Returns | `string` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md350-366](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L350-L366)

#### `ya.quote(str)` {#quote}

Quote special shell characters in a string for safe command execution.

```
local handle = io.popen("ls " .. ya.quote(filename))
```

| Property | Value |
| --- | --- |
| Parameters | `str: string` |
| Returns | `string` |
| Context | Both |

**Sources:** [docs/plugins/utils.md368-379](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L368-L379)

#### `ya.truncate(text, opts)` {#truncate}

Truncate text to specified width.

```
local truncated = ya.truncate("Hello, World!", {
    max = 5,
    rtl = false  -- Right-to-left truncation
})
```

| Property | Value |
| --- | --- |
| Parameters | `text: string`, `opts: { max: integer, rtl: boolean? }` |
| Returns | `string` |
| Context | Both |

**Sources:** [docs/plugins/utils.md381-398](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L381-L398)

#### `ya.clipboard(text)` {#clipboard}

Get or set system clipboard contents.

```
local content = ya.clipboard()        -- Get
ya.clipboard("new content")           -- Set
```

| Property | Value |
| --- | --- |
| Parameters | `text: string?` |
| Returns | `string?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md400-416](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L400-L416)

#### `ya.time()` {#time}

Get current timestamp as float (integer part = seconds, decimal = milliseconds).

| Property | Value |
| --- | --- |
| Returns | `number` |
| Context | Both |

**Sources:** [docs/plugins/utils.md418-424](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L418-L424)

#### `ya.sleep(secs)` {#sleep}

Sleep for specified seconds.

```
ya.sleep(0.5)  -- 500 milliseconds
```

| Property | Value |
| --- | --- |
| Parameters | `secs: number` |
| Returns | `unknown` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md426-438](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L426-L438)

### Logging Methods

#### `ya.dbg(msg, ...)` {#dbg}

Log debug messages to the log file. Accepts any data type.

```
ya.dbg("Hello", "World!")
ya.dbg({ foo = "bar", baz = 123, qux = true })
```

| Property | Value |
| --- | --- |
| Parameters | `msg: any`, `...: any` |
| Returns | `unknown` |
| Context | Both |

**Sources:** [docs/plugins/utils.md234-247](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L234-L247)

#### `ya.err(msg, ...)` {#err}

Log error messages to the log file. Accepts any data type.

```
ya.err("Hello", "World!")
ya.err({ foo = "bar", baz = 123, qux = true })
```

| Property | Value |
| --- | --- |
| Parameters | `msg: any`, `...: any` |
| Returns | `unknown` |
| Context | Both |

**Sources:** [docs/plugins/utils.md249-262](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L249-L262)

___

## ps API Reference

The `ps` namespace implements Yazi's pub-sub messaging system for the Data Distribution Service (DDS). All `ps` methods execute in sync context only. For architectural details, see [Data Distribution Service](https://deepwiki.com/yazi-rs/yazi-rs.github.io/5.2-data-distribution-service-(dds)).

**Sources:** [docs/plugins/utils.md503-601](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L503-L601)

### `ps.pub(kind, value)` {#ps\_pub}

Publish a message to the current instance. All local subscribers receive it.

```
ps.pub("greeting", "Hello, World!")
```

**Best practice**: Prefix `kind` with plugin name to avoid conflicts (e.g., `my-plugin-event1`).

| Property | Value |
| --- | --- |
| Parameters | `kind: string` (alphanumeric with dashes, not built-in kinds), `value: Sendable` |
| Returns | `unknown` |
| Context | Sync only |
| Notes | Value must be [Sendable](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture) with ownership transfer |

**Sources:** [docs/plugins/utils.md509-524](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L509-L524)

### `ps.pub_to(receiver, kind, value)` {#ps\_pub\_to}

Publish a message to a specific instance or broadcast to all instances.

```
ps.pub_to(1711957283332834, "greeting", "Hello, World!")  -- To specific instance
ps.pub_to(0, "greeting", "Hello!")                         -- Broadcast to all
```

**Delivery rules:**

-   **Local**: `receiver` is current instance and subscribed via `sub()` → receives message
-   **Remote**: `receiver` isn't current instance and subscribed via `sub_remote()` → receives message
-   **Broadcast**: `receiver` is `0` → all remote instances with `sub_remote()` receive message

| Property | Value |
| --- | --- |
| Parameters | `receiver: integer`, `kind: string`, `value: Sendable` |
| Returns | `unknown` |
| Context | Sync only |

**Sources:** [docs/plugins/utils.md526-545](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L526-L545)

### `ps.sub(kind, callback)` {#ps\_sub}

Subscribe to local messages. Callback executes in sync context with access to `cx` state.

```
ps.sub("cd", function(body)
    ya.dbg("New cwd", cx.active.current.cwd)
end)
```

**Important**: Each `kind` can only be subscribed once per plugin. Re-subscribing without unsubscribing throws an error.

| Property | Value |
| --- | --- |
| Parameters | `kind: string`, `callback: fun(body: Sendable)` |
| Returns | `unknown` |
| Context | Sync only |
| Notes | No time-consuming work in callback |

**Sources:** [docs/plugins/utils.md547-565](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L547-L565)

### `ps.sub_remote(kind, callback)` {#ps\_sub\_remote}

Subscribe to remote messages instead of local ones.

```
ps.sub_remote("remote-event", function(body)
    -- Handle remote instance message
end)
```

| Property | Value |
| --- | --- |
| Parameters | `kind: string`, `callback: fun(body: Sendable)` |
| Returns | `unknown` |
| Context | Sync only |

**Sources:** [docs/plugins/utils.md567-575](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L567-L575)

### `ps.unsub(kind)` {#ps\_unsub}

Unsubscribe from local messages.

```
ps.unsub("my-message")
```

| Property | Value |
| --- | --- |
| Parameters | `kind: string` |
| Returns | `unknown` |
| Context | Sync only |

**Sources:** [docs/plugins/utils.md577-588](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L577-L588)

### `ps.unsub_remote(kind)` {#ps\_unsub\_remote}

Unsubscribe from remote messages.

```
ps.unsub_remote("my-message")
```

| Property | Value |
| --- | --- |
| Parameters | `kind: string` |
| Returns | `unknown` |
| Context | Sync only |

**Sources:** [docs/plugins/utils.md590-601](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L590-L601)

___

## fs API Reference

The `fs` namespace provides asynchronous filesystem operations. All methods execute in async context only.

**Sources:** [docs/plugins/utils.md603-746](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L603-L746)

### `fs.cwd()` {#fs\_cwd}

Get the process's current working directory (CWD) from last `chdir` call.

```
local url, err = fs.cwd()
```

**Note**: This is different from `cx.active.current.cwd`, which updates immediately when the user navigates. `fs.cwd()` reflects the actual filesystem CWD, which may lag due to I/O validation (especially on slow devices like HDDs).

Use `cx.active.current.cwd` for user's current location. Use `fs.cwd()` when you need a valid directory for process spawning.

| Property | Value |
| --- | --- |
| Returns | `Url?, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md607-632](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L607-L632)

### `fs.cha(url, follow)` {#fs\_cha}

Get file/directory metadata (characteristics).

```
local cha, err = fs.cha(url)        -- Don't follow symlinks
local cha, err = fs.cha(url, true)  -- Follow symlinks
```

Returns a `Cha` object with file attributes. See [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system) for `Cha` properties.

| Property | Value |
| --- | --- |
| Parameters | `url: Url`, `follow: boolean?` |
| Returns | `Cha?, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md634-651](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L634-L651)

### `fs.write(url, data)` {#fs\_write}

Write data to a file, creating or overwriting it.

```
local ok, err = fs.write(url, "hello world")
```

| Property | Value |
| --- | --- |
| Parameters | `url: Url`, `data: string` |
| Returns | `boolean, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md653-666](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L653-L666)

### `fs.create(type, url)` {#fs\_create}

Create directories at the specified URL.

```
local ok, err = fs.create("dir", Url("/tmp/test"))              -- Single directory
local ok, err = fs.create("dir_all", Url("/tmp/test/nested"))  -- Recursive creation
```

| Type | Behavior |
| --- | --- |
| `"dir"` | Create a single empty directory |
| `"dir_all"` | Recursively create directory and all parent directories |

| Property | Value |
| --- | --- |
| Parameters | `type: "dir" | "dir_all"`, `url: Url` |
| Returns | `boolean, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md668-686](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L668-L686)

### `fs.remove(type, url)` {#fs\_remove}

Remove files or directories from the filesystem.

```
local ok, err = fs.remove("file", Url("/tmp/test.txt"))        -- Remove file
local ok, err = fs.remove("dir", Url("/tmp/empty"))            -- Remove empty dir
local ok, err = fs.remove("dir_all", Url("/tmp/test"))         -- Remove dir with contents
local ok, err = fs.remove("dir_clean", Url("/tmp/test"))       -- Remove empty subdirs
```

| Type | Behavior |
| --- | --- |
| `"file"` | Remove a single file |
| `"dir"` | Remove an empty directory |
| `"dir_all"` | Remove directory and all contents (use carefully!) |
| `"dir_clean"` | Remove all empty subdirectories; remove parent if it becomes empty |

| Property | Value |
| --- | --- |
| Parameters | `type: "file" | "dir" | "dir_all" | "dir_clean"`, `url: Url` |
| Returns | `boolean, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md688-708](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L688-L708)

### `fs.read_dir(url, options)` {#fs\_read\_dir}

Read directory contents with optional filtering and limits.

```
local files, err = fs.read_dir(url, {
    glob = "*.txt",   -- Optional glob pattern
    limit = 10,       -- Max files to read (default: unlimited)
    resolve = false,  -- Resolve symlinks (default: false)
})
```

Returns an array of `File` objects. See [Type System](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.2-type-system) for `File` properties.

| Property | Value |
| --- | --- |
| Parameters | `url: Url`, `options: { glob: string?, limit: integer?, resolve: boolean? }` |
| Returns | `File[]?, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md710-730](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L710-L730)

### `fs.unique_name(url)` {#fs\_unique\_name}

Generate a unique filename by appending `_n` if the file exists.

```
local url, err = fs.unique_name(Url("/tmp/test.txt"))
-- If test.txt exists, returns test_1.txt
-- If test_1.txt exists, returns test_2.txt, etc.
```

| Property | Value |
| --- | --- |
| Parameters | `url: Url` |
| Returns | `Url?, Error?` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md732-746](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L732-L746)

___

## Command API Reference

The `Command` API executes external processes asynchronously with full control over stdio streams, environment variables, and working directory.

**Sources:** [docs/plugins/utils.md748-915](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L748-L915)

### Command Constructor

#### `Command(value)` {#command\_new}

Create a new command builder.

```
local cmd = Command("ls")
```

| Property | Value |
| --- | --- |
| Parameters | `value: string` (command name or path) |
| Returns | `Self` |
| Context | Async only |

**Sources:** [docs/plugins/utils.md907-914](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L907-L914)

### Command Builder Methods

#### `arg(self, arg)` / `args(self, args)` {#command\_arg}

Append arguments to the command.

```
local cmd = Command("ls"):arg("-a"):arg("-l")
-- Or equivalently:
local cmd = Command("ls"):args({ "-a", "-l" })
```

| Property | Value |
| --- | --- |
| Parameters | `arg: string | string[]` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md763-777](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L763-L777)

#### `cwd(self, dir)` {#command\_cwd}

Set the command's working directory.

```
local cmd = Command("ls"):cwd("/root")
```

| Property | Value |
| --- | --- |
| Parameters | `dir: string` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md779-791](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L779-L791)

#### `env(self, key, value)` {#command\_env}

Add environment variables to the command.

```
local cmd = Command("ls")
    :env("PATH", "/bin")
    :env("HOME", "/home")
```

| Property | Value |
| --- | --- |
| Parameters | `key: string`, `value: string` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md793-806](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L793-L806)

#### `stdin(self, stdio)` {#command\_stdin}

Configure stdin stream.

```
local cmd = Command("cat"):stdin(Command.PIPED)
```

| Constant | Behavior |
| --- | --- |
| `Command.PIPED` | Pipe stdin for writing |
| `Command.NULL` | Discard stdin (default) |
| `Command.INHERIT` | Inherit parent's stdin |

| Property | Value |
| --- | --- |
| Parameters | `stdio: Stdio` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md808-826](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L808-L826)

#### `stdout(self, stdio)` {#command\_stdout}

Configure stdout stream.

```
local cmd = Command("ls"):stdout(Command.PIPED)
```

| Constant | Behavior |
| --- | --- |
| `Command.PIPED` | Pipe stdout for reading |
| `Command.NULL` | Discard stdout (default) |
| `Command.INHERIT` | Inherit parent's stdout |

| Property | Value |
| --- | --- |
| Parameters | `stdio: Stdio` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md828-846](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L828-L846)

#### `stderr(self, stdio)` {#command\_stderr}

Configure stderr stream.

```
local cmd = Command("ls"):stderr(Command.PIPED)
```

| Constant | Behavior |
| --- | --- |
| `Command.PIPED` | Pipe stderr for reading |
| `Command.NULL` | Discard stderr (default) |
| `Command.INHERIT` | Inherit parent's stderr |

| Property | Value |
| --- | --- |
| Parameters | `stdio: Stdio` |
| Returns | `self` |

**Sources:** [docs/plugins/utils.md848-866](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L848-L866)

### Execution Methods

#### `spawn(self)` {#command\_spawn}

Spawn the command as a child process.

```
local child, err = Command("ls"):spawn()
```

Returns a `Child` object for interacting with the running process.

| Property | Value |
| --- | --- |
| Returns | `Child?, Error?` |

**Sources:** [docs/plugins/utils.md868-879](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L868-L879)

#### `output(self)` {#command\_output}

Spawn the command and wait for it to complete, capturing output.

```
local output, err = Command("ls"):output()
if output then
    ya.dbg("stdout:", output.stdout)
    ya.dbg("stderr:", output.stderr)
    ya.dbg("success:", output.status.success)
end
```

Returns an `Output` object with `status`, `stdout`, and `stderr`.

| Property | Value |
| --- | --- |
| Returns | `Output?, Error?` |

**Sources:** [docs/plugins/utils.md881-892](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L881-L892)

#### `status(self)` {#command\_status}

Execute the command and wait for completion, returning only exit status.

```
local status, err = Command("ls"):status()
if status then
    ya.dbg("success:", status.success)
    ya.dbg("code:", status.code)
end
```

Returns a `Status` object with `success` and `code` fields.

| Property | Value |
| --- | --- |
| Returns | `Status?, Error?` |

**Sources:** [docs/plugins/utils.md894-905](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L894-L905)

___

## Child Process API

The `Child` object represents a running process spawned by `Command:spawn()`. It provides methods for reading output, writing input, and managing the process lifecycle.

**Sources:** [docs/plugins/utils.md916-1115](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L916-L1115)

### Reading Output

#### `read(self, len)` {#child\_read}

Read data from stdout or stderr alternately.

```
local data, event = child:read(1024)
```

**Event codes:**

-   `0`: Data from stdout
-   `1`: Data from stderr
-   `2`: No data available from either stream

| Property | Value |
| --- | --- |
| Parameters | `len: integer` |
| Returns | `string, integer` |

**Sources:** [docs/plugins/utils.md922-940](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L922-L940)

#### `read_line(self)` {#child\_read\_line}

Read data line by line from stdout or stderr.

```
local line, event = child:read_line()
```

Event codes are the same as `read()`.

| Property | Value |
| --- | --- |
| Returns | `string, integer` |

**Sources:** [docs/plugins/utils.md942-953](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L942-L953)

#### `read_line_with(self, opts)` {#child\_read\_line\_with}

Read lines with timeout support.

```
local line, event = child:read_line_with {
    timeout = 500,  -- Milliseconds
}
```

**Additional event code:**

-   `3`: Timeout elapsed

| Property | Value |
| --- | --- |
| Parameters | `opts: { timeout: integer }` |
| Returns | `string, integer` |

**Sources:** [docs/plugins/utils.md955-975](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L955-L975)

### Writing Input

#### `write_all(self, src)` {#child\_write\_all}

Write all data to the child's stdin.

```
local ok, err = child:write_all("input data\n")
```

**Requirements:**

1.  `stdin(Command.PIPED)` must be set
2.  `take_stdin()` must not have been called

| Property | Value |
| --- | --- |
| Parameters | `src: string` |
| Returns | `boolean, Error?` |

**Sources:** [docs/plugins/utils.md977-995](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L977-L995)

#### `flush(self)` {#child\_flush}

Flush buffered data to stdin.

```
local ok, err = child:flush()
```

**Requirements:** Same as `write_all()`.

| Property | Value |
| --- | --- |
| Returns | `boolean, Error?` |

**Sources:** [docs/plugins/utils.md997-1015](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L997-L1015)

### Stream Transfer

#### `take_stdin(self)` {#child\_take\_stdin}

Transfer ownership of the stdin stream.

```
local stdin = child:take_stdin()
```

Can only be called once. Only works if `stdin(Command.PIPED)` was set.

| Property | Value |
| --- | --- |
| Returns | `Stdio?` |

**Sources:** [docs/plugins/utils.md1056-1070](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1056-L1070)

#### `take_stdout(self)` {#child\_take\_stdout}

Transfer ownership of the stdout stream, useful for piping.

```
local echo = Command("echo"):arg("Hello"):stdout(Command.PIPED):spawn()
local rev = Command("rev"):stdin(echo:take_stdout()):stdout(Command.PIPED):output()
ya.dbg(rev.stdout)  -- "olleH\n"
```

Can only be called once. Only works if `stdout(Command.PIPED)` was set.

| Property | Value |
| --- | --- |
| Returns | `Stdio?` |

**Sources:** [docs/plugins/utils.md1072-1096](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1072-L1096)

#### `take_stderr(self)` {#child\_take\_stderr}

Transfer ownership of the stderr stream.

```
local stderr = child:take_stderr()
```

Can only be called once. Only works if `stderr(Command.PIPED)` was set.

| Property | Value |
| --- | --- |
| Returns | `Stdio?` |

**Sources:** [docs/plugins/utils.md1098-1114](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1098-L1114)

### Process Control

#### `wait(self)` {#child\_wait}

Wait for the child process to exit.

```
local status, err = child:wait()
```

| Property | Value |
| --- | --- |
| Returns | `Status?, Error?` |

**Sources:** [docs/plugins/utils.md1017-1028](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1017-L1028)

#### `wait_with_output(self)` {#child\_wait\_with\_output}

Wait for the child process and capture all output.

```
local output, err = child:wait_with_output()
```

| Property | Value |
| --- | --- |
| Returns | `Output?, Error?` |

**Sources:** [docs/plugins/utils.md1030-1041](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1030-L1041)

#### `start_kill(self)` {#child\_start\_kill}

Send SIGTERM to the child process.

```
local ok, err = child:start_kill()
```

| Property | Value |
| --- | --- |
| Returns | `boolean, Error?` |

**Sources:** [docs/plugins/utils.md1043-1054](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1043-L1054)

___

## Output and Status Types

### Output {#output}

Returned by `Command:output()` and `Child:wait_with_output()`.

| Field | Type | Description |
| --- | --- | --- |
| `status` | `Status` | Exit status of the process |
| `stdout` | `string` | Standard output contents |
| `stderr` | `string` | Standard error contents |

**Sources:** [docs/plugins/utils.md1116-1140](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1116-L1140)

### Status {#status}

Returned by `Command:status()` and `Child:wait()`.

| Field | Type | Description |
| --- | --- | --- |
| `success` | `boolean` | Whether the process exited successfully |
| `code` | `integer?` | Exit code (nil if process was terminated by signal) |

**Sources:** [docs/plugins/utils.md1142-1161](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L1142-L1161)

___

## Usage Examples

### Example: Interactive Preview with Input

```
function Entry:entry()
    local value, event = ya.input {
        title = "Enter search term:",
        position = { "top-center", y = 3, w = 60 },
    }
    
    if event == 1 then  -- Confirmed
        local output, err = Command("rg")
            :args({ value, cx.active.current.cwd })
            :stdout(Command.PIPED)
            :output()
        
        if output then
            ya.preview_widget({
                area = area,
                file = file,
                mime = "text/plain",
                skip = 0,
            }, ui.Text.parse(output.stdout))
        end
    end
end
```

**Sources:** [docs/plugins/utils.md136-892](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L136-L892)

### Example: Cross-Instance Clipboard with DDS

```lua
-- Subscribe to remote yank events
ps.sub_remote("yank", function(body)
    ya.clipboard(body.content)
    ya.notify {
        title = "Clipboard Synced",
        content = "Yanked from remote instance",
        timeout = 3,
        level = "info",
    }
end)

-- Publish yank event to all instances
local update_clipboard = ya.sync(function()
    local content = ya.clipboard()
    ps.pub_to(0, "yank", { content = content })
end)
```

**Sources:** [docs/plugins/utils.md191-575](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L191-L575)

### Example: Async File Processing with Progress

```
function Entry:entry(args)
    local files, err = fs.read_dir(cx.active.current.cwd, {
        limit = 100,
        resolve = true,
    })
    
    if not files then
        ya.err("Failed to read directory:", err)
        return
    end
    
    for i, file in ipairs(files) do
        ya.dbg(string.format("Processing %d/%d: %s", i, #files, file.url))
        
        local cha, err = fs.cha(file.url)
        if cha and cha.is_dir then
            local ok, err = fs.create("dir_all", file.url:join("backup"))
            if not ok then
                ya.err("Failed to create backup dir:", err)
            end
        end
        
        ya.sleep(0.1)  -- Rate limiting
    end
    
    ya.notify {
        title = "Processing Complete",
        content = string.format("Processed %d files", #files),
        timeout = 5,
    }
end
```

**Sources:** [docs/plugins/utils.md191-730](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/utils.md#L191-L730)