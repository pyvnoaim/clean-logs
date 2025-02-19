# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- _No unreleased changes at this time._

---

## [2.0.0] - 2025-02-19

### Added

- Complete code overhaul and improvements for better performance and reliability.

### Fixed

- Resolved various issues and improved output quality.

---

## [1.1.0] - 2024-11-25

### Added

- **Skip Large Files**: Added logic to skip log files larger than 2GB during the archiving process. These files are flagged in the output.
- **Flagging of Skipped Files**: Large files (over 2GB) are now explicitly noted in the output but excluded from the archive process.

### Fixed

- Improved handling of large files (>2GB) by skipping them and notifying the user.

---

## [1.0.0] - 2024-11-25

### Added

- **Administrator Check**: Ensures the script is run with administrator privileges before proceeding.
- **-Path Parameter**: Specifies the directory containing the .log files to archive.
- **-ArchivePath Parameter**: Optionally specifies a custom directory to store archived log files. Defaults to an Archive folder in the -Path directory if not provided.
- **-Age Parameter**: Defines the age (in months) of the log files to be archived.
- **Log File Search**: Searches for .log files in the provided -Path directory and subdirectories.
- **Outdated Log File Detection**: Filters log files based on the specified age and prepares them for archiving.
- **User Confirmation**: Prompts the user for confirmation before archiving and deleting old log files.
- **Log File Compression**: Archives outdated log files into a ZIP file.
- **Delete Confirmation**: Prompts the user to confirm whether to delete the archived files from the source directory.
- **Formatted Output**: Displays detailed output on the total size of log files, the size of outdated logs, and the number of files found.
- **Error Handling**: Catches errors during the archiving process and ensures that log files are not deleted if an error occurs.

### Fixed

- Initial release with basic functionality working as expected for archiving and deleting log files.

---

## [0.1.0] - 2024-11-20

### Added

- Initial concept development (internal testing).
- Basic script structure for searching log files, archiving, and deleting.
- Logging and error handling features added for better traceability during execution.

---

## [0.0.1] - 2024-11-15

### Added

- Project initialized.
