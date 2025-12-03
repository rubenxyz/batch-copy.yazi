-- destination-copy.yazi Configuration Example
-- Copy this configuration to your ~/.config/yazi/init.lua

require("destination-copy"):setup {
  destinations = {
    -- Number keys 0-9 for quick access
    { key = "1", name = "Text-to-Image Input", path = "/Users/username/path/to/destination1" },
    { key = "2", name = "Upscaler Input", path = "/Users/username/path/to/destination2" },
    { key = "3", name = "Video Generator", path = "/Users/username/path/to/destination3" },
    
    -- Letter keys a-z for additional destinations
    { key = "a", name = "Archive 2024", path = "/Users/username/Archive/2024" },
    { key = "b", name = "Backup Drive", path = "/Volumes/Backup/current" },
    { key = "c", name = "Cloud Sync", path = "/Users/username/Nextcloud/sync" },
    
    -- Add up to 36 destinations total (0-9, a-z)
    -- Each destination requires:
    --   key  = single character (0-9 or a-z)
    --   name = display name in menu (max 40 chars recommended)
    --   path = absolute path to destination directory
  }
}

-- Add key binding to ~/.config/yazi/keymap.toml:
-- [[manager.prepend_keymap]]
-- on = "s"
-- run = "plugin destination-copy"
-- desc = "Batch move to configured destination"
