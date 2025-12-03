# destination-copy.yazi

A [Yazi](https://yazi-rs.github.io/) plugin for rapid batch file operations using keyboard-driven destination selection.

Move multiple selected files to preconfigured destinations with just a few keystrokes. Perfect for workflows that require frequent file organization across multiple directories.

## Quick Start

```bash
# 1. Install
cd ~/.config/yazi/plugins
ln -s "/path/to/destination-copy.yazi" destination-copy.yazi

# 2. Configure (add to ~/.config/yazi/init.lua)
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Work", path = "~/Documents/Work" },
    { key = "2", name = "Personal", path = "~/Documents/Personal" },
  }
}

# 3. Add keybinding (add to ~/.config/yazi/keymap.toml)
[[manager.prepend_keymap]]
on = "s"
run = "plugin destination-copy"
desc = "Move to destination"

# 4. Install trash command
brew install trash
```

**Usage:** Select files → Press `s` → Choose destination → Type `y` → Done!

## Features

- **Keyboard-driven menu**: Choose from up to 36 destinations using 0-9 and a-z keys
- **Batch operations**: Move multiple files in a single operation
- **Safe file handling**: Automatically trashes existing destination files before moving
- **Fast workflow**: Two keystrokes (trigger + destination key) to move files
- **Visual feedback**: Clear notifications for success and errors

## Demo

```
Choose destination:
1 - Text-to-Image Input
2 - Upscaler Input  
3 - Video Generator
a - Archive 2024
b - Backup Drive
```

Select files → Press `s` → Press `1` → Type `y` → Done!

## Requirements

- **Yazi** 0.2.0 or higher
- **macOS** (uses `trash` command for safe deletion)
- **trash** command - Install with: `brew install trash`

## Installation

### 1. Install the Plugin

**Option A: Clone directly**
```bash
cd ~/.config/yazi/plugins
git clone https://github.com/yourusername/destination-copy.yazi.git
```

**Option B: Symlink (recommended for development)**
```bash
cd ~/.config/yazi/plugins
ln -s "/full/path/to/destination-copy.yazi" destination-copy.yazi
```

**Verify installation:**
```bash
ls ~/.config/yazi/plugins/destination-copy.yazi/main.lua
```
You should see the `main.lua` file if installed correctly.

### 2. Configure Destinations

Add to `~/.config/yazi/init.lua`:

```lua
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Text-to-Image Input", path = "/Users/you/AI/text2img" },
    { key = "2", name = "Upscaler Input", path = "/Users/you/AI/upscaler" },
    { key = "3", name = "Video Generator", path = "/Users/you/AI/video" },
    { key = "a", name = "Archive 2024", path = "/Users/you/Archive/2024" },
    { key = "b", name = "Backup Drive", path = "/Volumes/Backup/current" },
    -- Add up to 36 destinations (0-9, a-z)
  }
}
```

**Important:** 
- Use **absolute paths** for all destinations
- Paths with `~` will work (e.g., `~/Documents/Archive`)
- Destination directories must exist before use
- Each key must be unique (case-insensitive)

### 3. Add Key Binding

Add to `~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin destination-copy"
desc = "Batch move to configured destination"
```

Change `"s"` to any key you prefer.

## Usage

1. **Select files** in Yazi (press `Space` on files or use visual mode with `v`)
2. **Press trigger key** (`s` by default)
3. **Choose destination** by pressing the corresponding key (0-9 or a-z)
4. **Confirm** the operation by typing `y` (or `yes`) and pressing Enter
5. Files are moved to the destination

> **Note:** The plugin will automatically trash any existing files in the destination directory before moving your selected files.

## How It Works

When you select a destination:

1. **Validates** that files are selected and destination exists
2. **Trashes** any existing files at the destination (using macOS `trash` command)
3. **Moves** selected files to the destination
4. **Notifies** you of success or any errors

This ensures your destination directory only contains the files you just moved, with no manual cleanup needed.

## Configuration

Each destination requires three fields:

- `key`: Single character (0-9 or a-z) for quick selection
- `name`: Display name in the menu (recommended max 40 characters)
- `path`: Absolute path to destination directory

### Example Configurations

**For AI/ML Workflows:**
```lua
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Stable Diffusion Input", path = "~/AI/sd-input" },
    { key = "2", name = "ComfyUI Workspace", path = "~/AI/comfyui/input" },
    { key = "3", name = "Training Data", path = "~/AI/training/raw" },
  }
}
```

**For Media Organization:**
```lua
require("destination-copy"):setup {
  destinations = {
    { key = "p", name = "Photos 2024", path = "~/Pictures/2024" },
    { key = "v", name = "Videos Archive", path = "~/Videos/archive" },
    { key = "m", name = "Music Library", path = "~/Music/library" },
  }
}
```

## Error Handling

The plugin validates everything before moving files:

- ✅ Checks if `trash` command is available
- ✅ Checks if files are selected
- ✅ Checks if destination directories exist
- ✅ Handles user cancellation gracefully

If something goes wrong:
- **In-app notifications** show error messages
- **Error reports** are saved to `/tmp/destination-copy-error_*.txt`
- **Logs** are written to `~/.local/state/yazi/yazi.log`

## Troubleshooting

### "trash command not found"
Install the trash command:
```bash
brew install trash
```

### "No destinations configured"
Check that you've added the `require("destination-copy"):setup` block to `~/.config/yazi/init.lua`

**Example minimal configuration:**
```lua
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Destination 1", path = "/full/path/to/dest1" },
  }
}
```

### "Destination not found: [path]"
The configured destination directory doesn't exist. Either:
1. Create the directory: `mkdir -p /path/to/destination`
2. Update your configuration with the correct path

### Plugin not loading
1. Ensure the plugin directory is named `destination-copy.yazi`
2. Verify `main.lua` exists in the plugin directory
3. Check Yazi can find the plugin: `ls ~/.config/yazi/plugins/`

### View debug logs
Enable debug logging and watch the log file:
```bash
# Run Yazi with debug logging
YAZI_LOG=debug yazi

# In another terminal, watch the logs
tail -f ~/.local/state/yazi/yazi.log
```

Look for lines containing "destination-copy" to see plugin execution details.

## Why This Plugin?

I built this to streamline my AI image processing workflow. Instead of manually moving images between different AI tool directories, I can now:

1. Browse images in Yazi
2. Select the ones I want to process
3. Press `s` → `1` to send them to Stable Diffusion
4. Or `s` → `2` for the upscaler
5. Or `s` → `3` for video generation

This saves dozens of manual file moves every day.

## Design Philosophy

- **Minimal**: Single file plugin (`main.lua`)
- **Fast**: Keyboard-driven, no mouse needed
- **Safe**: Uses `trash` instead of permanent deletion
- **Simple**: No complex configuration, just paths and keys
- **Reliable**: Comprehensive validation and error reporting

## Technical Details

### Plugin Architecture
- **Execution Context**: Runs in async context for non-blocking operation
- **State Management**: Configuration stored in plugin state via `setup()` method
- **Sync Bridge**: Uses `ya.sync()` to access selected files from Yazi's context
- **API Compatibility**: Built for Yazi's plugin API v0.2.0+

### File Structure
```
destination-copy.yazi/
├── main.lua           # Plugin entry point (required by Yazi)
├── README.md          # Documentation
├── LICENSE            # MIT License
├── FIXED.md          # Repair notes and changelog
└── examples/
    └── config.lua     # Configuration examples
```

### How It Works Internally
1. Plugin loads and registers via `setup()` in `init.lua`
2. User triggers plugin via keymap binding
3. Plugin validates configuration and checks prerequisites
4. Uses `ya.sync()` to retrieve selected files from Yazi's sync context
5. Displays menu using `ya.which()` and gets user's destination choice
6. Confirms operation via `ya.input()` prompt
7. Trashes existing files in destination (if any)
8. Moves selected files to destination
9. Shows success/error notification

## Contributing

Suggestions and improvements are welcome! Open an issue or PR.

## License

MIT License - See LICENSE file for details

## Credits

Built for [Yazi](https://yazi-rs.github.io/), the blazing fast terminal file manager.

Special thanks to the Yazi community for their excellent documentation and plugin ecosystem.
