Relevant source files

-   [docs/resources.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md)
-   [docs/tips.md](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md)

This page provides a curated catalog of community-developed plugins for Yazi, organized by plugin type and functionality. It serves as a directory for discovering and selecting plugins to extend Yazi's capabilities beyond the built-in features.

For information about how to write your own plugins, see [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins). For details about the plugin API and available functions, see [Plugin API Reference](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.3-plugin-api-reference). For documentation of built-in plugins that ship with Yazi, see [Built-in Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.4-built-in-plugins).

:::warning The plugin system is actively evolving. Most plugins listed here target the latest development version of Yazi (`HEAD`). Ensure both Yazi and plugins are updated to compatible versions for proper functionality. :::

## Plugin Categories Overview

The Yazi plugin ecosystem is organized into seven primary categories based on plugin type and integration point:

**Sources:** [docs/resources.md1-200](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L1-L200)

## Plugin Installation and Management

All plugins follow the `.yazi` directory naming convention and are installed in the user's config directory at `~/.config/yazi/plugins/`. Plugins are loaded by referencing them in keybindings or configuration files.

### Installation Pattern

```
~/.config/yazi/
├── init.lua                      # Plugin setup calls
├── keymap.toml                   # Plugin keybindings
└── plugins/
    ├── plugin-name.yazi/
    │   └── main.lua              # Plugin entry point
    └── another-plugin.yazi/
        └── main.lua
```

### Activation Methods

| Activation Type | Configuration Location | Example |
| --- | --- | --- |
| Keybinding trigger | `keymap.toml` | `run = "plugin chmod"` |
| Setup initialization | `init.lua` | `require("folder-rules"):setup()` |
| Previewer/preloader rule | `yazi.toml` | `[[plugin.prepend_previewers]]` |
| Fetcher rule | `yazi.toml` | `[[plugin.fetchers]]` |

**Sources:** [docs/resources.md196-198](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L196-L198) [docs/tips.md13-14](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L13-L14)

## Previewers

Previewers extend Yazi's file preview capabilities beyond the built-in support for images, videos, PDFs, and code files. They implement the previewer interface to render custom file formats.

### General-Purpose Previewers

| Plugin | External Dependencies | Purpose |
| --- | --- | --- |
| `piper.yazi` | User-specified commands | Pipe any shell command output as preview content |
| `mux.yazi` | None | Define and cycle through multiple previewers for the same file type |

**Sources:** [docs/resources.md16-19](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L16-L19)

### Media File Previewers

| Plugin | Dependencies | Supported Formats | Key Features |
| --- | --- | --- | --- |
| `exifaudio.yazi` | `exiftool` | Audio files | Metadata extraction, album cover display |
| `mediainfo.yazi` | `ffmpeg`, `mediainfo` | Image, audio, video, subtitle | Comprehensive media information |

**Sources:** [docs/resources.md21-24](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L21-L24)

### Archive Previewers

| Plugin | Dependencies | Formats | Additional Features |
| --- | --- | --- | --- |
| `ouch.yazi` | `ouch` | Multiple archive formats | Preview and compression |
| `zless-preview.yazi` | `zless` | Compressed text files | Text content extraction |
| `comicthumb.yazi` | `p7zip` (Linux only) | Comic book archives | Thumbnail extraction |

**Sources:** [docs/resources.md26-30](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L26-L30)

### Document Previewers

| Plugin | Dependencies | Format | Notes |
| --- | --- | --- | --- |
| `djvu-view.yazi` | `ddjvu` from `djvulibre` | DjVu | Document image rendering |
| `nbpreview.yazi` | `nbpreview` | Jupyter notebooks (\*.ipynb) | Interactive notebook rendering |

**Sources:** [docs/resources.md32-46](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L32-L46)

### Data File Previewers

| Plugin | Dependencies | Formats | View Modes |
| --- | --- | --- | --- |
| `duckdb.yazi` | `duckdb` | CSV, TSV, JSON, Parquet | Raw data, statistical summary |
| `rich-preview.yazi` | `rich-cli` | Markdown, JSON, CSV, etc. | Styled console output |

**Sources:** [docs/resources.md36-50](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L36-L50)

### Specialized Previewers

| Plugin | Dependencies | Format | Use Case |
| --- | --- | --- | --- |
| `torrent-preview.yazi` | `transmission-cli` | \*.torrent | BitTorrent file metadata |

**Sources:** [docs/resources.md40-42](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L40-L42)

## Functional Plugins

Functional plugins extend Yazi's interactive capabilities through user-triggered actions. They are typically bound to keybindings in `keymap.toml`.

### Navigation and Jumping

| Plugin | External Dependencies | Navigation Method | Description |
| --- | --- | --- | --- |
| `relative-motions.yazi` | None | Vim motions | Relative line jumping (j/k with counts) |
| `jump-to-char.yazi` | None | Character search | Jump to next file starting with `<char>` |
| `time-travel.yazi` | BTRFS or ZFS | Snapshot browsing | Navigate filesystem snapshots |
| `cdhist.yazi` | `cdhist` | History fuzzy select | Search and navigate directory history |
| `cd-git-root.yazi` | `git` | Repository root | Change to git repository root |
| `fazif.yazi` | `fd`, `rg`/`rga`, `fzf` | Fuzzy search | Search with fd/rg and spawn FZF |

**Sources:** [docs/resources.md54-61](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L54-L61)

### Bookmarks and Location Management

| Plugin | Platform | Storage | Key Features |
| --- | --- | --- | --- |
| `bookmarks.yazi` | Cross-platform | Session only | Vi-like mark system |
| `mactag.yazi` | macOS only | macOS tags | Native Finder tag integration |
| `simple-tag.yazi` | Cross-platform | Custom | File/folder tagging |
| `yamb.yazi` | Cross-platform | Persistent | Key jumping, fzf integration |
| `bunny.yazi` | Cross-platform | Both | Persistent/ephemeral, previous directory, cross-tab |
| `whoosh.yazi` | Cross-platform | Both | Advanced features, path truncation, fzf |

**Sources:** [docs/resources.md63-70](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L63-L70)

### Tab Management

| Plugin | Functionality |
| --- | --- |
| `projects.yazi` | Save all tabs and their states as a project; restore projects |
| `close-and-restore-tab.yazi` | Restore previously closed tabs |

**Sources:** [docs/resources.md72-75](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L72-L75)

### File Operations

The largest category of functional plugins, providing diverse file manipulation capabilities:

#### Permission and Privilege Management

| Plugin | Dependencies | Purpose |
| --- | --- | --- |
| `chmod.yazi` | None | Change file mode for selected files |
| `sudo.yazi` | `sudo` | Execute file operations with elevated privileges |

#### Comparison and Analysis

| Plugin | Dependencies | Purpose |
| --- | --- | --- |
| `diff.yazi` | None | Diff selected file with hovered file, create patch |
| `what-size.yazi` | None | Calculate total size of selection or CWD |

#### Compression and Archives

| Plugin | Dependencies | Supported Operations |
| --- | --- | --- |
| `compress.yazi` | Archive utilities | Compress selected files to archive |
| `ouch.yazi` | `ouch` | Preview and compress multiple formats |
| `archivemount.yazi` | `archivemount` | Mount/unmount archives as directories |

#### File Linking and Transfer

| Plugin | Dependencies | Purpose |
| --- | --- | --- |
| `reflink.yazi` | Filesystem support | Create copy-on-write reflinks |
| `rsync.yazi` | `rsync` | Copy files locally or to remote servers |
| `sshfs.yazi` | `sshfs` | Mount remote directories over SSH |
| `kdeconnect-send.yazi` | `kdeconnect` | Send files to smartphone/devices |

#### Remote Filesystem Access

| Plugin | Dependencies | Supported Protocols |
| --- | --- | --- |
| `gvfs.yazi` | `gvfs` | MTP, GPhoto2, SMB, SFTP, NFS, FTP, Google Drive, WebDAV, AFP, AFC |

#### Recovery and Trash Management

| Plugin | Dependencies | Features |
| --- | --- | --- |
| `restore.yazi` | `trash-cli` | Restore latest deleted files/folders |
| `recycle-bin.yazi` | `trash-cli` | Browse trash, restore items, empty by age |

#### Version Control Integration

| Plugin | Dependencies | Purpose |
| --- | --- | --- |
| `lazygit.yazi` | `lazygit` | Manage Git directories with keybinding |

#### Preview Enhancements

| Plugin | Purpose |
| --- | --- |
| `zoom.yazi` | Zoom in/out of preview images |

**Sources:** [docs/resources.md77-94](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L77-L94)

### Clipboard Integration

| Plugin | Platform | Dependencies | Purpose |
| --- | --- | --- | --- |
| `clipboard.yazi` | Cross-platform | Platform-specific clipboard tools | Yank selected files to system clipboard |
| `copy-file-contents.yazi` | Cross-platform | None | Copy file contents without opening editor |
| `system-clipboard.yazi` | Cross-platform | Platform-specific clipboard tools | Simple system clipboard implementation |
| `wl-clipboard.yazi` | Linux (Wayland) | `wl-clipboard` | Wayland clipboard integration |
| `path-from-root.yazi` | Cross-platform | `git` | Copy file path relative to git root |
| `clippy.yazi` | macOS | None | Copy files using macOS Clippy |

**Sources:** [docs/resources.md96-103](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L96-L103)

### Command Enhancements

Plugins that enhance specific built-in Yazi commands:

#### Filter Enhancements

| Plugin | Features |
| --- | --- |
| `smart-filter.yazi` | Continuous filtering, auto-enter unique directories, open files on submit |

#### Enter Enhancements

| Plugin | Behavior |
| --- | --- |
| `smart-enter.yazi` | Open files or enter directories with single key |
| `bypass.yazi` | Skip directories with only single subdirectory |
| `fast-enter.yazi` | Auto-decompress archives or enter deepest directory |

#### Shell Enhancements

| Plugin | Purpose |
| --- | --- |
| `open-with-cmd.yazi` | Open files with prompted command |

#### Search Enhancements

| Plugin | Dependencies | Scope |
| --- | --- | --- |
| `vcs-files.yazi` | `git` | Git file changes |
| `git-files.yazi` | `git` | Git changes including untracked (via `git status --porcelain`) |
| `modif.yazi` | None | Recently modified files |

#### Paste Enhancements

| Plugin | Behavior |
| --- | --- |
| `smart-paste.yazi` | Paste into hovered directory or CWD if hovering file |

#### General Command Enhancements

| Plugin | Purpose |
| --- | --- |
| `augment-command.yazi` | Better handling of selected items vs. hovered item choice |

**Sources:** [docs/resources.md105-131](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L105-L131)

### UI Enhancements

| Plugin | Modified Component | Purpose |
| --- | --- | --- |
| `full-border.yazi` | Border system | Add full borders around Yazi |
| `toggle-pane.yazi` | Panes | Show/hide/maximize parent, current, preview panes |
| `git.yazi` | Linemode | Display Git file status in file list |
| `mount.yazi` | Manager | Disk mount/unmount/eject functionality |
| `starship.yazi` | Header | Starship prompt integration |
| `omp.yazi` | Header | oh-my-posh prompt integration |
| `yatline.yazi` | Header & Status | Customizable header-line and status-line |
| `simple-status.yazi` | Status bar | Minimalistic status with file attributes |
| `no-status.yazi` | Status bar | Remove status bar completely |
| `pref-by-location.yazi` | Settings | Save/restore linemode/sorting/hidden per directory |

**Sources:** [docs/resources.md133-144](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L133-L144)

## Preloaders

Preloaders run in the background to cache file content before preview is requested, improving preview responsiveness.

| Plugin | Dependencies | Purpose |
| --- | --- | --- |
| `allmytoes.yazi` | `allmytoes` | Generate freedesktop-compatible thumbnails |

**Sources:** [docs/resources.md146-150](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L146-L150)

## Fetchers

Fetchers provide alternative methods for retrieving file metadata, particularly MIME types.

| Plugin | Method | Trade-off |
| --- | --- | --- |
| `mime-ext.yazi` | Extension-based database | Faster but less accurate than content-based `file(1)` |

**Sources:** [docs/resources.md152-156](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L152-L156)

## Development Tools

| Plugin | Purpose |
| --- | --- |
| `types.yazi` | TypeScript-like type definitions for Yazi's Lua API, enabling autocomplete and type checking in IDEs |

**Sources:** [docs/resources.md158-160](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L158-L160)

## Editor Integrations

### Neovim Plugins

| Plugin | Maintainer | Key Features |
| --- | --- | --- |
| `yazi.nvim` | mikavilpas | Full Yazi integration with file picker and browser functionality |
| `tfm.nvim` | Rolv-Apneseth | Terminal file manager integration for multiple file managers |
| `fm-nvim` | Eric-Song-Nop | Generic terminal file manager support |

**Sources:** [docs/resources.md162-168](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L162-L168)

### Vim Plugins

| Plugin | Purpose |
| --- | --- |
| `vim-yazi` | Vim integration for seamless in-editor file browsing and navigation |
| `yazi.vim` | Alternative Vim plugin for Yazi integration |

**Sources:** [docs/resources.md170-173](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L170-L173)

### Helix Integration

| Integration | Description |
| --- | --- |
| Yazelix | File tree for Helix with helix-friendly keybindings for Zellij |

**Sources:** [docs/resources.md175-177](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L175-L177)

## Shell Plugins

| Plugin | Purpose |
| --- | --- |
| `yazi-prompt.sh` | Display indicator in shell prompt when running inside Yazi subshell |
| `custom-shell.yazi` | Run commands through default system shell |
| `command.yazi` | Display prompt for executing Yazi commands |

**Sources:** [docs/resources.md179-183](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L179-L183)

## Utilities

Development and configuration utilities:

| Utility | Purpose |
| --- | --- |
| `icons-brew.yazi` | Generate `theme.toml` for Yazi icons with custom color palette |
| `lsColorsToToml` | Convert `$LS_COLORS` to `[filetype]` section in `theme.toml` |

**Sources:** [docs/resources.md185-188](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L185-L188)

## Contributing Plugins

To add a plugin to this ecosystem page, plugins must meet the following requirements:

### Functional Requirements

1.  **Working Implementation**: Plugin must be functional and tested
2.  **Platform Documentation**: README must note platform-specific limitations
3.  **Naming Convention**: Directory/repository must end with `.yazi`
4.  **Required Files**: Must include files documented in [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture)

### Naming Conventions

| Integration Type | Recommended Suffix | Example |
| --- | --- | --- |
| Yazi plugin | `.yazi` | `bookmark.yazi` |
| Neovim plugin | `.nvim` or `.yazi` | `yazi.nvim` |
| Shell plugin | `.sh` or `.yazi` | `yazi-prompt.sh` |

**Sources:** [docs/resources.md190-199](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L190-L199)

## Plugin Architecture Reference

All plugins share common structural patterns:

```
plugin-name.yazi/
├── main.lua              # Entry point with entry() or setup() function
├── README.md             # Documentation
└── [optional files]      # Additional modules or resources
```

### Common Entry Points

| Function | Annotation | Purpose |
| --- | --- | --- |
| `entry(self, job)` | `@sync` or none | Main plugin execution, called on keybinding |
| `setup()` | None | Plugin initialization, called from `init.lua` |
| `peek(self, job)` | None | Previewer content generation |
| `preload(self, job)` | None | Background content preloading |
| `fetch(self, job)` | None | Metadata retrieval |

For detailed implementation guidance, see [Plugin Architecture](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.1-plugin-architecture) and [Writing Plugins](https://deepwiki.com/yazi-rs/yazi-rs.github.io/4.2-writing-plugins).

**Sources:** [docs/resources.md196-198](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/resources.md#L196-L198) [docs/tips.md13-14](https://github.com/yazi-rs/yazi-rs.github.io/blob/581b94c2/docs/tips.md#L13-L14)