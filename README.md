# CLOGS

This PowerShell script is designed to help you manage log files by archiving outdated logs based on their age. It allows you to specify a directory containing log files, an archive directory, and the age (in months) of logs to be archived. The script also provides options to delete the archived logs from the source directory after archiving.

---

## Features

- **Directory and Archive Path Autocompletion**: The script uses PowerShell's `ArgumentCompleter` to provide directory path suggestions for both the source and archive paths.
- **Log Age Filtering**: Logs older than the specified number of months are identified and archived.
- **File Size Handling**: Logs larger than 2GB are skipped during archiving.
- **ZIP Archiving**: Outdated logs are compressed into a ZIP file with a timestamped name.
- **User Prompts**: The script prompts for confirmation before archiving and deleting files.
- **Administrator Privileges Check**: Ensures the script is run with administrator privileges.
- **Detailed Output**: Provides clear status messages and summaries of actions taken.

---

## Prerequisites

- **PowerShell 5.1 or later**: The script is written for PowerShell and requires at least version 5.1.
- **Administrator Privileges**: The script must be run as an administrator to perform file operations.

---

## Usage

### Parameters

- **`-Path`**: The directory containing the log files to be archived. This parameter is mandatory.
- **`-ArchivePath`**: The directory where the archived logs will be stored. If not provided, it defaults to a subdirectory named `Archive` within the source directory.
- **`-Age`**: The age (in months) of logs to be archived. This parameter is mandatory and must be a non-negative integer.

### Example Command

```powershell
.\LogArchiver.ps1 -Path "C:\Logs" -ArchivePath "C:\ArchivedLogs" -Age 6
```

This command will archive all `.log` files in `C:\Logs` that are older than 6 months into `C:\ArchivedLogs`.

---

## Script Workflow

1. **Input Validation**:

   - Checks if the specified `Path` exists.
   - Ensures the script is run with administrator privileges.
   - Sets a default `ArchivePath` if not provided.

2. **Log File Discovery**:

   - Recursively searches for `.log` files in the specified directory.
   - Calculates the total size of all log files found.

3. **Outdated Log Filtering**:

   - Identifies logs older than the specified age.
   - Calculates the total size of outdated logs.

4. **User Confirmation**:

   - Prompts the user to confirm archiving of outdated logs.
   - If confirmed, proceeds to archive the logs into a ZIP file.

5. **File Archiving**:

   - Skips files larger than 2GB.
   - Archives eligible files into a timestamped ZIP file in the `ArchivePath`.

6. **Post-Archiving Actions**:
   - Prompts the user to delete the archived logs from the source directory.
   - Provides a summary of skipped files (if any).

---

## Output Examples

### Successful Archiving

```
[i] Path: C:\Logs
[i] Archive: C:\ArchivedLogs
---
[√] 10 log file(s) found - 1.23 GB
[x] 5 outdated log file(s) found - 650.00 MB
---
[~] Archive outdated log file(s)? (y/N): y
[√] 5 log file(s) archived into 'Archived_Logs_2023-10-15.zip' - 650.00 MB
---
[~] Delete the archived files from the source directory? (y/N): y
[√] 5 log file(s) deleted - 650.00 MB
```

### Skipped Files

```
[i] Path: C:\Logs
[i] Archive: C:\ArchivedLogs
---
[√] 10 log file(s) found - 1.23 GB
[x] 5 outdated log file(s) found - 650.00 MB
---
[~] Archive outdated log file(s)? (y/N): y
[!] Skipping file 'C:\Logs\large_log.log' - Size exceeds 2GB
[√] 4 log file(s) archived into 'Archived_Logs_2023-10-15.zip' - 450.00 MB
---
[!] Skipped 1 file(s): - 200.00 MB
    - C:\Logs\large_log.log
```

---

## Notes

- **Large Files**: Files larger than 2GB are skipped during archiving due to limitations with the `Compress-Archive` cmdlet.
- **Error Handling**: The script includes basic error handling to ensure logs are not deleted if archiving fails.
- **Customization**: You can modify the script to adjust the maximum file size limit or change the archive naming convention.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

Enjoy managing your logs efficiently! 🚀
