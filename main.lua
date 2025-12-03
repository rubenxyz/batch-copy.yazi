-- destination-copy.yazi Plugin
-- Batch move files to preconfigured destinations with keyboard-driven menu (0-9, a-z)
-- Moves existing destination files to trash before transferring selected files

local M = {}

-- Sync function to get selected files from cx (must be at top level)
local get_selected = ya.sync(function()
	local files = {}
	for _, file in pairs(cx.active.selected) do
		table.insert(files, file)
	end
	return files
end)

local function get_config_path()
	return "~/.config/yazi/init.lua"
end

-- Check if trash command is available (required for safe file deletion)
local function check_trash_available()
	local output = Command("which"):arg("trash"):output()
	return output and output.status and output.status.success
end

-- Validate configuration structure
local function validate_configuration(destinations)
	if not destinations or type(destinations) ~= "table" or #destinations == 0 then
		return false, "No destinations configured"
	end

	local seen_keys = {}
	for i, dest in ipairs(destinations) do
		if not dest.key or not dest.name or not dest.path then
			return false, string.format("Destination %d missing key, name, or path", i)
		end
		if #dest.key ~= 1 then
			return false, string.format("Key must be single character: %s", dest.key)
		end
		if seen_keys[dest.key:lower()] then
			return false, string.format("Duplicate key: %s", dest.key)
		end
		seen_keys[dest.key:lower()] = true
	end
	return true, nil
end

-- Validate destination path exists
local function validate_destination_exists(path)
	local cha = fs.cha(Url(path))
	return cha and cha.is_dir
end

-- Build destination menu candidates for ya.which()
-- Returns both candidates and the sorted destinations list
local function build_destination_menu(destinations)
	local cands = {}
	local sorted = {}
	for _, dest in ipairs(destinations) do
		table.insert(sorted, dest)
	end

	-- Sort: 0-9 first, then a-z
	table.sort(sorted, function(a, b)
		local a_key, b_key = a.key:lower(), b.key:lower()
		local a_is_num, b_is_num = a_key:match("^%d$"), b_key:match("^%d$")
		if a_is_num and not b_is_num then return true
		elseif not a_is_num and b_is_num then return false
		else return a_key < b_key end
	end)

	for _, dest in ipairs(sorted) do
		table.insert(cands, { on = dest.key, desc = dest.name })
	end
	return cands, sorted
end

-- Get destination files for trashing
local function get_destination_files(dest_path)
	local files = {}
	local ok, items = pcall(fs.read_dir, Url(dest_path))
	if ok and items then
		for _, item in ipairs(items) do
			if not item.cha.is_dir then
				table.insert(files, tostring(item.url))
			end
		end
	end
	return files
end

-- Trash files using macOS trash command
local function trash_files(files)
	if #files == 0 then return true, nil end

	ya.dbg(string.format("Trashing %d files", #files))
	local child, err = Command("trash"):args(files):spawn()
	if not child then
		ya.err("Failed to spawn trash: " .. tostring(err))
		return false, "Failed to spawn trash command"
	end

	local status = child:wait()
	if not status or not status.success then
		ya.err("Trash command failed")
		return false, "Trash command failed"
	end

	ya.dbg("Trash completed")
	return true, nil
end

-- Move files to destination
local function move_files(files, dest_path)
	ya.dbg(string.format("Moving %d files to %s", #files, dest_path))

	for _, file in ipairs(files) do
		local source = tostring(file.url)
		local filename = file.url:name()
		local target = dest_path .. "/" .. filename

		local child = Command("mv"):args({source, target}):spawn()
		if not child then
			ya.err("Failed to move: " .. source)
			return false, "Failed to move " .. filename
		end

		local status = child:wait()
		if not status or not status.success then
			ya.err("Move failed: " .. source)
			return false, "Move failed for " .. filename
		end
	end

	ya.dbg("Move completed")
	return true, nil
end

-- Write error report to /tmp/
local function write_error_report(operation, error_msg, dest_path, files)
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local path = "/tmp/destination-copy-error_" .. timestamp .. ".txt"
	local content = string.format([[================================================================================
DESTINATION-COPY PLUGIN ERROR REPORT
================================================================================

Timestamp: %s
Plugin: destination-copy.yazi

OPERATION DETAILS
-----------------
Action: %s
Destination: %s
Selected Files: %d

ERROR INFORMATION
-----------------
Error Message: %s

FILES INVOLVED
--------------
]], os.date("%Y-%m-%d %H:%M:%S"), operation, dest_path or "N/A", #files, error_msg)

	for i, file in ipairs(files) do
		content = content .. string.format("%d. %s\n", i, tostring(file.url))
	end

	content = content .. [[

RECOVERY SUGGESTIONS
--------------------
1. Check trash command: which trash
2. Verify destination path exists
3. Check file permissions
4. Review Yazi log: ~/.local/state/yazi/yazi.log

================================================================================
]]

	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
		return path
	end
	return nil
end

-- Setup method for user configuration
function M.setup(state, opts)
	state.destinations = (opts and opts.destinations) or {}
end

-- Show error notification
local function notify_error(msg)
	ya.notify({ title = "Destination Copy Error", content = msg, level = "error", timeout = 5 })
end

-- Main entry method (runs in async context)
function M.entry(state, job)
	ya.dbg("destination-copy plugin started")

	-- Validate configuration
	if not state.destinations or #state.destinations == 0 then
		return notify_error("No destinations configured. Add to: " .. get_config_path())
	end
	local valid, config_err = validate_configuration(state.destinations)
	if not valid then
		return notify_error("Configuration error: " .. config_err)
	end
	if not check_trash_available() then
		return notify_error("trash command not found. Install: brew install trash")
	end

	-- Get selected files using sync block
	local selected = get_selected()
	if #selected == 0 then
		return notify_error("No files selected. Select with Space or visual mode (v)")
	end

	-- Show menu and get destination
	local cands, sorted = build_destination_menu(state.destinations)
	local choice = ya.which({ cands = cands, silent = false })
	if not choice then return end
	
	-- ya.which returns 1-based index, use it to get the destination from sorted list
	local dest = sorted[choice]
	if not dest then return notify_error("Invalid destination selection") end
	if not validate_destination_exists(dest.path) then
		return notify_error(string.format(
			"Destination not found: %s\nCreate directory or update config at: %s",
			dest.path, get_config_path()
		))
	end

	-- Confirm operation using ya.input since ya.confirm API signature is different
	local value, event = ya.input({
		title = string.format("Move %d file(s) to %s? (y/n)", #selected, dest.name),
		position = { "top-center", w = 50 }
	})
	
	if not value or (value:lower() ~= "y" and value:lower() ~= "yes") or event ~= 1 then
		return
	end

	ya.dbg("Starting batch move to: " .. dest.path)

	-- Trash existing files
	local dest_files = get_destination_files(dest.path)
	if #dest_files > 0 then
		local ok, err = trash_files(dest_files)
		if not ok then
			local report = write_error_report("Trash Files", err, dest.path, selected)
			ya.notify({
				title = "Destination Copy Error",
				content = "Failed to trash files. Report: " .. (report or "N/A"),
				level = "error", timeout = 7,
			})
			return
		end
	end

	-- Move files
	local ok, err = move_files(selected, dest.path)
	if not ok then
		local report = write_error_report("Move Files", err, dest.path, selected)
		ya.notify({
			title = "Destination Copy Error",
			content = "Failed to move files. Report: " .. (report or "N/A"),
			level = "error", timeout = 7,
		})
		return
	end

	ya.dbg("Batch move completed")
	ya.notify({
		title = "Destination Copy",
		content = string.format("Moved %d file(s) to %s", #selected, dest.name),
		level = "info", timeout = 3,
	})
end

return M
