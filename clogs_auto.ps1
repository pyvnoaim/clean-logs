# Hinweis: Dieses Skript wurde entwickelt, um automatisiert über die Windows-Aufgabenplanung oder ähnliche Programme ausgeführt zu werden.
# - Sie können die Aufgabenplanung verwenden, um das Skript regelmäßig zu einem bestimmten Zeitpunkt oder bei bestimmten Ereignissen auszuführen.
# - Stellen Sie sicher, dass die Aufgabenplanung so konfiguriert ist, dass das Skript mit Administratorrechten ausgeführt wird.
#
# Passen Sie die folgenden Variablen an Ihre Umgebung an, bevor Sie das Skript einrichten:
# - $drive_letter: Das Laufwerk, das überwacht werden soll (z. B. "C").
# - $threshold: Der Schwellenwert für freien Speicher in Prozent, bei dem das Skript aktiv wird.
# - $path: Der Pfad zu den Log-Dateien, die überprüft und ggf. gelöscht werden sollen.
# - $age: Das maximale Alter der Log-Dateien in Monaten. Ältere Dateien werden archiviert und gelöscht.
# - $archive_path: Der Pfad, in dem die archivierten Log-Dateien gespeichert werden.

$drive_letter = "C"  # Das Laufwerk, das überwacht werden soll
$threshold = 10      # Schwellenwert für den freien Speicher in Prozent
$path = "C:\Users\lcierzynski\Desktop\dev\vscode\powershell\clogs\Logs"  # Pfad zu den Logs, die überprüft werden sollen
$age = 0             # Maximales Alter der Logs in Monaten (ältere Logs werden automatisch gelöscht)
$archive_path = "C:\Users\lcierzynski\Desktop\dev\vscode\powershell\clogs\Logs"  # Zielpfad, wohin die Logs archiviert werden sollen

Write-Host

# Administratorrechte prüfen
$user = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not ($user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Warning "This script needs to be executed as an administrator."
    Write-Host
    exit
}

# Prüfen, ob der Path-Ordner existiert
if (-Not (Test-Path $path -PathType Container)) {
    Write-Warning "'$path' doesn't exist."
    Write-Host
    exit
}

# Prüfen, ob das Archive-Ordner existiert
if (-Not (Test-Path $archive_path -PathType Container)) {
    Write-Warning "'$archive_path' doesn't exist."
    Write-Host
    exit
}

# Validierung des Alters
if ($age -lt 0) {
    Write-Warning "The age must be a positive integer."
    Write-Host
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

$drive = Get-PSDrive -Name $drive_letter

$total_space = $drive.Used + $drive.Free
$free_space = $drive.Free

$free_percentage = ($free_space / $total_space) * 100

if ($free_percentage -lt $threshold) {
    # Log-Informationen ausgeben
    Write-Host -ForegroundColor Red "[!] Diskspace on $($drive_letter): $([math]::Round($free_percentage, 2))%"
    Write-Host -ForegroundColor Gray "---"
    Write-Host -ForegroundColor Cyan "[i] Path: $path"
    Write-Host -ForegroundColor Cyan "[i] Archive: $archive_path"
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

    # ZIP-Datei erstellen
    $zip_name = "Archived_Logs_{0:yyyy-MM-dd}.zip" -f (Get-Date)
    $zip_path = Join-Path -Path $archive_path -ChildPath $zip_name

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
        
            # Löschung der archivierten Logs
            foreach ($old_log in $old_logs) {
                Remove-Item $old_log.FullName -Force
            }
            if ($deleted_size_mb -gt 1024) {
                Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) deleted - $formatted_deleted_size_gb GB deleted"
            } else {
                Write-Host -ForegroundColor Green "[+] $old_logs_count log file(s) deleted - $formatted_deleted_size_mb MB deleted"
            }
        } else {
            Write-Host -ForegroundColor Red "[!] Archiving failed. Log files were not deleted."
        }
    } catch {
        Write-Host -ForegroundColor Yellow "[i] An error occurred during archiving: $_"
        Write-Host -ForegroundColor Red "[!] Log files were not deleted."
    }
    Write-Host
} else {
    Write-Host -ForegroundColor Green "[+] Diskspace on $($drive_letter): $([math]::Round($free_percentage, 2))%"
    Write-Host -ForegroundColor Gray "---"
    Write-Host -ForegroundColor Cyan "[i] Path: $path"
    Write-Host -ForegroundColor Cyan "[i] Archive: $archive_path"
    Write-Host -ForegroundColor Gray "---"
    if ($total_size_mb -gt 1024) {
        Write-Host -ForegroundColor Green "[+] $log_files_count log file(s) found - $formatted_total_size_gb GB"
    } else {
        Write-Host -ForegroundColor Green "[+] $log_files_count log file(s) found - $formatted_total_size_mb MB"
    }
}
Write-Host
