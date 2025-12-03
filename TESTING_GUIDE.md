# Testing Guide for destination-copy.yazi

## Pre-flight Checklist

Before testing the plugin in Yazi, verify these items:

### ✅ File Structure
```bash
cd /path/to/destination_copy.yazi
ls -la main.lua
# Should see: main.lua (not init.lua)
```

### ✅ Syntax Check
```bash
luac -p main.lua
# Should output nothing (success) or "Syntax check passed"
```

### ✅ Plugin Installation
```bash
ls -la ~/.config/yazi/plugins/destination-copy.yazi/main.lua
# Should see the symlink or directory
```

### ✅ Trash Command
```bash
which trash
# Should output: /usr/local/bin/trash (or similar)
```

## Configuration Steps

### 1. Create Test Destinations
```bash
mkdir -p ~/test-yazi-dest1
mkdir -p ~/test-yazi-dest2
```

### 2. Configure Plugin
Edit `~/.config/yazi/init.lua` and add:

```lua
require("destination-copy"):setup {
  destinations = {
    { key = "1", name = "Test Dest 1", path = os.getenv("HOME") .. "/test-yazi-dest1" },
    { key = "2", name = "Test Dest 2", path = os.getenv("HOME") .. "/test-yazi-dest2" },
  }
}
```

### 3. Add Keybinding
Edit `~/.config/yazi/keymap.toml` and add:

```toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin destination-copy"
desc = "Move to destination"
```

## Testing Procedure

### Test 1: Basic Functionality
```bash
# 1. Create test files
mkdir -p ~/test-yazi-source
cd ~/test-yazi-source
touch file1.txt file2.txt file3.txt

# 2. Start Yazi with debug logging
YAZI_LOG=debug yazi ~/test-yazi-source

# 3. In Yazi:
#    - Press Space on file1.txt (select it)
#    - Press Space on file2.txt (select it)
#    - Press 's' (trigger plugin)
#    - Should see menu with destinations
#    - Press '1' (choose Test Dest 1)
#    - Type 'y' and press Enter
#    - Files should move to ~/test-yazi-dest1/

# 4. Verify
ls ~/test-yazi-dest1/
# Should show: file1.txt file2.txt
```

### Test 2: Trash Existing Files
```bash
# 1. Create files in destination
echo "old content" > ~/test-yazi-dest1/existing-file.txt

# 2. Create new source files
cd ~/test-yazi-source
touch new-file.txt

# 3. Start Yazi
yazi ~/test-yazi-source

# 4. In Yazi:
#    - Select new-file.txt
#    - Press 's' then '1'
#    - Type 'y'
#    - existing-file.txt should be in trash
#    - only new-file.txt should be in dest1

# 5. Verify trash
ls ~/.Trash/  # Should see existing-file.txt (macOS)
```

### Test 3: No Files Selected
```bash
# 1. Start Yazi
yazi ~/test-yazi-source

# 2. In Yazi:
#    - Don't select any files
#    - Press 's'
#    - Should see error: "No files selected"
```

### Test 4: Invalid Destination
```bash
# 1. Edit init.lua, add invalid path:
{ key = "9", name = "Invalid", path = "/nonexistent/path" }

# 2. Start Yazi
yazi ~/test-yazi-source

# 3. In Yazi:
#    - Select a file
#    - Press 's' then '9'
#    - Should see error: "Destination not found"
```

### Test 5: Cancel Operation
```bash
# 1. Start Yazi
yazi ~/test-yazi-source

# 2. In Yazi:
#    - Select files
#    - Press 's' then '1'
#    - Type 'n' (or just press Escape)
#    - Files should NOT move
```

## Debug Logs

Watch logs in real-time:
```bash
# Terminal 1: Run Yazi
YAZI_LOG=debug yazi

# Terminal 2: Watch logs
tail -f ~/.local/state/yazi/yazi.log | grep "destination-copy"
```

### Expected Log Entries
```
[DEBUG] destination-copy plugin started
[DEBUG] Moving 2 files to /Users/you/test-yazi-dest1
[DEBUG] Move completed
[DEBUG] Batch move completed
```

## Common Issues

### Issue: Plugin not loading
**Check:**
```bash
# 1. Plugin directory name correct?
ls ~/.config/yazi/plugins/ | grep destination-copy

# 2. main.lua exists?
ls ~/.config/yazi/plugins/destination-copy.yazi/main.lua

# 3. init.lua has setup()?
grep "destination-copy" ~/.config/yazi/init.lua
```

### Issue: "trash command not found"
**Fix:**
```bash
brew install trash
which trash  # Verify installation
```

### Issue: Files not moving
**Check logs for errors:**
```bash
tail -100 ~/.local/state/yazi/yazi.log | grep -i error
```

### Issue: Permission denied
**Fix:**
```bash
# Ensure destination directories are writable
chmod 755 ~/test-yazi-dest1
```

## Cleanup

After testing:
```bash
# Remove test directories
rm -rf ~/test-yazi-source
rm -rf ~/test-yazi-dest1
rm -rf ~/test-yazi-dest2

# Remove test configuration from init.lua
# Remove test keybinding from keymap.toml
```

## Success Criteria

✅ Plugin loads without errors
✅ Menu displays correctly with configured destinations
✅ Files move successfully to selected destination
✅ Existing files in destination are trashed
✅ Error messages display for invalid operations
✅ Cancel operation works correctly
✅ No errors in debug logs

## Report Issues

If you encounter problems:

1. **Check debug logs:**
   ```bash
   tail -100 ~/.local/state/yazi/yazi.log
   ```

2. **Check error reports:**
   ```bash
   ls -la /tmp/destination-copy-error_*.txt
   cat /tmp/destination-copy-error_*.txt  # If any exist
   ```

3. **Verify Yazi version:**
   ```bash
   yazi --version  # Should be 0.2.0 or higher
   ```

Good luck testing! 🚀
