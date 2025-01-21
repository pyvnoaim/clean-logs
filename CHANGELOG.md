# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-01-21

### Added

- **Direct Deletion Without Archiving**: Introduced functionality to delete log files directly without archiving them. This provides users with more flexibility in managing log files.

## [1.1.0] - 2024-11-25

### Added

- **Skip Large Files**: Added logic to skip log files larger than 2GB during the archiving process, with these files being flagged in the output.
- **Flagging of Skipped Files**: Large files (over 2GB) are now explicitly noted in the output, but not included in the archive process.

### Fixed

- No significant fixes, but the script now better handles large files (>2GB) by skipping them and notifying the user.

## [1.0.0] - 2024-11-25

### Added

- **Administrator Check**: Ensures the script is run with administrator privileges before proceeding.
- **`-Path` Parameter**: Specifies the directory containing the `.log` files to archive.
- **`-ArchivePath` Parameter**: Optionally specifies a custom directory to store archived log files. Defaults to `Archive` folder in the `-Path` directory if not provided.
- **`-Age` Parameter**: Defines the age (in months) of the log files to be archived.
- **Log File Search**: Searches for `.log` files in the provided `-Path` directory and subdirectories.
- **Outdated Log File Detection**: Filters log files based on the specified age and prepares them for archiving.
- **User Confirmation**: Prompts the user for confirmation before archiving and deleting old log files.
- **Log File Compression**: Archives outdated log files into a ZIP file.
- **Delete Confirmation**: Prompts the user to confirm whether to delete the archived files from the source directory.
- **Formatted Output**: Displays detailed output on the total size of log files, the size of outdated logs, and the number of files found.
- **Error Handling**: Catches errors during the archiving process and ensures that log files are not deleted if an error occurs.

### Fixed

- Initial release with basic functionality working as expected for archiving and deleting log files.

## [0.1.0] - 2024-11-20

### Added

- Initial concept development (internal testing).
- Basic script structure for searching log files, archiving, and deleting.
- Logging and error handling features added for better traceability during execution.
