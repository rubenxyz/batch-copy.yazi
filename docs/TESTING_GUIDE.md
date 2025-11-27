# Testing Guide for batch-copy.yazi Plugin

## Setup Instructions

### 1. Install Plugin

Create a symlink in Yazi's plugins directory:

```bash
cd ~/.config/yazi/plugins
ln -s "/Users/ruben/Nextcloud/08_-_DEVELOPMENT/MISC_TOOLS/destination_copy.yazi" batch-copy.yazi
```

### 2. Configure Plugin

Add to `~/.config/yazi/init.lua`:

```lua
require("batch-copy"):setup {
	destinations = {
		{ key = "1", name = "Test Destination 1", path = "/tmp/batch-copy-test/dest1" },
		{ key = "2", name = "Test Destination 2", path = "/tmp/batch-copy-test/dest2" },
		{ key = "a", name = "Test Archive", path = "/tmp/batch-copy-test/archive" },
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

### 4. Create Test Directories

```bash
mkdir -p /tmp/batch-copy-test/{source,dest1,dest2,archive}
cd /tmp/batch-copy-test/source
touch test1.txt test2.txt test3.txt
```

## Testing Checklist

### Basic Functionality

- [ ] Launch Yazi with debug logging: `YAZI_LOG=debug yazi`
- [ ] Navigate to `/tmp/batch-copy-test/source`
- [ ] Select test files with Space key
- [ ] Press 's' to trigger plugin
- [ ] Verify menu appears with all destinations
- [ ] Select destination '1'
- [ ] Confirm operation
- [ ] Verify files moved to `/tmp/batch-copy-test/dest1`
- [ ] Verify files removed from source
- [ ] Check success notification appears

### Error Handling

- [ ] Trigger plugin without selecting files → Should show error
- [ ] Configure invalid destination path → Should show error on selection
- [ ] Test with trash command temporarily unavailable

### Edge Cases

- [ ] Test with files containing spaces in names
- [ ] Test canceling menu (Escape key)
- [ ] Test declining confirmation dialog
- [ ] Test with empty destination (no files to trash)
- [ ] Test with existing files in destination (verify trash works)

## Viewing Logs

Check Yazi log file:
```bash
tail -f ~/.local/state/yazi/yazi.log
```

Check error reports:
```bash
ls -la /tmp/batch-copy-error_*.txt
```

## Cleanup After Testing

```bash
rm -rf /tmp/batch-copy-test
```
