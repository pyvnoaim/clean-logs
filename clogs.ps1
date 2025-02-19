param(
    [Parameter(Mandatory)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        # If no base path exists (e.g., user starts with "C:\")
        if (-not $wordToComplete -or $wordToComplete -eq "") {
            $basePath = "."
        } else {
            # Calculate the path from the input
            $basePath = [System.IO.Path]::GetDirectoryName($wordToComplete)
            if (-not $basePath) { $basePath = $wordToComplete } # Base is the input itself
        }
        
        # If the base path is invalid, return no suggestions
        if (-not (Test-Path $basePath -PathType Container)) {
            return @()
        }
        
        # Get suggestions based on input
        Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "$wordToComplete*" } |
        ForEach-Object { $_.FullName }
    })]
    [string]$Path,

    [Parameter()]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        if (-not $wordToComplete -or $wordToComplete -eq "") {
            $basePath = "."
        } else {
            $basePath = [System.IO.Path]::GetDirectoryName($wordToComplete)
            if (-not $basePath) { $basePath = $wordToComplete }
        }
        
        if (-not (Test-Path $basePath -PathType Container)) {
            return @()
        }
        
        Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "$wordToComplete*" } |
        ForEach-Object { $_.FullName }
    })]
    [string]$ArchivePath,

    [Parameter(Mandatory)]
    [ValidateScript({ $_ -ge 0 })] # Ensure age is a non-negative integer
    [int]$Age
)

# Function to display formatted messages
function Write-Status {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if ($Color -eq "Red") {
        Write-Host -ForegroundColor $Color "[x] $Message"
    } elseif ($Color -eq "Green") {
        Write-Host -ForegroundColor $Color "[√] $Message"
    } elseif ($Color -eq "Yellow") {
        Write-Host -ForegroundColor $Color "[!] $Message"
    } elseif ($Color -eq "Cyan") {
        Write-Host -ForegroundColor $Color "[i] $Message"
    } else {
        Write-Host -ForegroundColor $Color "[i] $Message"
    }
}

# Function to calculate and format file sizes
function Format-FileSize {
    param(
        [long]$SizeInBytes
    )
    if ($SizeInBytes -gt 1GB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    } else {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
}

Write-Host

# Check for administrator privileges
$user = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not ($user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Status -Message "This script needs to be executed as an administrator." -Color "Yellow"
    exit
}

# Set default ArchivePath if not provided
if (-not $ArchivePath) {
    $ArchivePath = Join-Path -Path $Path -ChildPath "Archive"
}

# Check if the specified Path exists
if (-Not (Test-Path $Path -PathType Container)) {
    Write-Status -Message "'$Path' does not exist." -Color "Yellow"
    exit
}

# Create Archive directory if it doesn't exist
if (-Not (Test-Path $ArchivePath)) {
    New-Item -Path $ArchivePath -ItemType Directory | Out-Null
}

# Find log files
$log_files = Get-ChildItem -Path $Path -Filter "*.log" -File -Recurse
$log_files_count = $log_files.Count
$total_size_bytes = ($log_files | Measure-Object -Property Length -Sum).Sum
$total_size_formatted = Format-FileSize -SizeInBytes $total_size_bytes

# Filter outdated logs
$months_ago = (Get-Date).AddMonths(-$Age)
$old_logs = $log_files | Where-Object { $_.LastWriteTime -lt $months_ago }
$old_logs_count = $old_logs.Count
$old_logs_size_bytes = ($old_logs | Measure-Object -Property Length -Sum).Sum
$old_logs_size_formatted = Format-FileSize -SizeInBytes $old_logs_size_bytes

# Display log information
Write-Status -Message "Path: $Path" -Color "Cyan"
Write-Status -Message "Archive: $ArchivePath" -Color "Cyan"
Write-Host -ForegroundColor Gray "---"
Write-Status -Message "$log_files_count log file(s) found - $total_size_formatted" -Color "Green"

# Check for outdated logs
if ($old_logs_count -eq 0) {
    Write-Status -Message "0 outdated log file(s) found" -Color "Green"
    Write-Host
    exit
} else {
    Write-Status -Message "$old_logs_count outdated log file(s) found - $old_logs_size_formatted" -Color "Red"
    Write-Host -ForegroundColor Gray "---"
}

# Prompt user for archiving confirmation
$confirm = Read-Host "[~] Archive outdated log file(s)? (y/N)"
if ($confirm -ne "y") {
    Write-Status -Message "Archiving canceled by the user." -Color "Red"
    exit
}

# Create ZIP file
$zip_name = "Archived_Logs_{0:yyyy-MM-dd}.zip" -f (Get-Date)
$zip_path = Join-Path -Path $ArchivePath -ChildPath $zip_name

# Initialize variables to track skipped files
$skipped_files = @()
$skipped_size_bytes = 0
$archived_files = @()
$archived_size_bytes = 0

try {
    # Process outdated logs
    foreach ($old_log in $old_logs) {
        if ($old_log.Length -gt 2GB) {
            $skipped_files += $old_log
            $skipped_size_bytes += $old_log.Length
            Write-Status -Message "Skipping file '$($old_log.FullName)' - Size exceeds 2GB" -Color "Yellow"
        } else {
            $archived_files += $old_log
            $archived_size_bytes += $old_log.Length
        }
    }

    # Archive files if any are eligible
    if ($archived_files.Count -gt 0) {
        $archived_size_formatted = Format-FileSize -SizeInBytes $archived_size_bytes
        Compress-Archive -Path ($archived_files.FullName) -DestinationPath $zip_path -Force

        if (Test-Path $zip_path) {
            Write-Status -Message "$($archived_files.Count) log file(s) archived into '$zip_name' - $archived_size_formatted" -Color "Green"
            Write-Host -ForegroundColor Gray "---"

            # Prompt user for deletion confirmation
            $delete_confirm = Read-Host "[~] Delete the archived files from the source directory? (y/N)"
            if ($delete_confirm -eq "y") {
                $archived_files | Remove-Item -Force
                Write-Status -Message "$($archived_files.Count) log file(s) deleted - $archived_size_formatted" -Color "Green"
            } else {
                Write-Status -Message "Deleting canceled by the user." -Color "Red"
            }
        } else {
            Write-Status -Message "Archiving failed. Log files were not deleted." -Color "Red"
        }
    } else {
        Write-Host -ForegroundColor Gray "---"
        Write-Status -Message "No files to archive after skipping files larger than 2GB." -Color "Red"
    }

    # Output skipped files
    if ($skipped_files.Count -gt 0) {
        $skipped_size_formatted = Format-FileSize -SizeInBytes $skipped_size_bytes
        Write-Status -Message "Skipped $($skipped_files.Count) file(s): - $skipped_size_formatted" -Color "Yellow"
        foreach ($skipped_file in $skipped_files) {
            Write-Status -Message "    - $($skipped_file.FullName)" -Color "Yellow"
        }
    }
} catch {
    Write-Status -Message "An error occurred during archiving: $_" -Color "Yellow"
    Write-Status -Message "Log files were not deleted." -Color "Red"
}
Write-Host