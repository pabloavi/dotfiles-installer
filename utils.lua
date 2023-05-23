local M = {}

local colorp = require("color").print_color
local json = require("json")
local get_name = require("file").get_name
local get_path = require("file").get_path

---Reads a json file and returns a table
---@param file any
---@return table
M.read_json = function(file)
	local f = io.open(file, "rb")
	if not f then
		colorp("red", "ERROR: " .. file .. " does not exist")
		os.exit(1)
	end
	if f then
		local content = f:read("*all")
		f:close()
		return json.decode(content)
	end
	return { nil }
end

---Executes a command and returns the output
---@param cmd string
---@return string|nil
M.execute = function(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end
	local result = handle:read("*a")
	handle:close()
	return result
end

---Returns true if a file exists
---@param file string
---@return boolean
M.exists = function(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

---Returns the distro
---@return string
M.distro = function()
	local distro = tostring(M.execute("cat /etc/os-release | grep '^ID=' | cut -d '=' -f2"))
	distro = string.gsub(distro, "\n", "")
	return distro
end

---Returns path given without //, / at the end, and ~ replaced by $HOME
---@param str string
---@return string
M.valid_path = function(str)
	local home = os.getenv("HOME")
	if type(home) ~= "string" then
		home = ""
	end
	str = string.gsub(str, "//", "/")
	str = string.gsub(str, "/$", "")
	str = string.gsub(str, "^~", home)
	return str
end

---Returns files and directories in a given directory (recursively)
---@param path string
---@return table|nil files with full path to each file
M.get_files = function(path)
	local files = {}
	local p = io.popen("find " .. path .. " -type f")
	if not p then
		return nil
	end
	for file in p:lines() do
		table.insert(files, file)
	end
	return files
end

---Returns properties of a file
---@param file string
---@return table
M.get_file_info = function(file, dotfiles_dir, backup_dir)
	--- Define properties
	local file_name = M.valid_path(string.match(file, "/([^/]+)$"))
	local file_path_to_dots = M.valid_path(string.match(file, dotfiles_dir .. "(.*)"))
	local home_file = M.valid_path(os.getenv("HOME") .. "/" .. file_path_to_dots)
	local home_dir = M.valid_path(string.match(home_file, "(.+)/[^/]+$"))
	local backup_file = M.valid_path(os.getenv("HOME") .. backup_dir .. "/" .. file_path_to_dots)
	local backup_path = M.valid_path(string.match(backup_file, "(.+)/[^/]+$"))
  ---

  -- stylua: ignore
	return { -- example file: /home/user/dotfiles/.config/nvim/init.lua
		name = file_name,                 -- init.lua
		path_to_dots = file_path_to_dots, -- /.config/nvim/init.lua
		home_file = home_file,                 -- /home/user/.config/nvim/init.lua
		home_path = home_dir,             -- /home/user/.config/nvim
		backup_file = backup_file,             -- /tmp/dotfiles-dir/.config/nvim/init.lua
		backup_path = backup_path,        -- /tmp/dotfiles-dir/.config/nvim
	}
end

---Returns directories in a given directory removing the ignored directories and/or files
-- if starts with /, it means the path is relative to the home directory, so only that file is ignored (not its matching files)
-- if ends with /, it's a directory, so all files in that directory are ignored
---@param dots_dir string full path to the dotfiles directory
---@param files table
---@param ignored table
---@return table files with full path to each file
M.remove_ignored = function(dots_dir, files, ignored)
	if not ignored then
		ignored = {}
	end

	-- to improve readability, ignored can be a table of tables
	-- now we flatten it
	local new_ignored = {}
	for _, ignore in ipairs(ignored) do
		if type(ignore) == "table" then
			for _, i in ipairs(ignore) do
				table.insert(new_ignored, i)
			end
		else
			table.insert(new_ignored, ignore)
		end
	end

	local absolute_ignored = {} -- table of full paths to be ignored
	local relative_ignored = {} -- table of paths that, if matched, will be ignored

	for _, ignore in ipairs(new_ignored) do
		if string.match(ignore, "^/") then
			local file = dots_dir .. ignore
			table.insert(absolute_ignored, file)
		else
			table.insert(relative_ignored, ignore)
		end
	end

	local new_files = {}

	for _, file in ipairs(files) do
		local file_name = get_name(file)
		local file_path = get_path(file)
		local is_ignored = false

		-- check if file is in the absolute ignored list
		for _, ignore in ipairs(absolute_ignored) do
			if file == ignore then
				if verbose then
					colorp("Ignoring " .. file .. " (absolute)", "light_blue")
				end

				is_ignored = true
			end

			-- if file contains full path of ignore, remove it
			if string.match(ignore, "/$") then
				if string.match(file, ignore) then
					if verbose then
						colorp("Ignoring " .. file .. " (absolute, directory)", "light_blue")
					end
					is_ignored = true
				end
			end
		end

		-- check if file is in the relative ignored list
		for _, ignore in ipairs(relative_ignored) do
			if file_name == ignore then
				if verbose then
					colorp("Ignoring " .. file .. " (relative)", "light_green")
				end
				is_ignored = true
			end

			-- if file contains full path of ignore, remove it
			if string.match(ignore, "/$") then
				if string.match(file_path, ignore) then
					if verbose then
						colorp("Ignoring " .. file .. " (relative, directory)", "light_green")
					end
					is_ignored = true
				end
			end
		end

		if not is_ignored then
			table.insert(new_files, file)
		end
	end

	return new_files
end

return M
