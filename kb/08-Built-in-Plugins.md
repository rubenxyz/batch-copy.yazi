Relevant source files

-   [docs/dds.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md)
-   [docs/flavors/overview.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/flavors/overview.md)
-   [docs/plugins/builtins.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md)

This page documents Yazi's built-in plugins that are shipped with the core application. These plugins extend Yazi's functionality without requiring additional installation, covering file navigation, cross-instance communication, and common file operations.

For information about writing custom plugins, see [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins). For the plugin API reference, see [Plugin API Reference](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3-plugin-api-reference). For community-contributed plugins, see [Plugin Ecosystem](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.5-plugin-ecosystem).

___

## Overview

Built-in plugins are located in the `yazi-plugin/preset/plugins/` directory and are automatically available to all Yazi installations. Unlike external plugins, these are maintained as part of the core codebase and follow the same versioning and release cycle as Yazi itself.

**Location in codebase**: [yazi-plugin/preset/plugins/](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/)

**Available built-in plugins**:

-   `fzf.lua` - Fuzzy file finding
-   `zoxide.lua` - Smart directory navigation
-   `dds.lua` - DDS command bridge
-   `session.lua` - Cross-instance clipboard
-   `extract.lua` - Archive extraction

Sources: [docs/plugins/builtins.md1-60](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L1-L60) [docs/dds.md401-472](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L401-L472)

___

## Architecture

The following diagram shows how built-in plugins integrate with Yazi's core systems and the external tools they depend on:

**Plugin execution flow**: User action → Keymap lookup → Plugin invocation → External tool execution (if needed) → DDS event emission (if needed) → UI update

Sources: [docs/plugins/builtins.md1-60](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L1-L60) [docs/dds.md401-472](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L401-L472)

___

## File Navigation Plugins

### `fzf.lua` - Fuzzy File Finding

Integrates the `fzf` fuzzy finder into Yazi for rapid file and directory navigation within the current working directory or among selected files.

**Source code**: [yazi-plugin/preset/plugins/fzf.lua](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/fzf.lua)

#### Usage

**Default keybinding**: z

**Behavior modes**:

| Context | Action |
| --- | --- |
| Normal mode (no selection) | Search all files in CWD subtree |
| Selection mode | Search only among selected files |
| Single file selected | `reveal` file or `cd` if directory |
| Multiple files selected | Select/deselect the chosen files in Yazi |

#### Example

```python
# In Yazi, press 'z' to open fzf interface
# Type fuzzy pattern, e.g., "readme md" matches "README.md"
# Press Enter to navigate to selected file
# Press Ctrl-C to cancel
```

#### Requirements

-   `fzf` binary must be installed and available in `$PATH`
-   No additional configuration required for basic functionality

Sources: [docs/plugins/builtins.md10-32](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L10-L32)

___

### `zoxide.lua` - Smart Directory Navigation

Leverages `zoxide` to provide intelligent directory jumping based on frecency (frequency + recency) of visited directories.

**Source code**: [yazi-plugin/preset/plugins/zoxide.lua](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/zoxide.lua)

#### Usage

**Default keybinding**: Z (uppercase)

Launches an interactive `zoxide` interface powered by `fzf` to select from previously visited directories.

#### Configuration

Add to `~/.config/yazi/init.lua`:

```
require("zoxide"):setup {
update_db = true,  -- Add current directory to zoxide database on CWD change
}
```

**Available options**:

| Option | Type | Description |
| --- | --- | --- |
| `update_db` | boolean | Whether to automatically add paths to zoxide database when switching directories |

#### Requirements

1.  `zoxide` binary installed ([installation guide](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/installation%20guide))
2.  `fzf` binary installed (dependency of zoxide interactive mode)
3.  Zoxide configured for your shell (run `zoxide init <shell>` and add to shell config)

Sources: [docs/plugins/builtins.md33-60](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L33-L60)

___

## DDS Integration Plugins

The following diagram illustrates how DDS integration plugins bridge CLI commands and cross-instance communication:

Sources: [docs/dds.md404-441](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L404-L441)

___

### `dds.lua` - DDS Command Bridge

Bridges the `ya emit` CLI command into Yazi's pub-sub system, converting shell commands into internal DDS events.

**Source code**: [yazi-plugin/preset/plugins/dds.lua](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/dds.lua)

#### Purpose

The `ya emit` command provides a user-friendly way to trigger Yazi commands from the shell. This plugin implements the translation layer:

```
ya emit &lt;command&gt; &lt;args&gt;  →  ya pub dds-emit --json '{"cmd":"&lt;command&gt;","args":[...]}'
```

#### Usage Example

Synchronize Yazi's CWD with shell PWD when exiting a subshell:

**Zsh** (`~/.zshrc`):

```python
# Change Yazi's CWD to PWD on subshell exit
if [[ -n "$YAZI_ID" ]]; then
function _yazi_cd() {
ya emit cd "$PWD"
}
add-zsh-hook zshexit _yazi_cd
fi
```

**Fish** (`~/.config/fish/config.fish`):

```python
# Change Yazi's CWD to PWD on subshell exit
if [ -n "$YAZI_ID" ]
trap 'ya emit cd "$PWD"' EXIT
end
```

#### Event Kind

Subscribes to: `dds-emit`

**Message body structure**:

```
{
cmd = "cd",           -- Command name from keymap.toml
args = { "/tmp" }     -- Command arguments
}
```

Sources: [docs/dds.md404-442](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L404-L442)

___

### `session.lua` - Cross-Instance Clipboard

Enables yanking files in one Yazi instance and pasting them in another instance using DDS static messages for state persistence.

**Source code**: [yazi-plugin/preset/plugins/session.lua](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/session.lua)

#### Configuration

Add to `~/.config/yazi/init.lua`:

```
require("session"):setup {
sync_yanked = true,
}
```

**Important**: Restart **all** Yazi instances after configuration changes for cross-instance synchronization to work properly.

#### How It Works

1.  When files are yanked in instance A, `session.lua` publishes a static message with kind `@yank-persist`
2.  Static messages (kind starting with `@`) are persisted by DDS and restored when new instances start
3.  Instance B receives the persisted message on startup and can paste those files
4.  Yanked state is synchronized across all running instances in real-time via `sub_remote("yank")`

#### Limitations

-   Only works between Yazi instances running under the same user account
-   Requires DDS system to be functional (automatic in normal usage)
-   File paths must be accessible from all instances (shared filesystem)

Sources: [docs/dds.md444-456](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L444-L456)

___

## Utility Plugins

### `extract.lua` - Archive Extraction

Provides event-driven archive extraction using platform-appropriate extraction tools. Can be bound as an opener for archive files.

**Source code**: [yazi-plugin/preset/plugins/extract.lua](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/yazi-plugin/preset/plugins/extract.lua)

#### Configuration

Add to `~/.config/yazi/yazi.toml`:

```
[opener]
extract = [
{ run = 'ya pub extract --list "$@"', desc = "Extract here", for = "unix" },
{ run = 'ya pub extract --list %*',   desc = "Extract here", for = "windows" },
]
```

Then associate archive extensions with this opener:

```python
# In the same yazi.toml file
[open]
rules = [
{ mime = "application/{zip,gzip,x-tar,x-bzip*,x-7z-compressed,x-rar}", use = "extract" },
]
```

#### Usage

1.  Navigate to an archive file (`.zip`, `.tar.gz`, `.7z`, etc.)
2.  Press Enter to open the file
3.  Select "Extract here" from the opener menu
4.  Files are extracted to the current directory

#### Event Kind

Subscribes to: `extract`

**Message body structure**:

```lua
-- Array of file URLs to extract
{ "/root/archive1.zip", "/root/archive2.tar.gz" }
```

#### Supported Formats

The plugin automatically detects and uses available extraction tools:

| Format | Tools (in priority order) |
| --- | --- |
| `.zip` | `unar`, `7z`, `unzip` |
| `.tar`, `.tar.gz`, `.tgz` | `unar`, `7z`, `tar` |
| `.tar.bz2`, `.tbz2` | `unar`, `7z`, `tar` |
| `.tar.xz`, `.txz` | `unar`, `7z`, `tar` |
| `.7z` | `7z`, `unar` |
| `.rar` | `unar`, `7z` |

Sources: [docs/dds.md458-471](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L458-L471)

___

## Configuration Patterns

### Setup Method Pattern

Several built-in plugins follow a configuration pattern using a `setup()` method called from `init.lua`:

```lua
-- ~/.config/yazi/init.lua

-- Configure zoxide
require("zoxide"):setup {
update_db = true,
}

-- Configure session
require("session"):setup {
sync_yanked = true,
}
```

**Pattern characteristics**:

-   Optional configuration - plugins work with defaults if not configured
-   Table-based options for clarity
-   Setup must be called before Yazi finishes initialization
-   Changes require restarting Yazi to take effect

Sources: [docs/plugins/builtins.md53-59](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L53-L59) [docs/dds.md449-454](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L449-L454)

___

### DDS Event Pattern

Plugins that integrate with DDS use event subscription to respond to messages:

```lua
-- Plugin structure for DDS integration
return {
entry = function(self, args)
-- Subscribe to event kind
ps.sub("my-event-kind", function(body)
-- Handle the event
end)
end,
}
```

**Pattern characteristics**:

-   Plugins act as event handlers
-   Can use `ps.sub()` for local events or `ps.sub_remote()` for cross-instance events
-   Static messages (kind starting with `@`) persist across restarts
-   CLI integration via `ya pub <kind> --list/--json/--str`

Sources: [docs/dds.md23-28](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L23-L28) [docs/dds.md401-471](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L401-L471)

___

### External Tool Integration Pattern

Plugins that invoke external binaries use the `Command` API:

```lua
-- Example pattern for external tool integration
local child, err = Command("fzf")
:args({ "--preview", "..." })
:stdin(Command.PIPED)
:stdout(Command.PIPED)
:spawn()

if not child then
return ya.err("Failed to spawn fzf: " .. tostring(err))
end

-- Read output and process
local output, err = child:wait_with_output()
```

**Pattern characteristics**:

-   Defensive error handling (check if `child` is nil)
-   Pipe configuration for stdio communication
-   Asynchronous execution with `wait_with_output()`
-   User-friendly error messages via `ya.err()`

Sources: [docs/plugins/builtins.md10-60](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L10-L60)

___

## Dependency Matrix

The following table summarizes external dependencies for each built-in plugin:

| Plugin | Required Dependencies | Optional Dependencies | Platform Notes |
| --- | --- | --- | --- |
| `fzf.lua` | `fzf` binary | None | Cross-platform |
| `zoxide.lua` | `zoxide` binary, `fzf` binary, shell integration | None | Requires zoxide init in shell config |
| `dds.lua` | None | None | Built-in, no external deps |
| `session.lua` | None | None | Built-in, no external deps |
| `extract.lua` | At least one: `unar`, `7z`, `unzip`, `tar` | None | Tool selection automatic |

Sources: [docs/plugins/builtins.md40-46](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/plugins/builtins.md#L40-L46) [docs/dds.md401-471](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/dds.md#L401-L471)