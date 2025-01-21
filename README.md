# clogs (Powershell Script)

This PowerShell script is designed to archive and optionally delete old log files from a specified directory. It is particularly useful for managing log files in environments where logs accumulate over time, taking up valuable disk space. The script allows for custom directory paths, age filters, and user confirmation for both archiving and deletion of the log files.

## Features

- **Archives** log files that are older than a specified number of months.
- **Optionally deletes** the archived log files after they have been successfully archived.
- **Creates an archive folder** if one doesn't exist.
- **Checks for administrator privileges** before execution.
- **Limits archiving to log files** that are 2GB or smaller, skipping larger files and flagging them in the output.

## Prerequisites

- PowerShell **5.1 or newer**.
- Administrator rights for execution.

## Parameters

The script requires three parameters:

### 1. `-Path` (Mandatory)

The path to the directory where the log files are located. The script will search for log files with the `.log` extension in this directory and its subdirectories.

- **Type**: `string`
- **Example**: `"C:\Logs"`

### 2. `-ArchivePath` (Optional)

The path where archived log files will be stored. If not provided, the script will create an `Archive` folder within the specified `-Path` directory.

- **Type**: `string`
- **Example**: `"C:\Logs\Archive"`

### 3. `-Age` (Mandatory)

The age (in months) of the log files to be archived. Any log file older than this number of months will be considered for archiving.

- **Type**: `int`
- **Example**: `6` (for files older than 6 months)

## Usage

```powershell
.\clogs.ps1 -Path "C:\Logs" -Age 6
```

This command will:

1. Look for `.log` files in the `C:\Logs` directory and its subdirectories.
2. Archive all log files older than 6 months into a new ZIP archive.
3. Prompt the user to delete the archived files.

If you want to specify a custom archive path:

```powershell
.\clogs.ps1 -Path "C:\Logs" -ArchivePath "C:\Logs\Backup" -Age 6
```

This will archive the logs into the `C:\Logs\Backup` directory.

> **Note**: You can use the `tab` key to autocomplete paths for `-Path` and `-ArchivePath`, but make sure to start with `C:\` or the drive letter of the path you want.

## Script Workflow

1. **Check for administrator privileges**: The script ensures it is running with administrator rights. If not, it will exit with a warning.
2. **Find log files**: It searches the provided path for `.log` files and calculates the total size of these files.
3. **Find outdated log files**: It filters out log files that are older than the specified age and calculates their size.
4. **Skip files larger than 2GB**: Log files greater than 2GB will be skipped and flagged in the output.
5. **Prompt for archiving**: If outdated log files are found, it asks the user whether they want to archive them.
6. **Archive logs**: If confirmed, the script compresses the outdated log files into a ZIP file.
7. **Prompt for deletion**: After archiving, it asks whether the user wants to delete the archived files from the source directory.
8. **Complete**: The script finishes by confirming the archive and deletion actions, or aborts the process if the user cancels any of the steps.

## Example Output

```plaintext
[i] Path: C:\Logs
[i] Archive: C:\Logs\Archive
---
[+] 10 log file(s) found - 120.00 MB
[!] 3 outdated log file(s) found - 45.00 MB
[!] 1 file(s) larger than 2GB skipped - 2.1 GB
---
[~] Archive outdated log file(s)? (y/N)
[+] 3 log file(s) archived into 'Archived_Logs_2024-11-25.zip' - 45.00 MB
---
[~] Delete the archived files from the source directory? (y/N)
[+] 3 log file(s) deleted - 45.00 MB deleted
```

## Error Handling

- The script will notify you if it encounters any issues while creating the archive, such as missing permissions or invalid paths.
- If an error occurs during the archiving process, the script will display the error message but will not delete any files.

## Contribution

Feel free to fork and improve the script! Pull requests are welcome.
