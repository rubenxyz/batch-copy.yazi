Relevant source files

-   [docs/plugins/types.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md)

This document provides a complete reference for the data types used in Yazi's Lua plugin API. These types represent core entities such as file paths, file metadata, icons, and errors that plugins interact with when accessing Yazi's functionality.

For information about the APIs that operate on these types, see [Core Utilities API (ya, ps, fs, Command)](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command)). For UI-specific types like `ui.Rect`, `ui.Text`, and `ui.Style`, see [Layout and UI API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.3-layout-and-ui-api).

## Type System Overview

Yazi's Lua plugin API exposes six fundamental types that represent different aspects of the file management system. These types are passed to and returned from API functions across the `ya`, `fs`, `ps`, and `Command` namespaces.

### Type Hierarchy and API Integration

**Sources:** [docs/plugins/types.md1-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L1-L454)

| Type | Primary Purpose | Key Properties | Used By |
| --- | --- | --- | --- |
| `Url` | Represent file paths and archive locations | `name`, `stem`, `parent`, `is_regular`, `is_archive` | All file operations |
| `Cha` | Store file metadata and characteristics | `is_dir`, `len`, `mtime`, `uid`, `perm()` | File inspection |
| `File` | Minimal file representation | `url`, `cha`, `link_to`, `name` | Directory listings |
| `Icon` | Visual icon representation | `text`, `style` | UI rendering |
| `Error` | Error information | `code` | Error handling |
| `Window` | Terminal dimensions | `rows`, `cols`, `width`, `height` | Layout calculations |

**Sources:** [docs/plugins/types.md8-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L8-L454)

## Url Type

The `Url` type represents file paths in Yazi, including both regular filesystem paths and special archive URLs. It provides path manipulation methods similar to Rust's `PathBuf`.

### Construction

```lua
-- Regular file
local url = Url("/root/Downloads/logo.png")

-- File inside an archive
local url = Url("archive:///root/ost.zip#bgm.mp3")
```

**Sources:** [docs/plugins/types.md8-18](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L8-L18)

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `name` | `string?` | Filename (e.g., `"logo.png"`) |
| `stem` | `string?` | Filename without extension (e.g., `"logo"`) |
| `frag` | `string?` | Archive fragment after `#` (e.g., `"bgm.mp3"`) |
| `parent` | `Url?` | Parent directory |
| `is_regular` | `boolean` | Whether this is a regular file (not search/archive) |
| `is_search` | `boolean` | Whether this is from a search result |
| `is_archive` | `boolean` | Whether this is an archive URL |
| `is_absolute` | `boolean` | Whether the path is absolute |
| `has_root` | `boolean` | Whether the path has a root component |

**Sources:** [docs/plugins/types.md20-93](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L20-L93)

### Methods

#### Path Manipulation

```lua
-- Join paths
local child = url:join("subdir/file.txt")

-- Check path relationships
if url:starts_with("/home/user") then
    -- ...
end

if url:ends_with(".txt") then
    -- ...
end

-- Strip prefix
local relative = url:strip_prefix("/home/user")
```

| Method | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `join(self, another)` | `another: Url | string` | `Url` | Create new URL by joining paths |
| `starts_with(self, another)` | `another: Url | string` | `boolean` | Check if URL starts with prefix |
| `ends_with(self, another)` | `another: Url | string` | `boolean` | Check if URL ends with suffix |
| `strip_prefix(self, another)` | `another: Url | string` | `Url` | Remove prefix from URL |

**Sources:** [docs/plugins/types.md94-133](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L94-L133)

#### Metamethods

```lua
-- Equality comparison
if url1 == url2 then
    -- ...
end

-- Convert to string
local path = tostring(url)

-- Concatenate with string
local url2 = url .. "/file.txt"
```

| Metamethod | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `__eq(self, another)` | `another: Url` | `boolean` | Equality comparison |
| `__tostring(self)` | \- | `string` | Convert to string representation |
| `__concat(self, another)` | `another: string` | `Url` | Concatenate with string |
| `__new(value)` | `value: string | Url` | `Url` | Constructor (called by `Url()`) |

**Sources:** [docs/plugins/types.md134-171](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L134-L171)

### Url Type Structure Diagram

**Sources:** [docs/plugins/types.md8-171](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L8-L171)

## Cha Type

The `Cha` (characteristics) type stores file metadata including type, permissions, timestamps, and ownership. It corresponds to information typically retrieved via `stat()` system calls.

### File Type Properties

| Property | Type | Description |
| --- | --- | --- |
| `is_dir` | `boolean` | Directory |
| `is_hidden` | `boolean` | Hidden file (Unix: starts with `.`, Windows: hidden attribute) |
| `is_link` | `boolean` | Symbolic link |
| `is_orphan` | `boolean` | Broken symlink (points to non-existent target) |
| `is_dummy` | `boolean` | Failed to load metadata (unsupported filesystem) |
| `is_block` | `boolean` | Block device |
| `is_char` | `boolean` | Character device |
| `is_fifo` | `boolean` | Named pipe (FIFO) |
| `is_sock` | `boolean` | Unix socket |
| `is_exec` | `boolean` | Executable file |
| `is_sticky` | `boolean` | Sticky bit set |

**Sources:** [docs/plugins/types.md176-263](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L176-L263)

### Size and Timestamps

| Property | Type | Description |
| --- | --- | --- |
| `len` | `integer` | File size in bytes (use `fs.File:size()` for directories) |
| `atime` | `integer?` | Last access time (Unix timestamp) |
| `btime` | `integer?` | Birth/creation time (Unix timestamp) |
| `mtime` | `integer?` | Last modification time (Unix timestamp) |

**Sources:** [docs/plugins/types.md264-297](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L264-L297)

### Unix-Specific Properties

These properties are only available on Unix-like systems (Linux, macOS, BSD):

| Property | Type | Description |
| --- | --- | --- |
| `uid` | `integer?` | User ID of owner |
| `gid` | `integer?` | Group ID of owner |
| `nlink` | `integer?` | Number of hard links |

**Sources:** [docs/plugins/types.md298-324](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L298-L324)

### Methods

#### Permission String

```lua
-- Get Unix permission string
local perm = cha:perm()  -- Returns "drwxr-xr-x" or similar
```

| Method | Returns | Description | Availability |
| --- | --- | --- | --- |
| `perm(self)` | `string?` | Unix permission string (e.g., `"drwxr-xr-x"`) | Unix-like systems only |

**Sources:** [docs/plugins/types.md325-333](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L325-L333)

### Cha Property Categories

**Sources:** [docs/plugins/types.md172-333](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L172-L333)

## File Type

The `File` type represents a bare file without context information. This is distinct from `fs.File` (documented in [Core Utilities API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.1-core-utilities-api-(ya-ps-fs-command))), which includes additional context like icon and highlight information.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `url` | `Url` | File path |
| `cha` | `Cha` | File characteristics |
| `link_to` | `Url?` | Symlink target (only present for symlinks) |
| `name` | `string` | Filename |

**Sources:** [docs/plugins/types.md334-369](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L334-L369)

### Usage Example

```lua
-- File is typically obtained from directory listings or plugin parameters
local file = ... -- Passed to plugin

-- Access properties
local path = file.url
local size = file.cha.len
local is_directory = file.cha.is_dir

-- Check for symlink
if file.cha.is_link and file.link_to then
    ya.err("Symlink points to: " .. tostring(file.link_to))
end
```

### File vs fs.File

**Sources:** [docs/plugins/types.md334-369](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L334-L369)

## Icon Type

The `Icon` type represents a visual icon with styling information, used for rendering file icons in the UI.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `text` | `string` | Icon text (typically a Unicode character) |
| `style` | `Style` | Icon styling (see [Layout and UI API](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3.3-layout-and-ui-api) for `Style`) |

**Sources:** [docs/plugins/types.md370-389](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L370-L389)

### Usage Example

```lua
-- Icons are typically obtained from file operations
local icon = file:icon()

-- Access properties
ya.preview_widgets(job, {
    ui.Text.default(icon.text):style(icon.style),
    -- ...
})
```

**Sources:** [docs/plugins/types.md370-389](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L370-L389)

## Error Type

The `Error` type represents an error that occurred during an operation. Errors can be caught and inspected in plugin code.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `code` | `integer` | Raw error code (system-dependent) |

**Sources:** [docs/plugins/types.md390-401](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L390-L401)

### Metamethods

```lua
-- Convert error to string
local message = tostring(err)

-- Concatenate with string
local detailed = err .. " - additional context"
```

| Metamethod | Parameters | Returns | Description |
| --- | --- | --- | --- |
| `__tostring(self)` | \- | `string` | Convert error to human-readable string |
| `__concat(self, another)` | `another: string` | `Error` | Concatenate error with string |

**Sources:** [docs/plugins/types.md402-420](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L402-L420)

### Error Handling Pattern

**Sources:** [docs/plugins/types.md390-420](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L390-L420)

## Window Type

The `Window` type provides information about the terminal window dimensions, useful for layout calculations and responsive UI rendering.

### Properties

| Property | Type | Description |
| --- | --- | --- |
| `rows` | `integer` | Number of terminal rows (height in characters) |
| `cols` | `integer` | Number of terminal columns (width in characters) |
| `width` | `integer` | Window width in pixels |
| `height` | `integer` | Window height in pixels |

**Sources:** [docs/plugins/types.md421-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L421-L454)

### Usage Example

```lua
-- Obtain window information
local window = ya.window()

-- Calculate responsive layout
local preview_width = math.floor(window.cols * 0.6)
local sidebar_width = window.cols - preview_width

-- Check pixel dimensions for image preview
if window.width > 0 and window.height > 0 then
    -- Terminal supports pixel queries
    local image_max_width = math.floor(window.width * 0.5)
end
```

### Window Dimensions

**Sources:** [docs/plugins/types.md421-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L421-L454)

## Type Usage Patterns

The following diagram illustrates common patterns for how these types are used together in plugin code:

**Sources:** [docs/plugins/types.md1-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L1-L454)

## Type Conversion and Construction

| Type | Construction | String Conversion | Notes |
| --- | --- | --- | --- |
| `Url` | `Url(string)` or `Url(url)` | `tostring(url)` | Copy constructor supported |
| `Cha` | Returned by API | N/A | Cannot be constructed directly |
| `File` | Returned by API | Use `file.url` | Cannot be constructed directly |
| `Icon` | Returned by API | Use `icon.text` | Cannot be constructed directly |
| `Error` | Returned by API | `tostring(err)` | Cannot be constructed directly |
| `Window` | `ya.window()` | N/A | Cannot be constructed directly |

**Sources:** [docs/plugins/types.md1-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/types.md#L1-L454)