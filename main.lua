pcall(require, "luarocks.loader")
local utils = require("utils")
local colorp = require("color").print_color

local config, dotfiles_dir, backup_dir, distro, yes
local home = os.getenv("HOME")

local default_opts = {
	yes = "",
	force = false,
	verbose = true,
	dry_run = false,
	backup = true,
	config = "config.json",
	dotfiles_dir = home .. "/.dotfiles",
	backup_dir = "/tmp/dotfiles-backup",
	distro = "fedora",
	ignored = {
		{
			"/.git/",
			"/README.md",
			"/LICENSE",
			"/.gitignore",
			"/.gitmodules",
		},
		"install.lua",
		"uninstall.lua",
	},
}

config = utils.read_json(config or default_opts["config"])

for _, arg in ipairs(arg) do
	-- check for argument -h, --help or no known argument
	if arg == "-h" or arg == "--help" or not string.match(arg, "--") then
		print("Usage: install.lua [options]")
		print("Options:")
		print("  -h, --help           print this help")
		print("  -v, --verbose        print everything")
		print("  -y, --yes            assume yes to all prompts")
		print("  -f, --force          force install of dotfiles")
		print("  -d, --dry-run        don't actually do anything")
		print("  -nb, --no-backup     don't backup files")
		print("  --config=FILE        use FILE as config file")
		print("  --dotfiles-dir=DIR   use DIR as dotfiles directory")
		print("  --backup-dir=DIR     use DIR as backup directory")
		print("  --distro=NAME        use NAME as distro")
		print("  --ignore-options     ignore options in config file")
		os.exit(0)
	end

	if arg ~= "-i" or arg ~= "--ignore-options" then
		if config["options"] then
			for k, v in pairs(config["options"]) do
				default_opts[k] = v
			end
		end
	end

	if arg == "-v" or arg == "--verbose" then
		verbose = true
	end

	if arg == "-nb" or arg == "--no-backup" then
		backup = false
	end

	if string.match(arg, "--config=") then
		config = string.match(arg, "--config=(.+)")
	end

	if string.match(arg, "--dotfiles-dir=") then
		dotfiles_dir = string.match(arg, "--dotfiles-dir=(.+)")
	end

	if string.match(arg, "--backup-dir=") then
		backup_dir = string.match(arg, "--backup-dir=(.+)")
	end

	if string.match(arg, "--distro=") then
		distro = string.match(arg, "--distro=(.+)")
	end

	if arg == "-y" or arg == "--yes" then
		yes = " -y "
	end

	if arg == "-f" or arg == "--force" then
		force = true
	end

	if arg == "-d" or arg == "--dry-run" then
		dry_run = true
	end
end

yes = yes or default_opts["yes"]
force = force or default_opts["force"]
verbose = verbose or default_opts["verbose"]
backup = backup or default_opts["backup"]
dry_run = dry_run or default_opts["dry_run"]

dotfiles_dir = dotfiles_dir or config["dotfiles_dir"] or default_opts["dotfiles_dir"]
backup_dir = backup_dir or config["backup_dir"] or default_opts["backup_dir"]

-- Clone the dotfiles repo
local url = config["dotfiles_repo"]
local dotfiles_name = string.match(url, "/([^/]+)%.git$")

-- TODO: add --only-symlink and --no-clone
if true then
	print("Cloning " .. dotfiles_name .. "...")
	if force then
		utils.execute("rm -rf " .. dotfiles_dir)
	end
	if not utils.exists(dotfiles_dir) then
		utils.execute("git clone " .. config["dotfiles_repo"] .. " " .. dotfiles_dir)
	else
		colorp("ERROR: " .. "Already cloned\n", "red")
	end

	-- Install dependencies
	distro = distro or config["distro"] or utils.distro()

	if verbose then
		print("Detected distro: " .. distro)
	end

	if distro == "arch" then
		-- install yay if not installed
		if os.execute("pacman -Q yay") ~= 0 then
			utils.execute("git clone https://aur.archlinux.org/yay.git")
			os.execute("cd yay && makepkg -si")
		end

		-- update package managers
		os.execute("sudo pacman -Su" .. yes) -- TODO: check if -y works
		os.execute("yay -Su" .. yes)

		-- install pacman packages
		local pacman_packages = table.concat(config["arch"]["pacman"], " ")
		os.execute("sudo pacman -S " .. yes .. pacman_packages)

		if verbose then
			print("Installed pacman packages: " .. pacman_packages)
		end

		-- install aur packages
		local aur_packages = table.concat(config["arch"]["aur"], " ")
		os.execute("yay -S " .. yes .. aur_packages)

		if verbose then
			print("Installed aur packages: " .. aur_packages)
		end
	elseif distro == "fedora" then
		-- update package managers
		if verbose then
			colorp("Updating dnf...", "green")
		end

		os.execute("sudo dnf upgrade")

		-- add copr repos
		if verbose then
			colorp("Adding copr repos...", "green")
		end

		local copr_repos = table.concat(config["fedora"]["copr"], " ")
		os.execute("sudo dnf copr enable " .. yes .. copr_repos)

		if verbose then
			print("Added copr repos: " .. copr_repos)
		end

		-- install dnf packages
		if verbose then
			colorp("Installing dnf packages...", "green")
		end

		local dnf_packages = table.concat(config["fedora"]["dnf"], " ")
		os.execute("sudo dnf install " .. yes .. dnf_packages)

		if verbose then
			print("Installed dnf packages: " .. dnf_packages)
		end
	else
		colorp("ERROR: " .. "Unsupported distro\n", "red")
		os.exit(1)
	end

	-- install pip3 packages
	if verbose then
		colorp("Installing pip3 packages...", "green")
	end

	local pip3_packages = table.concat(config["pip3"], " ")
	os.execute("pip3 install " .. pip3_packages)

	if verbose then
		print("Installed pip3 packages: " .. pip3_packages)
	end

	-- install nodejs packages
	if verbose then
		colorp("Installing nodejs packages...", "green")
	end

	local nodejs_packages = table.concat(config["nodejs"], " ")
	os.execute("npm install -g " .. nodejs_packages)

	if verbose then
		print("Installed nodejs packages: " .. nodejs_packages)
	end

	-- install software
	if verbose then
		colorp("Installing software...", "green")
	end

	local software_commands = config["software_commands"]
	for _, command in pairs(software_commands) do
		utils.execute(command)
	end

	if verbose then
		print("Executed:" .. table.concat(software_commands, "\n"))
	end
end

-- Get the files to symlink
local ignored = config["ignored"] or default_opts["ignored"]

local files = utils.get_files(dotfiles_dir) -- full paths
if not files then
	colorp("ERROR: " .. "No files found\n", "red")
	os.exit(1)
end
files = utils.remove_ignored(dotfiles_dir, files, ignored)
for _, k in pairs(files) do
	print(k)
end

-- create the backup directory
if backup then
	if not utils.exists(backup_dir) then
		utils.execute("mkdir -p " .. backup_dir)

		if verbose then
			print("Created backup directory: " .. backup_dir)
		end
	end
end

-- loop through the files and symlink them
for _, file in ipairs(files) do
	local file_info = utils.get_file_info(file, dotfiles_dir, backup_dir)

	if verbose then
		print("file_name: " .. file_info.name)
		print("file_path_to_dots: " .. file_info.path_to_dots)
		print("home_file: " .. file_info.home_file)
		print("home_dir: " .. file_info.home_path)
		print("backup_file: " .. file_info.backup_file)
		print("backup_path: " .. file_info.backup_path)
	end

	-- create the backup directory
	if not utils.exists(file_info.backup_path) then
		utils.execute("mkdir -p " .. file_info.backup_path)

		if verbose then
			print("Created " .. file_info.backup_path)
		end
	end

	-- create the home directory
	if not utils.exists(file_info.home_path) then
		utils.execute("mkdir -p " .. file_info.home_path)

		if verbose then
			print("Created " .. file_info.home_path)
		end
	end

	-- backup the file
	if backup then
		if utils.exists(file_info.home_file) then
			utils.execute("cp " .. file_info.home_file .. " " .. file_info.backup_file)

			if verbose then
				print("Backed up " .. file_info.name .. " to " .. file_info.backup_file)
			end
		end
	end

	-- symlink the file
	if not dry_run then
		utils.execute("ln -sf " .. file .. " " .. file_info.home_file)
	end

	if verbose then
		print("Symlinked " .. file .. " to " .. file_info.home_file)
		print("Command: " .. "ln -sf " .. file .. " " .. file_info.home_file)
	end
end

-- zip backup
if backup then
	utils.execute("zip -r " .. backup_dir .. ".zip " .. backup_dir)
	utils.execute("rm -rf " .. backup_dir)
	if verbose then
		print("Created backup at " .. backup_dir .. ".zip")
		print("Removed backup directory at " .. backup_dir)
	end
end
