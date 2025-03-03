import { promises as fs } from 'fs';
import { dirname, join, basename, parse } from 'path';
import inquirer from 'inquirer';
import { fileURLToPath } from 'url';

// Get current file and directory paths
const __filename = fileURLToPath(import.meta.url);
const __dirnamePath = dirname(__filename);

// Define constants
const SCRIPTS_DIR = basename(__dirnamePath); // Should be 'lib'
const BACKUP_ROOT = process.cwd(); // Use current working directory as backup root

// Function to get available items (files and directories) excluding 'lib'
export async function getAvailableItems(path) {
    try {
        const entries = await fs.readdir(path, { withFileTypes: true });
        const items = entries
            .filter(entry => entry.name !== SCRIPTS_DIR) // Exclude 'lib' directory
            .map(entry => ({
                name: `${entry.isDirectory() ? '[DIR] ' : '[FILE] '} ${entry.name}`,
                value: entry.name
            }));
        return items;
    } catch (error) {
        console.error('Error reading items:', error);
        throw error;
    }
}

// Function to prompt user to select items to backup
export async function promptForItems(availableItems) {
    if (availableItems.length === 0) {
        console.log('No available files or directories to backup.');
        process.exit(1);
    }

    const answers = await inquirer.prompt([
        {
            type: 'checkbox',
            name: 'selectedItems',
            message: 'Select files and/or directories to backup:',
            choices: availableItems,
            validate: (input) => {
                if (input.length === 0) {
                    return 'You must select at least one file or directory to backup.';
                }
                return true;
            }
        }
    ]);
    return answers.selectedItems;
}

// Function to prompt user to select version type
export async function promptForVersionType(itemName) {
    const answers = await inquirer.prompt([
        {
            type: 'list',
            name: 'versionType',
            message: `Choose version increment type for "${itemName}":`,
            choices: [
                { name: 'Patch (bug fixes) - x.x.X', value: 1 },
                { name: 'Minor (new features) - x.X.0', value: 2 },
                { name: 'Major (breaking changes) - X.0.0', value: 3 },
            ],
            default: 1
        }
    ]);
    return answers.versionType;
}

// Function to get next version number for a specific item
export async function getNextVersionNumber(itemName) {
    try {
        const items = await fs.readdir(BACKUP_ROOT);
        const parsedItem = parse(itemName);

        // Create pattern that matches the name and version, handling file extensions properly
        const versionPattern = parsedItem.ext
            ? new RegExp(`^${parsedItem.name.replace(/\./g, '\\.')}_(\\d+)\\.(\\d+)\\.(\\d+)\\${parsedItem.ext}$`)
            : new RegExp(`^${itemName.replace(/\./g, '\\.')}_(\\d+)\\.(\\d+)\\.(\\d+)$`);

        const versionedItems = items
            .map(item => {
                const match = item.match(versionPattern);
                if (match) {
                    return {
                        item,
                        version: match.slice(1).map(Number) // [major, minor, patch]
                    };
                }
                return null;
            })
            .filter(entry => entry !== null)
            .sort((a, b) => {
                for (let i = 0; i < 3; i++) {
                    if (a.version[i] !== b.version[i]) {
                        return b.version[i] - a.version[i];
                    }
                }
                return 0;
            });

        let nextVersion;
        if (versionedItems.length === 0) {
            nextVersion = '0.1.0';
        } else {
            const versionType = await promptForVersionType(itemName);
            const latestVersion = [...versionedItems[0].version]; // Clone the array

            switch (versionType) {
                case 3: // Major
                    latestVersion[0]++;
                    latestVersion[1] = 0;
                    latestVersion[2] = 0;
                    break;
                case 2: // Minor
                    latestVersion[1]++;
                    latestVersion[2] = 0;
                    break;
                default: // Patch
                    latestVersion[2]++;
            }

            nextVersion = latestVersion.join('.');
        }

        return nextVersion;
    } catch (error) {
        console.error(`Error determining next version for ${itemName}:`, error);
        throw error;
    }
}

// Function to create a backup with individual versioning
export async function createBackup() {
    try {
        const availableItems = await getAvailableItems(BACKUP_ROOT);
        const selectedItems = await promptForItems(availableItems);

        console.log('\nStarting backup process...');
        console.log('Please wait...');

        // Process each selected item individually
        for (const item of selectedItems) {
            const sourcePath = join(BACKUP_ROOT, item);
            const stats = await fs.lstat(sourcePath);

            // Get next version number for this specific item
            const nextVersion = await getNextVersionNumber(item);

            if (stats.isDirectory()) {
                // For directories: Append version to directory name and copy contents
                const newDirName = `${item}_${nextVersion}`;
                const destinationPath = join(BACKUP_ROOT, newDirName);

                await fs.cp(sourcePath, destinationPath, {
                    recursive: true,
                    filter: (src) => {
                        return !src.includes('node_modules') &&
                            !src.includes('.git') &&
                            !src.includes('backup_public');
                    }
                });

                console.log(`\nDirectory backed up: ${newDirName}`);
            } else if (stats.isFile()) {
                // For files: Append version before file extension
                const parsedPath = parse(item);
                const newFileName = `${parsedPath.name}_${nextVersion}${parsedPath.ext}`;
                const destinationPath = join(BACKUP_ROOT, newFileName);

                await fs.copyFile(sourcePath, destinationPath);

                console.log(`\nFile backed up: ${newFileName}`);
            } else {
                console.log(`\nSkipping unsupported item type: ${item}`);
            }
        }

        console.log('\nAll selected items have been backed up successfully! ✅');
        console.log(`Location: ${BACKUP_ROOT}`);

        // Removed listing of all backups as per your request
    } catch (error) {
        console.error('Error creating backup:', error);
    }
}
