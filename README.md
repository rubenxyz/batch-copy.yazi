# batch-copy.yazi

A [Yazi](https://yazi-rs.github.io/) plugin for rapid batch file operations using keyboard-driven destination selection.

Move multiple selected files to preconfigured destinations with just two keystrokes. Perfect for workflows that require frequent file organization across multiple directories.

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

Select files → Press `s` → Press `1` → Confirm → Done!

## Requirements

- **macOS** (uses `trash` command for safe deletion)
- **Yazi** 0.2.0 or higher
- **trash** command (`brew install trash`)

## Installation

### 1. Install the Plugin

```bash
cd ~/.config/yazi/plugins
git clone https://github.com/yourusername/batch-copy.yazi.git
```

Or using symlink for development:

```bash
cd ~/.config/yazi/plugins
ln -s "/path/to/batch-copy.yazi" batch-copy.yazi
```

### 2. Configure Destinations

Add to `~/.config/yazi/init.lua`:

```lua
require("batch-copy"):setup {
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

### 3. Add Key Binding

Add to `~/.config/yazi/keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin batch-copy"
desc = "Batch move to configured destination"
```

Change `"s"` to any key you prefer.

## Usage

1. **Select files** in Yazi (press `Space` on files or use visual mode with `v`)
2. **Press trigger key** (`s` by default)
3. **Choose destination** by pressing the corresponding key (0-9 or a-z)
4. **Confirm** the operation
5. Files are moved to the destination

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
require("batch-copy"):setup {
  destinations = {
    { key = "1", name = "Stable Diffusion Input", path = "~/AI/sd-input" },
    { key = "2", name = "ComfyUI Workspace", path = "~/AI/comfyui/input" },
    { key = "3", name = "Training Data", path = "~/AI/training/raw" },
  }
}
```

**For Media Organization:**
```lua
require("batch-copy"):setup {
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
- **Error reports** are saved to `/tmp/batch-copy-error_*.txt`
- **Logs** are written to `~/.local/state/yazi/yazi.log`

## Troubleshooting

### "trash command not found"
```bash
brew install trash
```

### "No destinations configured"
Check that you've added the `require("batch-copy"):setup` block to `~/.config/yazi/init.lua`

### "Destination not found: [path]"
The configured destination directory doesn't exist. Create it or update your configuration.

### View debug logs
```bash
YAZI_LOG=debug yazi
tail -f ~/.local/state/yazi/yazi.log
```

## Why This Plugin?

I built this to streamline my AI image processing workflow. Instead of manually moving images between different AI tool directories, I can now:

1. Browse images in Yazi
2. Select the ones I want to process
3. Press `s` → `1` to send them to Stable Diffusion
4. Or `s` → `2` for the upscaler
5. Or `s` → `3` for video generation

This saves dozens of manual file moves every day.

## Design Philosophy

- **Minimal**: One file, 273 lines, 12 functions
- **Fast**: Keyboard-driven, no mouse needed
- **Safe**: Uses `trash` instead of permanent deletion
- **Simple**: No complex configuration, just paths and keys

## Contributing

This is a personal plugin, but suggestions and improvements are welcome! Open an issue or PR.

## License

MIT License - See LICENSE file for details

## Credits

Built for [Yazi](https://yazi-rs.github.io/), the blazing fast terminal file manager
