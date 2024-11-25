param(
    [Parameter(Mandatory)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        # Wenn kein Basispfad existiert (z. B. Benutzer beginnt mit "C:\")
        if (-not $wordToComplete -or $wordToComplete -eq "") {
            $basePath = "."
        } else {
            # Pfad aus dem Wort berechnen
            $basePath = [System.IO.Path]::GetDirectoryName($wordToComplete)
            if (-not $basePath) { $basePath = $wordToComplete } # Basis ist die Eingabe selbst
        }
        
        # Falls der Basispfad ungültig ist, keine Vorschläge zurückgeben
        if (-not (Test-Path $basePath -PathType Container)) {
            return @()
        }
        
        # Vorschläge basierend auf Eingabe suchen
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
    [int]$Age
)

# Administratorrechte prüfen
$user = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not ($user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Warning "This script needs to be executed as an administrator."
    Write-Host
    exit
}

# Default ArchivePath erstellen, falls nicht angegeben
if (-not $ArchivePath) {
    $ArchivePath = Join-Path -Path $Path -ChildPath "Archive"
}

Write-Host

# Prüfen, ob der Path-Ordner existiert
if (-Not (Test-Path $Path -PathType Container)) {
    Write-Warning "'$Path' doesn't exist."
    Write-Host
    exit
}

# Archive-Ordner erstellen, falls er nicht existiert
if (-Not (Test-Path $ArchivePath)) {
    New-Item -Path $ArchivePath -ItemType Directory | Out-Null
}

# Validierung des Alters
if ($Age -lt 0) {
    Write-Warning "The age must be a positive integer."
    exit
}

# Logdateien suchen
$log_files = Get-ChildItem -Path $Path -Filter "*.log" -File -Recurse
$log_files_count = $log_files.Count
$total_size_mb = [math]::round(($log_files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$months_ago = (Get-Date).AddMonths(-$Age)
$old_logs = $log_files | Where-Object { $_.LastWriteTime -lt $months_ago }
$old_logs_count = $old_logs.Count
$deleted_size_mb = [math]::round(($old_logs | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

# Formatierte Größen
$formatted_total_size_gb = "{0:N2}" -f ($total_size_mb / 1024)
$formatted_total_size_mb = "{0:N2}" -f $total_size_mb
$formatted_deleted_size_gb = "{0:N2}" -f ($deleted_size_mb / 1024)
$formatted_deleted_size_mb = "{0:N2}" -f $deleted_size_mb

# Log-Informationen ausgeben
Write-Host -ForegroundColor Cyan "[i] Path: $Path"
Write-Host -ForegroundColor Cyan "[i] Archive: $ArchivePath"
Write-Host -ForegroundColor Gray "---"
if ($total_size_mb -gt 1024) {
    Write-Host -ForegroundColor Green "[+] $log_files_count log file(s) found - $formatted_total_size_gb GB"
} else {
    Write-Host -ForegroundColor Green "[+] $log_files_count log file(s) found - $formatted_total_size_mb MB"
}

# Veraltete Logs prüfen
if ($old_logs_count -eq 0) {
    Write-Host -ForegroundColor Green "[+] 0 outdated log file(s) found"
    Write-Host
    exit
} else {
    if ($total_size_mb -gt 1024) {
        Write-Host -ForegroundColor Red "[!] $old_logs_count outdated log file(s) found - $formatted_deleted_size_gb GB"
    } else {
        Write-Host -ForegroundColor Red "[!] $old_logs_count outdated log file(s) found - $formatted_deleted_size_mb MB"
    }
    Write-Host -ForegroundColor Gray "---"
}

# Benutzerabfrage zur Archivierung
$confirm = Read-Host "[~] Archive outdated log file(s)? (y/N)"
if ($confirm -ne "y") {
    Write-Host -ForegroundColor Red "[!] Archiving canceled by the user."
    Write-Host
    exit
}

# ZIP-Datei erstellen
$zip_name = "Archived_Logs_{0:yyyy-MM-dd}.zip" -f (Get-Date)
$zip_path = Join-Path -Path $ArchivePath -ChildPath $zip_name

try {
    # Logdateien archivieren
    $old_logs_paths = $old_logs | ForEach-Object { $_.FullName }
    Compress-Archive -Path $old_logs_paths -DestinationPath $zip_path -Force

    # Überprüfen, ob die Archivdatei erstellt wurde
    if (Test-Path $zip_path) {
        if ($total_size_mb -gt 1024) {
            Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) archived into '$zip_name' - $formatted_total_size_gb GB"
        } else {
            Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) archived into '$zip_name' - $formatted_total_size_mb MB"
        }
        Write-Host -ForegroundColor Gray "---"
        
        # Benutzerabfrage zur Löschung
        $delete_confirm = Read-Host "[~] Delete the archived files from the source directory? (y/N)"
        if ($delete_confirm -eq "y") {
            foreach ($old_log in $old_logs) {
                Remove-Item $old_log.FullName -Force
            }
            if ($deleted_size_mb -gt 1024) {
                Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) deleted - $formatted_deleted_size_gb GB deleted"
            } else {
                Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) deleted - $formatted_deleted_size_mb MB deleted"
            }
        } else {
            Write-Host -ForegroundColor Red "[!] Deleting canceled by the user."
        }
    } else {
        Write-Host -ForegroundColor Red "[!] Archiving failed. Log files were not deleted."
    }
} catch {
    Write-Host -ForegroundColor Yellow "[i] An error occurred during archiving: $_"
    Write-Host -ForegroundColor Red "[!] Log files were not deleted."
}
Write-Host