# dotfiles-installer

A simple lua script to install my dotfiles.

## Installation

Clone the repository wherever you want:

```bash
git clone https://github.com/pabloavi/dotfiles-installer.git
```

Then that's it, you're ready to use it.

## Usage

As simple as running the script:

```bash
lua main.lua
```

Of course, the script is bundled with options. Here we have the help message:

```bash
lua main.lua --help
```

```
  -h, --help           print this help
  -v, --verbose        print everything
  -y, --yes            assume yes to all prompts
  -f, --force          force install of dotfiles
  -d, --dry-run        don't actually do anything
  -nb, --no-backup     don't backup files
  --config=FILE        use FILE as config file
  --dotfiles-dir=DIR   use DIR as dotfiles directory
  --backup-dir=DIR     use DIR as backup directory
  --distro=NAME        use NAME as distro
  --ignore-options     ignore options in config file

```

## Configuration

The script can be configured by using a config file. The default config file is `config.lua` and it's located in the same directory as the script. You can use the `--config` option to specify a different config file. The only distributions available are fedora and arch, as they are the only ones I use. The config file is a json file, and contains all the information needed (options and packages):

```json
{
  "dotfiles_repo": "http://repo_url.git", // The url of the dotfiles repository
  "dotfiles_dir": "~/.dotfiles", // The directory where the dotfiles will saved
  "backup_dir": "/tmp/dotfiles_backup", // The directory where the backup will be saved
  "options": { // The options for the script
    "verbose": false,
    "backup": true,
    // ...
  },
  "arch": {
    "pacman": [
      "bspwm",
      "sxhkd",
      // ...
    ],
  "fedora": {
    "dnf": [
      "bspwm",
      "sxhkd",
      // ...
    ],
    "copr": [
      "pabloavi/whatever",
      // ...
    ],
  }
  "pip3": [ // The packages that will be installed with pip3
    "inkscape-figures",
    "pywal",
    // ...
    ],
  "nodejs": [ // The packages that will be installed with npm
    "rae-api",
    // ...
    ],
  "software_commands": [ // The commands that will be executed one by one (of course, you can use && to execute multiple commands)
    "wget https://raw.githubusercontent.com/ronniedroid/Wall-d/master/wall-d -O ~/.local/bin/wall-d",
    "rmtrash -rf ~/.config/nvim && git clone https://github.com/pabloavi/NvChad/ ~/.config/nvim",
    "dir='$HOME/Documentos/git/repos/multirice-dotfiles/' && rmtrash -rf $dir && git clone https://github.com/pabloavi/multirice-dotfiles/ $dir && cd $dir && ln -sf -r $dir/colorchanger/* ~/.local/bin/ && ln -sf -r $dir/ricechanger/* ~/.local/bin/* "
    // ...
  ],
  "ignored": [ // The files that will be ignored when installing the dotfiles
    "/.git/", // ending with a / means that it's a directory (so it will ignore everything inside it)
    "/README.md", // starting with a / means that it's a relative path to the dotfiles directory root
    "/LICENSE", // Ignore the file `LICENSE` in dotfiles root
    "/.gitignore", // Ignore all files named `.gitignore` in any folder
    "/.gitmodules", // Ignore all files named `.gitmodules` in any folder
    "/dotfiles_backup.zip", // Ignore the file `/dotfiles_backup.zip` in dotfiles root
    "/installer/", // Ignore all files inside `installer` directory in root (containning itself)
    "indent.log" // Without any /, it means it's just a file name to match; i.e. this ignores all files named `indent.log` in any folder
  ]
}
```

The script works by cloning the dotfiles repository to the `dotfiles_dir` directory, and then installing the dotfiles with all dependencies by symlinking all files in it to the home directory, overwriting if necessary.

## TODO

- [ ] Test with arch.
- [ ] Add reinstall option, so that it can be used to update the dotfiles without running the whole script again.
- [ ] Add uninstall option, so that all symlinks that come from the dotfiles are removed.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
