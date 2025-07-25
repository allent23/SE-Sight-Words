#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Manages Windows Security Event Logs on Windows 10 IoT Core
    
.DESCRIPTION
    This script checks if the Security event log is over 100MB in size.
    If it is, it creates an archive location, clears any existing archive,
    copies the log with a timestamp, and then clears the Security event log.
    
.NOTES
    - Must be run as Administrator
    - Designed for Windows 10 IoT Core
    - Archives logs to C:\EventLogArchive by default
#>

param(
    [string]$ArchiveLocation = "C:\EventLogArchive",
    [int]$MaxSizeMB = 100
)

# Function to write log messages
function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Function to get event log file size
function Get-EventLogFileSize {
    param([string]$LogName)
    
    try {
        # Get the event log configuration
        $logConfig = Get-WinEvent -ListLog $LogName -ErrorAction Stop
        $logFilePath = $logConfig.LogFilePath
        
        if (Test-Path $logFilePath) {
            $fileInfo = Get-Item $logFilePath
            return [math]::Round($fileInfo.Length / 1MB, 2)
        } else {
            Write-LogMessage "Log file not found: $logFilePath" "WARNING"
            return 0
        }
    }
    catch {
        Write-LogMessage "Error getting log file size: $($_.Exception.Message)" "ERROR"
        return 0
    }
}

# Function to create archive directory
function New-ArchiveDirectory {
    param([string]$Path)
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-LogMessage "Created archive directory: $Path"
        } else {
            Write-LogMessage "Archive directory already exists: $Path"
        }
        return $true
    }
    catch {
        Write-LogMessage "Error creating archive directory: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to clear existing archive files
function Clear-ExistingArchive {
    param([string]$ArchivePath)
    
    try {
        $existingFiles = Get-ChildItem -Path $ArchivePath -Filter "Security_*.evtx" -ErrorAction SilentlyContinue
        if ($existingFiles) {
            Write-LogMessage "Clearing $($existingFiles.Count) existing archive file(s)"
            $existingFiles | Remove-Item -Force
            Write-LogMessage "Existing archive files cleared"
        } else {
            Write-LogMessage "No existing archive files to clear"
        }
        return $true
    }
    catch {
        Write-LogMessage "Error clearing existing archive: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to export event log
function Export-SecurityEventLog {
    param(
        [string]$DestinationPath,
        [string]$FileName
    )
    
    try {
        $fullPath = Join-Path $DestinationPath $FileName
        
        # Export the Security event log
        wevtutil epl Security $fullPath
        
        if (Test-Path $fullPath) {
            $archiveSize = [math]::Round((Get-Item $fullPath).Length / 1MB, 2)
            Write-LogMessage "Successfully exported Security log to: $fullPath ($archiveSize MB)"
            return $true
        } else {
            Write-LogMessage "Failed to create archive file" "ERROR"
            return $false
        }
    }
    catch {
        Write-LogMessage "Error exporting event log: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to clear Security event log
function Clear-SecurityEventLog {
    try {
        # Clear the Security event log
        wevtutil cl Security
        Write-LogMessage "Security event log cleared successfully"
        return $true
    }
    catch {
        Write-LogMessage "Error clearing Security event log: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main script execution
try {
    Write-LogMessage "Starting Security Event Log management script"
    Write-LogMessage "Target log: Security"
    Write-LogMessage "Size threshold: $MaxSizeMB MB"
    Write-LogMessage "Archive location: $ArchiveLocation"
    
    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-LogMessage "This script must be run as Administrator" "ERROR"
        exit 1
    }
    
    # Get current Security log size
    $currentSize = Get-EventLogFileSize -LogName "Security"
    Write-LogMessage "Current Security log size: $currentSize MB"
    
    if ($currentSize -gt $MaxSizeMB) {
        Write-LogMessage "Security log size ($currentSize MB) exceeds threshold ($MaxSizeMB MB). Starting archive process..."
        
        # Create archive directory
        if (-not (New-ArchiveDirectory -Path $ArchiveLocation)) {
            Write-LogMessage "Failed to create archive directory. Exiting." "ERROR"
            exit 1
        }
        
        # Clear existing archive files
        if (-not (Clear-ExistingArchive -ArchivePath $ArchiveLocation)) {
            Write-LogMessage "Failed to clear existing archive. Exiting." "ERROR"
            exit 1
        }
        
        # Generate timestamp for filename
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveFileName = "Security_$timestamp.evtx"
        
        # Export the Security event log
        if (Export-SecurityEventLog -DestinationPath $ArchiveLocation -FileName $archiveFileName) {
            Write-LogMessage "Archive created successfully"
            
            # Clear the Security event log
            if (Clear-SecurityEventLog) {
                Write-LogMessage "Security event log management completed successfully"
                
                # Verify the log was cleared
                Start-Sleep -Seconds 2
                $newSize = Get-EventLogFileSize -LogName "Security"
                Write-LogMessage "New Security log size after clearing: $newSize MB"
                
                exit 0
            } else {
                Write-LogMessage "Failed to clear Security event log" "ERROR"
                exit 1
            }
        } else {
            Write-LogMessage "Failed to create archive. Security log not cleared." "ERROR"
            exit 1
        }
    } else {
        Write-LogMessage "Security log size ($currentSize MB) is within acceptable limits. No action required."
        exit 0
    }
}
catch {
    Write-LogMessage "Unexpected error: $($_.Exception.Message)" "ERROR"
    exit 1
}