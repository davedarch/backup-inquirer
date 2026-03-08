# Backup Inquirer CLI Tool

!Backup Inquirer

!License

Backup Inquirer is a command-line interface (CLI) tool that allows you to back up files and directories with semantic versioning. It provides an interactive experience to select items for backup and increment their versions individually, ensuring organized and trackable backups.

## 📦 Features

- Interactive Selection: Easily choose files and directories to back up using an intuitive checkbox interface.

- Semantic Versioning: Increment versions individually for each file and directory based on your needs (Patch, Minor, Major).

- Global Accessibility: Run the backup command from any directory on your system.

- Exclusion Filters: Automatically exclude common directories like node_modules, .git, and backup_public to streamline your backups.

- Future-Ready: Designed for easy extension with features like compression, logging, and scheduling.

## 🚀 Installation

### Prerequisites

- Node.js: Ensure you have Node.js (v16.7.0 or higher) installed. You can download it from Node.js Official Website.

### Local Installation

- Clone the Repository:
    
       git clone https://github.com/yourusername/your-backup-tool.git
    
       cd your-backup-tool
    

- Install Dependencies:
    
       npm install
    

- Link the Package Globally:

This allows you to use the backup command from any directory.

   npm link

Note: This creates a symbolic link in your global node_modules. If you encounter permission issues, you might need to run the command with elevated privileges or adjust your npm permissions.

### Global Installation via NPM

Once you've published the package to NPM (see Publishing to NPM), you can install it globally using:

npm install -g your-backup-tool

Replace your-backup-tool with the actual name of your package.

## 🎯 Usage

After installation, you can use the backup command from any directory to initiate the backup process.

### Basic Usage

backup

#### What Happens:

- Select Items to Backup:

- An interactive checkbox prompt displays all available files and directories in the current working directory (excluding the lib directory).

- Use the arrow keys to navigate and the spacebar to select/deselect items.

- Press Enter to confirm your selections.

!Select Items

- Choose Version Increment Type:

- For each selected item, choose how you want to increment its version:

- Patch (x.x.X): For bug fixes and minor changes.

- Minor (x.X.0): For adding new features without breaking existing functionality.

- Major (X.0.0): For significant changes that may break backward compatibility.

!Choose Version

- Backup Execution:

- The tool copies and renames each selected item with the new version number.

- Files are renamed by appending the version before the file extension (e.g., file01.txt → file01_0.1.1.txt).

- Directories are renamed by appending the version to the directory name (e.g., project → project_0.2.3).

- Completion Message:

- A summary confirming the successful creation of backups.
    
       All selected items have been backed up successfully! ✅
    
       Location: /path/to/current/directory
    

### Example Workflow

- Navigate to Your Project Directory:
    
       cd /path/to/your/project
    

- Run the Backup Command:
    
       backup
    

- Interactive Prompts:

- Select Items:
    
         ? Select files and/or directories to backup:
    
         ❯ ◯ [DIR] src
    
           ◯ [DIR] public
    
           ◯ [FILE] README.md
    
           ◯ [FILE] package.json
    
    - Choose Version for Each Item:
    
         ? Choose version increment type for "src":
    
           ◯ Patch (bug fixes) - x.x.X
    
         ❯ ◯ Minor (new features) - x.X.0
    
           ◯ Major (breaking changes) - X.0.0
    

- Backup Process:

- Files and directories are copied and renamed with the new versions.

- Example Output:
    
         Directory backed up: src_0.2.3
    
         File backed up: README_0.1.1.md
    
         File backed up: package_0.1.1.json
    
         All selected items have been backed up successfully! ✅
    
         Location: /path/to/your/project
    

## ZSH Versions (macOS Native)

Two standalone ZSH scripts are included that replicate all functionality without requiring Node.js or any npm dependencies. ZSH is the default shell on macOS (Catalina and later).

### backup.zsh — Pure ZSH, Zero Dependencies

No dependencies at all. Uses a numbered toggle list for item selection and ZSH's built-in `select` for version type prompts.

```zsh
# Make executable (first time only)
chmod +x backup.zsh

# Run from the directory you want to back up
./backup.zsh

# Or specify a target directory
./backup.zsh /path/to/directory
```

**Item selection:**
```
Select files and/or directories to backup:
(Enter numbers to toggle, 'a' to select all, 'd' to deselect all, empty to confirm)

  *  1) [FILE] README.md
     2) [DIR]  src
  *  3) [FILE] config.json

>
```

**Version type:**
```
Choose version increment type for "README.md":
1) Patch (bug fixes) - x.x.X
2) Minor (new features) - x.X.0
3) Major (breaking changes) - X.0.0
Enter choice [1-3]:
```

### backup-fzf.zsh — ZSH + fzf (Prettier UI)

Uses [fzf](https://github.com/junegunn/fzf) for fuzzy-searchable multi-select and single-select menus.

```zsh
# Install fzf (one time)
brew install fzf

# Make executable (first time only)
chmod +x backup-fzf.zsh

# Run
./backup-fzf.zsh
./backup-fzf.zsh /path/to/directory
```

**Item selection** — use Tab to toggle, type to fuzzy search, Enter to confirm:
```
  Backup>
  * [DIR]  src
    [FILE] README.md
  * [FILE] config.json
  Select items to backup (Tab to toggle, Enter to confirm)
```

**Version type** — single-select fzf menu:
```
  Version>
  > Patch (bug fixes) - x.x.X
    Minor (new features) - x.X.0
    Major (breaking changes) - X.0.0
  Version increment for "README.md":
```

The script checks for fzf on startup and exits with install instructions if it's missing.

### Version Comparison

| | Node.js (`backup`) | ZSH (`backup.zsh`) | ZSH + fzf (`backup-fzf.zsh`) |
|---|---|---|---|
| Dependencies | Node.js, npm, inquirer | None | fzf |
| Multi-select UI | Inquirer checkbox | Numbered toggle | fzf fuzzy multi-select |
| Version prompt | Inquirer list | ZSH `select` | fzf single-select |
| Startup speed | ~200ms+ | Instant | Instant |
| macOS built-in | No | Yes | No (fzf via brew) |

### ZSH Versions — Testing To-Do

The ZSH scripts have not yet been tested. The following should be validated on macOS before use in production:

- [ ] **Basic execution** — both scripts launch without errors on macOS ZSH
- [ ] **Item listing** — files and directories display correctly with `[FILE]`/`[DIR]` labels
- [ ] **Exclusion filtering** — `node_modules`, `.git`, `backup_public`, `lib`, and `.DS_Store` are excluded from the item list
- [ ] **Multi-select (backup.zsh)** — toggling by number, select all (`a`), deselect all (`d`), and confirming with empty input all work correctly
- [ ] **Multi-select (backup-fzf.zsh)** — Tab toggling and Enter confirmation work; type labels are stripped correctly from selections
- [ ] **First backup defaults to 0.1.0** — when no prior versioned copy exists
- [ ] **Patch increment** — e.g. `0.1.0` -> `0.1.1`
- [ ] **Minor increment** — e.g. `0.1.1` -> `0.2.0`
- [ ] **Major increment** — e.g. `0.2.0` -> `1.0.0`
- [ ] **File versioning format** — version inserted before extension (e.g. `notes.txt` -> `notes_0.1.0.txt`)
- [ ] **Directory versioning format** — version appended to name (e.g. `src` -> `src_0.1.0`)
- [ ] **Files with multiple dots** — e.g. `my.config.json` should become `my.config_0.1.0.json`
- [ ] **Files without extensions** — e.g. `Makefile` -> `Makefile_0.1.0`
- [ ] **Directory copy exclusions** — when backing up a directory, `node_modules`, `.git`, and `backup_public` inside it are not copied
- [ ] **Hidden files in directories** — dotfiles inside directories are included in copies
- [ ] **Empty directories** — copied without error
- [ ] **Multiple items in one run** — selecting several items and versioning each independently
- [ ] **Consecutive runs** — running backup twice picks up the latest version and increments correctly
- [ ] **fzf missing (backup-fzf.zsh)** — displays install instructions and exits gracefully
- [ ] **Custom directory argument** — `./backup.zsh /some/path` operates on the specified path
- [ ] **Invalid directory argument** — displays error and exits

## 🛠️ Development

### Project Structure

```
backup-inquirer/
├── bin/
│   └── backup.js            # Node.js CLI entry point
├── lib/
│   └── backup-inquirer.js   # Node.js core backup logic
├── backup.zsh               # ZSH version (zero dependencies)
├── backup-fzf.zsh           # ZSH version (fzf UI)
├── package.json
├── README.md
└── .gitignore
```

### Scripts

### Adding Command-Line Arguments (Optional)

While the current version relies solely on interactive prompts, you can enhance functionality by integrating command-line arguments using libraries like commander. This allows for more flexibility, such as specifying items to backup or version types directly via flags.

### Example:

backup --items file01.txt project --version-type patch

Note: Implementation of command-line arguments is not included in the current version.

## 📦 Publishing to NPM

Publishing your CLI tool to NPM makes it easily installable for others and accessible via the global npm install -g command.

### Step-by-Step Guide

- Create an NPM Account:

If you don't already have one, sign up for an NPM account.

- Login to NPM via CLI:
    
       npm login
    

- Enter your NPM username, password, and email when prompted.

- Update package.json:

Ensure your package.json has the necessary fields correctly configured.

   {

     "name": "your-backup-tool",

     "version": "1.0.0",

     "description": "A CLI tool to backup files and directories with semantic versioning.",

     "main": "lib/backup-inquirer.js",

     "bin": {

       "backup": "./bin/backup.js"

     },

     "type": "module",

     "scripts": {

       "start": "node bin/backup.js"

     },

     "keywords": [

       "backup",

       "cli",

       "semantic-versioning",

       "inquirer"

     ],

     "author": "Your Name",

     "license": "MIT",

     "dependencies": {

       "inquirer": "^8.2.0"

     }

   }

Important Fields:

- name: Must be unique across the NPM registry. Consider using a scoped package (e.g., @yourusername/backup-tool) if the name is already taken.

- version: Follow Semantic Versioning (e.g., 1.0.0).

- bin: Maps the CLI command (backup) to your executable script.

- type: Set to "module" to enable ES module syntax.

- dependencies: Lists all necessary packages.

- Ensure Your Package is Ready:

- Scoped Package (Optional): If you want to scope your package under your NPM username or organization.

Example package.json snippet for a scoped package:

     {

       "name": "@yourusername/backup-tool",

       // ... other fields

     }

- Prepare .gitignore:

Ensure sensitive files like node_modules are excluded.

     node_modules/

     .env

- Add a README.md: Provides users with information about your tool (this document).

- Publish the Package:
    
       npm publish
    

For Scoped Packages:

Scoped packages are private by default. To publish a public scoped package:

   npm publish --access public

- Install Your Package Globally:

Once published, you and others can install the tool globally:

   npm install -g your-backup-tool

Replace your-backup-tool with your actual package name.

- Verify the Installation:

From any directory, run:

   backup

You should see the interactive prompts as defined in your script.

## 📝 Configuration

Currently, the tool uses the current working directory as the backup root. All backups are created within this directory, and the lib folder is excluded by default.

### Future Enhancements

- Configuration File: Introduce a backup-config.json for user-specific settings like exclusion patterns, default version types, and backup destinations.

- Environment Variables: Support environment variables for dynamic configurations.

## 🛠️ Contributing

Contributions are welcome! Please follow these steps to contribute:

- Fork the Repository:

Click the "Fork" button on the GitHub repository page.

- Clone Your Fork:
    
       git clone https://github.com/yourusername/your-backup-tool.git
    
       cd your-backup-tool
    

- Create a New Branch:
    
       git checkout -b feature/your-feature-name
    

- Make Your Changes:

Implement your feature or fix.

- Commit Your Changes:
    
       git commit -m "Add your descriptive commit message"
    

- Push to Your Fork:
    
       git push origin feature/your-feature-name
    

- Create a Pull Request:

Open a pull request on the original repository describing your changes.

## 📝 Licensing

This project is licensed under the MIT License.

## 🙏 Acknowledgements

- Inquirer.js for the interactive CLI prompts.

- Node.js for providing the runtime environment.

- npm for managing and publishing the package.

## 📫 Contact

For any questions, suggestions, or feedback, feel free to open an issue on the GitHub repository or contact me directly at youremail@example.com.

---

Happy Backing Up! 🚀
