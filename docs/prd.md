# PRD - batch-copy.yazi Plugin

## 01. Project Definition

### 01.1 Project Description

A Yazi file manager plugin that enables rapid batch file operations by presenting a keyboard-driven destination menu (0-9, a-z) for moving selected files to preconfigured locations. The plugin moves existing destination files to trash before transferring the selected files, streamlining workflows that require frequent file organization across multiple predetermined directories.

### 01.2 Core Features

- **Keyboard-Driven Destination Selection**: Display hint menu with up to 36 destinations (0-9, a-z keys)
- **Batch File Move**: Move multiple selected files to chosen destination in single operation
- **Safe Destination Clearing**: Move existing destination files to macOS trash before file transfer
- **Configuration Management**: User-configurable destination paths via Yazi's standard config system
- **Validation and Safety**: Pre-flight checks for file selection, destination existence, and trash command availability
- **Contextual Help**: Display configuration file location in hint menu for easy setup reference
- **Fail-Fast Error Handling**: Validate all preconditions before executing destructive operations
- **Operation Reporting**: Success notifications via Yazi UI, detailed error reports on failure

### 01.3 Specific Requirements

**Functional Requirements**

- Plugin must be triggered by configurable key binding (default: `s`)
- At least one file must be selected in Yazi before plugin execution
- Destination paths must be configured before plugin can operate
- Existing files in destination directory must be moved to macOS trash (not permanently deleted)
- Selected files must be moved (not copied) from source to destination
- Configuration must support up to 36 destinations (keys 0-9, a-z)
- Plugin must display configuration file path in hint menu for user reference

**Technical Requirements**

- Plugin must use macOS `trash` command for safe file deletion
- Must validate trash command availability before operations
- Must validate destination paths exist before operations
- Must validate at least one file is selected before showing menu
- Must use appropriate Yazi context (sync/async) for each operation
- Must handle user cancellation gracefully (menu escape, confirmation decline)
- Error reports must be written to USER-FILES/07.TEMP/ for failed operations
- Success notifications must use ya.notify() for in-Yazi feedback

**Dependencies**

- External Command: `trash` (macOS trash utility)
- Yazi Version: 0.2.0 or higher (for modern plugin API)
- macOS Operating System (for trash command)

### 01.4 Project Context

**Option A: Personal Plugin (LLM-Operated)**

- **Users**: Just me (developer/owner)
- **Operation**: Claude Code or other LLM operates on my behalf
- **Documentation**: LLM-readable (clear comments in Lua)
- **Testing**: I test manually in Yazi - no automated tests, no test frameworks, no test suites
- **CI/CD**: Not needed (no team, no external deployment)
- **Simplification Impact**:
  - No user documentation needed
  - No automated testing whatsoever
  - No test files or test directories
  - No release management
  - No external integrations
  - Focus exclusively on building functional plugins

### 01.5 Error Handling Strategy

**Invalid Command Execution**
- Use ya.err() for logging command failures
- Use ya.notify() for user-facing error messages
- Write detailed error report to USER-FILES/07.TEMP/error_report_[timestamp].txt

**Missing Dependencies**
- Check for `trash` command availability at plugin start
- If not found, show error: "trash command not found. Install via: brew install trash"
- Provide installation instructions in error notification

**User Cancellation**
- Handle nil returns from ya.which() when user presses Escape
- Handle nil returns from ya.confirm() when user declines operation
- Exit gracefully without error messages on cancellation

**File Operation Failures**
- Validate all preconditions before any destructive operations (Fail Fast)
- If trash operation fails, abort entire operation and show error
- If move operation fails, show error with details
- Never leave destination in inconsistent state

**Configuration Errors**
- If no destinations configured, show error with config file path
- If destination path doesn't exist, show error: "Destination not found: [path]. Please create directory or update config at: [config_path]"
- If configuration file syntax error, log to ya.err() and show notification

**File Selection Errors**
- If no files selected, show error: "No files selected. Select files with Space or visual mode (v)"
- Do not proceed with menu display if selection validation fails

---

## 02. Minimalist Architecture Philosophy

### Core Principles

**Simplicity First**

- One purpose per plugin: Batch move files to preconfigured destinations
- Self-documenting variable names: `dest_path`, `selected_files`, `trash_cmd`
- Standard Lua patterns only: No metatable magic, no complex abstractions
- Functions under 50 lines each
- No premature abstractions: Build what's needed, nothing more
- Use Yazi's built-in APIs: ya.which(), ya.confirm(), ya.notify(), Command API

**Implementation Standards**

- Main plugin file: `init.lua` at project root
- Plugin directory name: `batch-copy.yazi`
- Use local variables for all non-exported functions
- Return table with `entry` method (functional plugin)
- Return table with `setup` method for configuration
- All helper functions are local and under 50 lines

### Lua Plugin Implementation Standards

**Code Structure**

- Single file implementation (init.lua) unless exceeds 200 lines
- Use setup() method for loading user configuration
- Configuration stored in USER-FILES/01.CONFIG/destinations.lua
- Local helper functions for: validation, trash operations, move operations
- Clear separation between validation and execution phases

**Error Handling**

- Use ya.err() for logging errors to Yazi log file
- Use ya.notify() for user-facing error messages (level = "error")
- Check return values from all Command operations
- Handle nil returns from ya.which() and ya.confirm() gracefully
- Fail fast: Validate everything before destructive operations

**Dependencies**

- Required external command: `trash` (macOS trash utility)
- Installation: `brew install trash`
- Check dependency availability at plugin initialization
- Provide clear installation instructions in error messages

**Plugin Operations**

- Use async context for main entry method (default)
- Use Command API for executing external commands (trash, mv)
- Use ya.which() for destination menu display
- Use ya.confirm() for user confirmation before operations
- Use ya.notify() for success/error feedback
- Handle user cancellation gracefully (return on nil)

**Testing & Documentation**

- Build functional plugin - I test manually in Yazi
- No automated tests, no test frameworks, no test files
- Clear inline comments for complex logic
- Test in Yazi to verify plugin works before committing
- Comments explain WHY, not WHAT

---

## 03. Plugin Structure

### Yazi Plugin Structure

#### Folder Structure

```plaintext
batch-copy.yazi/
├── init.lua               # Main plugin entry point (required)
└── USER-FILES/            # Plugin data and configuration
    ├── 00.KB/             # Knowledge base and documentation
    │   ├── idea_brief.md
    │   ├── PRD_Instructions_Template.md
    │   ├── prd.md         # This document
    │   ├── smart_copy_concept.md
    │   └── yazi_plugin.md
    ├── 01.CONFIG/         # Plugin configuration files
    │   └── destinations.lua  # User-configured destination paths
    ├── 02.STANDBY/        # Reserved for future use
    ├── 03.PROFILES/       # Not used by this plugin
    ├── 04.INPUT/          # Not used by this plugin (READ ONLY)
    ├── 05.OUTPUT/         # Not used by this plugin
    ├── 06.DONE/           # Not used by this plugin
    └── 07.TEMP/           # Error reports and operation logs
        └── error_report_YYYYMMDD_HHMMSS.txt
```

#### Plugin Entry Point

The `init.lua` file must return a table with `setup` and `entry` methods:

```lua
-- batch-copy.yazi/init.lua
local M = {}

-- Setup method for loading user configuration
function M.setup(state, opts)
  -- Load destinations from opts
  state.destinations = opts.destinations or {}
end

-- Entry method for plugin execution
function M.entry(state, job)
  -- Plugin logic here
  -- 1. Validate dependencies (trash command)
  -- 2. Validate file selection
  -- 3. Load destinations from config
  -- 4. Show destination menu
  -- 5. Get user confirmation
  -- 6. Validate preconditions (destination exists, trash available)
  -- 7. Move destination files to trash
  -- 8. Move selected files to destination
  -- 9. Show success notification
end

return M
```

---

## 04. Input/Output Pattern for Yazi Plugins

### 04.1 Purpose and Scope

This plugin follows Yazi's standard plugin patterns for configuration and operation. Users configure destination paths via Yazi's init.lua, and the plugin provides clear feedback through Yazi's UI notification system.

**Key principle**: User manages configuration; plugin validates and executes operations safely

### 04.2 Standard Folder Structure

```plaintext
batch-copy.yazi/
├── .gitignore                                        
├── init.lua                                           # Main plugin entry point
└── USER-FILES/
    ├── 00.KB/                                         # Knowledge base and reference materials
    │   ├── idea_brief.md                              # Original project idea
    │   ├── PRD_Instructions_Template.md               # PRD template structure
    │   ├── prd.md                                     # This document
    │   ├── smart_copy_concept.md                      # Detailed implementation concept
    │   └── yazi_plugin.md                             # Yazi plugin development guide
    ├── 01.CONFIG/                                     # Configuration files for plugin
    │   └── destinations.lua.example                   # Example destinations config
    ├── 02.STANDBY/                                    # Reserved for future use (ignored by plugin)
    ├── 03.PROFILES/                                   # Not used by this plugin
    ├── 04.INPUT/                                      # Not used by this plugin (READ ONLY)
    ├── 05.OUTPUT/                                     # Not used by this plugin
    ├── 06.DONE/                                       # Not used by this plugin
    └── 07.TEMP/                                       # Error reports and operation logs
        └── error_report_YYYYMMDD_HHMMSS.txt           # Generated on operation failure
```

### 04.3 Plugin Operation Flow

#### Typical Flow

```plaintext
[User Selects Files] → [Press 's'] → [Show Menu] → [Choose Dest] → [Confirm] → [Execute] → [Notify]
      ↓                      ↓             ↓             ↓             ↓            ↓           ↓
   Space/Visual         Key Binding   ya.which()    User Choice   ya.confirm()  Commands  ya.notify()
```

#### Detailed Operation Sequence

```plaintext
1. User selects files in Yazi (Space key or visual mode 'v')
2. User presses 's' key (or configured key binding)
3. Plugin validates:
   - At least one file is selected
   - Trash command is available
   - Destinations are configured
4. Plugin shows destination menu via ya.which()
   - Menu displays: "0-9, a-z: Destination Name | Config: [path]"
5. User selects destination by pressing key (0-9, a-z)
6. Plugin validates destination path exists
7. Plugin shows confirmation dialog via ya.confirm()
   - "Move existing files to trash and move N selected files to: [destination]?"
8. User confirms or cancels
9. If confirmed:
   a. Move existing destination files to trash
   b. Move selected files to destination
   c. Show success notification
10. If failed:
    a. Log error to ya.err()
    b. Write error report to USER-FILES/07.TEMP/
    c. Show error notification with details
```

### 04.4 Folder Descriptions

| Folder      | Purpose                          | Plugin Access |
| ----------- | -------------------------------- | ------------- |
| 00.KB       | Knowledge base, PRD, guides      | Read-only     |
| 01.CONFIG   | Destination paths configuration  | Read-only     |
| 02.STANDBY  | Reserved for future use          | Ignored       |
| 03.PROFILES | Not used by this plugin          | Ignored       |
| 04.INPUT    | Not used by this plugin          | Ignored       |
| 05.OUTPUT   | Not used by this plugin          | Ignored       |
| 06.DONE     | Not used by this plugin          | Ignored       |
| 07.TEMP     | Error reports, operation logs    | Write-only    |

### 04.5 User Workflow

#### Installation and Configuration

1. **Install Plugin**: Place `batch-copy.yazi/` in `~/.config/yazi/plugins/`
2. **Configure Destinations**: Add to `~/.config/yazi/init.lua`:
   ```lua
   require("batch-copy"):setup {
     destinations = {
       { key = "1", name = "Text-to-Image Input", path = "/Users/ruben/path/to/dest1" },
       { key = "2", name = "Upscaler Input", path = "/Users/ruben/path/to/dest2" },
       { key = "a", name = "Archive", path = "/Users/ruben/path/to/archive" },
       -- Add up to 36 destinations (0-9, a-z)
     }
   }
   ```
3. **Configure Keymap**: Add to `~/.config/yazi/keymap.toml`:
   ```toml
   [[manager.prepend_keymap]]
   on = "s"
   run = "plugin batch-copy"
   ```
4. **Install Dependencies**: Install trash command:
   ```bash
   brew install trash
   ```

#### Daily Usage Workflow

1. Navigate to source directory in Yazi
2. Select files to move (Space key or visual mode 'v')
3. Press 's' key
4. Select destination from menu (press 0-9 or a-z)
5. Confirm operation in dialog
6. Files are moved, success notification appears
7. If error occurs, check USER-FILES/07.TEMP/error_report_*.txt

### 04.6 Configuration Example

#### Example destinations.lua Structure

```lua
-- This is configured in ~/.config/yazi/init.lua
-- Example configuration:

require("batch-copy"):setup {
  destinations = {
    -- Number keys 0-9
    { key = "1", name = "Text-to-Image Input", path = "/Users/ruben/genai/text-to-image/INPUT" },
    { key = "2", name = "Upscaler Input", path = "/Users/ruben/genai/upscaler/INPUT" },
    { key = "3", name = "Video Input", path = "/Users/ruben/genai/video/INPUT" },
    
    -- Letter keys a-z
    { key = "a", name = "Archive 2024", path = "/Users/ruben/archive/2024" },
    { key = "b", name = "Backup Drive", path = "/Volumes/Backup/current" },
    { key = "c", name = "Cloud Sync", path = "/Users/ruben/Nextcloud/sync" },
    
    -- More destinations as needed (up to 36 total)
  }
}
```

### 04.7 Configuration Management

| Directory   | Format         | Purpose                         |
| ----------- | -------------- | ------------------------------- |
| 01.CONFIG   | Lua (examples) | Example configuration files     |
| Yazi init   | Lua            | Actual user configuration       |
| 00.KB       | Markdown       | Reference docs, PRD             |

### 04.8 Output Organization

- **Success**: ya.notify() shows "Moved N files to [destination]"
- **Error**: Write detailed report to USER-FILES/07.TEMP/error_report_[timestamp].txt
- **Logging**: Use ya.dbg() for debug logs (moderate level - significant events)
- **User Notifications**: Use ya.notify() with appropriate level (info, error)

### 04.9 Key Principles

#### Data Organization

- User configures destinations in Yazi's standard init.lua
- Plugin validates configuration on setup
- Clear separation between configuration and operation

#### Operation Safety

- Fail-fast validation: Check everything before destructive operations
- Use macOS trash command (not rm -rf) for existing files
- Require explicit user confirmation before operations
- Handle user cancellation gracefully
- Never leave destination in inconsistent state

#### Configuration Separation

- Plugin configuration (destinations) in Yazi's init.lua
- Reference materials in USER-FILES/00.KB/
- Error reports in USER-FILES/07.TEMP/
- Clear distinction between temporary and permanent files

### 04.10 Implementation Details

#### Logging Strategy

**Plugin Logs**

- **ya.dbg()** - Moderate logging: significant events only
  - Plugin initialization
  - Destination selection
  - Operation start/completion
  - Command execution (trash, move)
- **ya.err()** - Error messages logged to Yazi log file
  - Dependency check failures
  - File operation failures
  - Configuration errors
- **ya.notify()** - User-facing notifications in Yazi UI
  - Success: "Moved N files to [destination]"
  - Errors: Clear, actionable error messages

**Log Location**

- Unix-like: `~/.local/state/yazi/yazi.log`
- Enable with: `YAZI_LOG=debug yazi`

**Error Reports**

- Written to: USER-FILES/07.TEMP/error_report_[YYYYMMDD_HHMMSS].txt
- Contains:
  - Timestamp
  - Operation attempted
  - Files involved
  - Error message
  - Stack trace (if available)
  - System information

#### File Operations

**Safe Operations**

- Always confirm destructive actions with ya.confirm()
- Use trash command for existing destination files
- Validate all paths before operations
- Check command success before proceeding

**External Commands**

- Use Command API for all external commands
- Commands used:
  - `trash [files...]` - Move files to trash
  - Standard Lua/Yazi APIs for file moves

**Command Execution Pattern**

```lua
-- Check if trash command exists
local trash_check = Command("which"):arg("trash"):output()
if not trash_check or trash_check.status.code ~= 0 then
  -- Error: trash not available
end

-- Execute trash command
local child, err = Command("trash"):args(files_to_trash):spawn()
if not child then
  -- Error: failed to spawn
end

local status = child:wait()
if not status or not status.success then
  -- Error: trash command failed
end
```

#### Error Handling and Recovery

**Graceful Degradation**

- If trash not available, show error with installation instructions
- If destination doesn't exist, show error with creation instructions
- If no files selected, show error with selection instructions

**Clear Error Reporting**

- Use ya.err() for logs: `ya.err("Failed to trash files: " .. error_msg)`
- Use ya.notify() for users: `ya.notify({ title = "Error", content = msg, level = "error" })`
- Write detailed report to USER-FILES/07.TEMP/

**Recovery Options**

- User can check trash bin to recover files if needed
- Error report provides details for troubleshooting
- No automatic retry mechanisms (fail-fast philosophy)

**User Experience**

- Don't block UI with long operations (use async context)
- Show progress feedback for large operations (if needed)
- Clear, actionable error messages

#### Plugin Modes

- **Functional Plugin**: Triggered by key binding, performs action (entry method)
- **Configuration**: Uses setup() method for user configuration
- **Async Context**: Uses async context for I/O operations (default)

#### Technical Implementation

**Plugin Flow**: 
1. User Action (select files + press key)
2. Validation (files selected, trash available, config exists)
3. Menu Display (ya.which with destinations)
4. User Selection (0-9, a-z)
5. Confirmation (ya.confirm with details)
6. Execution (trash existing files, move selected files)
7. Notification (success or error)

**File Formats**: 
- CONFIG: Lua (in Yazi's init.lua)
- KB: Markdown
- Temp: Text (error reports)

**Logging**: 
- ya.dbg() for moderate logging (significant events)
- ya.err() for errors
- ya.notify() for user messages

**Error Handling**: 
- Check all return values
- Handle nil gracefully
- Fail fast (validate before execute)

**Context**: 
- Async (default) for I/O operations

### 04.11 Version Control Guidelines

#### Directory Exclusion

**Git Ignore Rules**

```gitignore
# User-specific configuration
USER-FILES/01.CONFIG/destinations.lua

# Temporary files and error reports
USER-FILES/07.TEMP/*
!USER-FILES/07.TEMP/.gitkeep

# macOS system files
.DS_Store

# Editor files
*.swp
*.swo
*~
```

#### Rationale for Exclusion

1. **Repository Size Management**: Error reports and logs shouldn't be in version control
2. **Data Privacy**: User destination paths may contain sensitive information
3. **Plugin Code Focus**: Version control focuses on plugin logic, not user data
4. **User-Specific Data**: Configuration is personal to each user

**Data Management**

- **Never commit user config** from USER-FILES/01.CONFIG/destinations.lua
- **Never commit error reports** from USER-FILES/07.TEMP/
- **Provide example config** as destinations.lua.example
- **Use .gitkeep files** in empty USER-FILES directories to preserve structure
- **Document directory structure** in comments within init.lua

**Project Structure**

- **Maintain folder structure** even when empty
- **Use .gitkeep files** in empty directories:
  - USER-FILES/01.CONFIG/.gitkeep
  - USER-FILES/07.TEMP/.gitkeep
- **Include destinations.lua.example** with sample configuration
- **Document setup** in inline comments

**Folder Preservation**: Use .gitkeep files in empty directories

#### Security Considerations

**Sensitive Data**

- **Never commit user paths** or personal information
- **Use placeholders** in example configuration
- **Document required configuration** without exposing user data
- **Provide config templates** (e.g., destinations.lua.example)

**Data Privacy**

- **Review files** before committing
- **Use synthetic data** for examples
- **Anonymize paths** in documentation
- **Document requirements** without exposing user data

**Installation and Usage**

- **Install**: Place plugin directory in `~/.config/yazi/plugins/`
- **Configure**: Add setup call in `~/.config/yazi/init.lua`
- **Keymap**: Add binding in `~/.config/yazi/keymap.toml`
- **Dependencies**: Install trash via `brew install trash`
- **Test**: Test in Yazi with YAZI_LOG=debug before committing

---

## 05. Detailed Technical Specification

### 05.1 Plugin Interface

**Entry Method Signature**

```lua
function M.entry(state, job)
  -- state: Plugin state (contains loaded configuration)
  -- job: Job parameter (contains args from keymap)
end
```

**Setup Method Signature**

```lua
function M.setup(state, opts)
  -- state: Plugin state storage
  -- opts: User configuration from init.lua
end
```

### 05.2 Configuration Schema

**Destination Object Structure**

```lua
{
  key = "1",           -- Single character: 0-9 or a-z
  name = "Dest Name",  -- Display name in menu
  path = "/full/path"  -- Absolute path to destination
}
```

**Configuration Validation Rules**

- Each destination must have unique key (0-9, a-z)
- Key must be single character, case-insensitive
- Path must be absolute (starts with /)
- Name should be descriptive (max 40 chars for menu display)
- Maximum 36 destinations (0-9 = 10, a-z = 26)

### 05.3 Menu Display Format

**Hint Menu Structure**

```plaintext
╭─────────────────────────────────────────╮
│ Select Destination:                     │
│                                         │
│ 1 → Text-to-Image Input                 │
│ 2 → Upscaler Input                      │
│ 3 → Video Input                         │
│ a → Archive 2024                        │
│ b → Backup Drive                        │
│                                         │
│ Config: ~/.config/yazi/init.lua         │
╰─────────────────────────────────────────╯
```

### 05.4 Confirmation Dialog Format

**Confirmation Message Structure**

```plaintext
╭─────────────────────────────────────────╮
│ Confirm Batch Move                      │
│                                         │
│ Move 5 selected files to:               │
│ /Users/ruben/genai/text-to-image/INPUT  │
│                                         │
│ Existing files in destination will be   │
│ moved to Trash.                         │
│                                         │
│ Continue?                               │
│                                         │
│ [Yes]  [No]                             │
╰─────────────────────────────────────────╯
```

### 05.5 Validation Sequence

**Pre-Operation Validation Checklist**

1. **Dependency Check**: Verify trash command exists
2. **Selection Check**: Verify at least one file selected
3. **Configuration Check**: Verify destinations configured
4. **Destination Check**: Verify selected destination path exists
5. **Permission Check**: Verify write permissions to destination
6. **Trash Check**: Verify trash command is executable

**Validation Failure Responses**

| Check Failed | Error Message | Action |
|-------------|---------------|--------|
| No trash | "trash command not found. Install: brew install trash" | Exit |
| No selection | "No files selected. Select with Space or visual mode (v)" | Exit |
| No config | "No destinations configured. Add to: ~/.config/yazi/init.lua" | Exit |
| Dest missing | "Destination not found: [path]. Create directory or update config." | Exit |
| No permission | "Cannot write to: [path]. Check permissions." | Exit |

### 05.6 Error Report Format

**Error Report Template**

```plaintext
================================================================================
BATCH-COPY PLUGIN ERROR REPORT
================================================================================

Timestamp: 2024-11-26 14:32:15
Plugin Version: 1.0.0
Yazi Version: [detected]

OPERATION DETAILS
-----------------
Action: Batch Move
Destination: /Users/ruben/genai/text-to-image/INPUT
Selected Files: 5

ERROR INFORMATION
-----------------
Error Type: Command Execution Failure
Error Message: trash command failed with exit code 1
Command: trash [file list]

FILES INVOLVED
--------------
1. /Users/ruben/source/image1.png
2. /Users/ruben/source/image2.png
3. /Users/ruben/source/image3.png
4. /Users/ruben/source/image4.png
5. /Users/ruben/source/image5.png

SYSTEM INFORMATION
------------------
OS: macOS 14.0
Trash Available: Yes
Destination Exists: Yes
Write Permission: Yes

RECOVERY SUGGESTIONS
--------------------
1. Check trash command: which trash
2. Verify destination path exists
3. Check file permissions
4. Review Yazi log: ~/.local/state/yazi/yazi.log

================================================================================
```

### 05.7 Success Notification Format

**Simple Success Message**

```plaintext
Moved 5 files to Text-to-Image Input
```

### 05.8 Command API Implementation

**Recommended Approach: Command API**

Based on Yazi plugin best practices and modern API capabilities, the Command API is recommended over shell emit for:

- Better error handling and return value checking
- More control over command execution
- Cleaner separation of concerns
- Easier debugging and logging

**Trash Command Execution**

```lua
local function trash_files(files)
  local child, err = Command("trash"):args(files):spawn()
  if not child then
    ya.err("Failed to spawn trash command: " .. tostring(err))
    return false, err
  end
  
  local status = child:wait()
  if not status or not status.success then
    ya.err("Trash command failed")
    return false, "Trash command failed"
  end
  
  return true, nil
end
```

**File Move Execution**

```lua
local function move_files(files, destination)
  for _, file in ipairs(files) do
    local source = tostring(file.url)
    local target = destination .. "/" .. file.name
    
    local child, err = Command("mv"):args({source, target}):spawn()
    if not child then
      ya.err("Failed to move file: " .. source)
      return false, err
    end
    
    local status = child:wait()
    if not status or not status.success then
      ya.err("Move failed for: " .. source)
      return false, "Move command failed"
    end
  end
  
  return true, nil
end
```

### 05.9 File Size Management

**Target: Single File Implementation**

- Estimated line count: 150-200 lines
- Keep in single init.lua file (aligns with Yazi plugin philosophy)
- Split only if exceeds 200 lines soft limit
- Prioritize readability over strict line count

**File Structure Organization**

```lua
-- Configuration state
-- Helper functions (validation, trash, move)
-- Setup method
-- Entry method
-- Return module table
```

---

## 06. Implementation Plan

### 06.1 Development Phases

**Phase 1: Core Setup (Estimated: 50 lines)**
- Module structure and state management
- Setup method for configuration loading
- Configuration validation

**Phase 2: Validation Logic (Estimated: 40 lines)**
- Trash command availability check
- File selection validation
- Destination existence validation

**Phase 3: Menu and Confirmation (Estimated: 30 lines)**
- Build destination menu from config
- Display menu via ya.which()
- Display confirmation dialog via ya.confirm()

**Phase 4: File Operations (Estimated: 50 lines)**
- Trash existing destination files
- Move selected files to destination
- Error handling for each operation

**Phase 5: Notifications and Reporting (Estimated: 30 lines)**
- Success notification
- Error report generation
- Logging implementation

**Total Estimated: ~200 lines (single file)**

### 06.2 Testing Checklist

**Manual Testing Scenarios**

- [ ] Plugin loads without errors
- [ ] Configuration loads from init.lua
- [ ] Trash command check works
- [ ] No files selected → shows error
- [ ] Menu displays all configured destinations
- [ ] Menu shows config file path
- [ ] User can cancel menu (Esc key)
- [ ] User can cancel confirmation dialog
- [ ] Destination validation works
- [ ] Existing files moved to trash successfully
- [ ] Selected files moved to destination successfully
- [ ] Success notification appears
- [ ] Error report generated on failure
- [ ] Multiple destinations work (test 0-9, a-z)
- [ ] Large file sets work (10+ files)
- [ ] Paths with spaces handled correctly

**Edge Cases to Test**

- [ ] Empty destination directory (no files to trash)
- [ ] Destination directory doesn't exist
- [ ] No write permission to destination
- [ ] Trash command not installed
- [ ] Configuration has invalid paths
- [ ] Configuration has duplicate keys
- [ ] Files already exist in destination
- [ ] Very long destination paths/names

### 06.3 Documentation Requirements

**Inline Comments Required For**

- Why trash command is required (safety)
- Why fail-fast validation is used
- Complex validation logic
- Command execution patterns

**No External Documentation Needed**

- No README.md (personal plugin)
- No user guides (I know how it works)
- Code should be self-documenting

---

## 07. Future Considerations

### 07.1 Potential Enhancements (DO NOT IMPLEMENT)

These are ideas for potential future improvements. Do not implement without explicit request.

- Copy mode option (in addition to move)
- Undo last operation
- Operation history log
- Batch operations from multiple sources
- Destination path autocomplete
- Visual progress for large operations
- Customizable confirmation messages
- Multi-destination move (distribute files)

### 07.2 Known Limitations

- macOS only (trash command dependency)
- Maximum 36 destinations (keyboard limit)
- No operation progress for large file sets
- No automatic destination creation
- No rollback on partial failures

---

## 08. Success Criteria

### 08.1 Functional Success

- [ ] Plugin triggers on configured key binding
- [ ] Displays menu with all configured destinations
- [ ] Moves existing destination files to trash
- [ ] Moves selected files to chosen destination
- [ ] Shows success notification
- [ ] Generates error report on failure
- [ ] Handles all validation scenarios correctly
- [ ] Handles user cancellation gracefully

### 08.2 Code Quality Success

- [ ] Single file under 200 lines
- [ ] All functions under 50 lines
- [ ] Clear, self-documenting variable names
- [ ] Proper error handling throughout
- [ ] Moderate logging (significant events)
- [ ] No clever code - straightforward logic
- [ ] Follows Yazi plugin patterns

### 08.3 User Experience Success

- [ ] Fast response time (<1 second for menu)
- [ ] Clear error messages with actionable instructions
- [ ] Intuitive key bindings (0-9, a-z)
- [ ] Config file path shown in menu
- [ ] Confirmation shows operation details
- [ ] Success notification is brief and clear

---

## 09. Appendix

### 09.1 Configuration Example

**Full Configuration in ~/.config/yazi/init.lua**

```lua
require("batch-copy"):setup {
  destinations = {
    -- AI/ML Workflows
    { key = "1", name = "Text-to-Image Input", path = "/Users/ruben/08_-_DEVELOPMENT/GENAI_IMAGE_TOOLS/text-to-image_tool/USER-FILES/04. INPUT" },
    { key = "2", name = "Upscaler Input", path = "/Users/ruben/08_-_DEVELOPMENT/GENAI_IMAGE_TOOLS/upscaler_tool/USER-FILES/04. INPUT" },
    { key = "3", name = "Video Generator Input", path = "/Users/ruben/08_-_DEVELOPMENT/GENAI_VIDEO_TOOLS/video_tool/USER-FILES/04. INPUT" },
    
    -- Archive Destinations
    { key = "a", name = "Archive 2024", path = "/Users/ruben/Archive/2024" },
    { key = "b", name = "Archive 2023", path = "/Users/ruben/Archive/2023" },
    
    -- Backup Destinations
    { key = "c", name = "Cloud Sync", path = "/Users/ruben/Nextcloud/sync" },
    { key = "d", name = "External Backup", path = "/Volumes/Backup/current" },
    
    -- Project Destinations
    { key = "p", name = "Current Project Assets", path = "/Users/ruben/Projects/current/assets" },
    { key = "w", name = "Work In Progress", path = "/Users/ruben/WIP" },
  }
}
```

### 09.2 Keymap Configuration Example

**Keymap in ~/.config/yazi/keymap.toml**

```toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin batch-copy"
desc = "Batch move to configured destination"
```

**Alternative Keymap (if 's' conflicts)**

```toml
[[manager.prepend_keymap]]
on = [ "b", "c" ]
run = "plugin batch-copy"
desc = "Batch move to configured destination"
```

### 09.3 Dependencies Installation

**macOS Installation**

```bash
# Install trash command via Homebrew
brew install trash

# Verify installation
which trash
# Should output: /opt/homebrew/bin/trash (or similar)

# Test trash command
trash --help
```

### 09.4 Troubleshooting Guide

**Plugin doesn't appear in menu**

- Check plugin directory is in `~/.config/yazi/plugins/`
- Verify directory name is `batch-copy.yazi`
- Verify `init.lua` exists in plugin directory
- Restart Yazi

**"No destinations configured" error**

- Check `~/.config/yazi/init.lua` contains setup call
- Verify destinations table syntax is correct
- Check for Lua syntax errors in init.lua
- Restart Yazi after config changes

**"trash command not found" error**

- Install trash: `brew install trash`
- Verify installation: `which trash`
- Check PATH includes Homebrew bin directory

**"Destination not found" error**

- Verify destination path exists: `ls [path]`
- Create directory if needed: `mkdir -p [path]`
- Update configuration if path changed
- Check for typos in configuration

**Operations fail silently**

- Enable debug logging: `YAZI_LOG=debug yazi`
- Check log file: `~/.local/state/yazi/yazi.log`
- Check error reports: `USER-FILES/07.TEMP/error_report_*.txt`

---

**END OF PRD**

*This PRD defines the complete specification for the batch-copy.yazi plugin. Implementation should follow this specification while adhering to the Code Manifesto principles of simplicity, minimalism, and fail-fast error handling.*
