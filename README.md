# Windows Security Event Log Manager

A PowerShell script designed for Windows 10 IoT Core to automatically manage Security event logs by archiving and clearing them when they exceed a specified size threshold.

## Features

- **Size Monitoring**: Checks if Security event log exceeds 100MB (configurable)
- **Automatic Archiving**: Creates timestamped archives in a dedicated location
- **Clean Archive Management**: Clears existing archives before creating new ones
- **Automatic Log Clearing**: Clears the Security event log after successful archiving
- **Comprehensive Logging**: Detailed console output with timestamps
- **Error Handling**: Robust error handling with appropriate exit codes

## Files Included

- `manage-security-eventlogs.ps1` - Main PowerShell script
- `run-eventlog-manager.bat` - Batch file wrapper for easy execution
- `README.md` - This documentation file

## Requirements

- Windows 10 IoT Core (or compatible Windows version)
- Administrator privileges
- PowerShell 3.0 or later

## Usage

### Method 1: Using the Batch File (Recommended)

1. Right-click on `run-eventlog-manager.bat`
2. Select "Run as administrator"
3. Follow the on-screen prompts

### Method 2: Direct PowerShell Execution

1. Open PowerShell as Administrator
2. Navigate to the script directory
3. Run: `.\manage-security-eventlogs.ps1`

### Method 3: PowerShell with Custom Parameters

```powershell
# Custom archive location and size threshold
.\manage-security-eventlogs.ps1 -ArchiveLocation "D:\LogArchives" -MaxSizeMB 50

# Using default settings (100MB threshold, C:\EventLogArchive)
.\manage-security-eventlogs.ps1
```

## Configuration Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `ArchiveLocation` | `C:\EventLogArchive` | Directory where archived logs will be stored |
| `MaxSizeMB` | `100` | Size threshold in MB that triggers archiving |

## How It Works

1. **Size Check**: Script checks the current size of the Security event log
2. **Threshold Evaluation**: If size exceeds the configured threshold (default 100MB):
   - Creates archive directory if it doesn't exist
   - Clears any existing Security_*.evtx files in the archive location
   - Exports current Security log to archive with timestamp (format: `Security_YYYYMMDD_HHMMSS.evtx`)
   - Clears the Security event log
   - Verifies the operation was successful
3. **No Action Required**: If size is within limits, script exits with success

## Archive File Naming

Archives are named using the following format:
- `Security_YYYYMMDD_HHMMSS.evtx`
- Example: `Security_20241220_143052.evtx`

## Exit Codes

- `0` - Success (log managed or no action required)
- `1` - Error (check console output for details)

## Logging Output

The script provides detailed console output including:
- Timestamp for each operation
- Current log sizes
- Archive operations status
- Error messages with context
- Final verification of operations

## Example Output

```
[2024-12-20 14:30:52] [INFO] Starting Security Event Log management script
[2024-12-20 14:30:52] [INFO] Target log: Security
[2024-12-20 14:30:52] [INFO] Size threshold: 100 MB
[2024-12-20 14:30:52] [INFO] Archive location: C:\EventLogArchive
[2024-12-20 14:30:52] [INFO] Current Security log size: 125.67 MB
[2024-12-20 14:30:52] [INFO] Security log size (125.67 MB) exceeds threshold (100 MB). Starting archive process...
[2024-12-20 14:30:52] [INFO] Created archive directory: C:\EventLogArchive
[2024-12-20 14:30:52] [INFO] No existing archive files to clear
[2024-12-20 14:30:55] [INFO] Successfully exported Security log to: C:\EventLogArchive\Security_20241220_143052.evtx (125.67 MB)
[2024-12-20 14:30:55] [INFO] Archive created successfully
[2024-12-20 14:30:56] [INFO] Security event log cleared successfully
[2024-12-20 14:30:56] [INFO] Security event log management completed successfully
[2024-12-20 14:30:58] [INFO] New Security log size after clearing: 0.02 MB
```

## Automation

### Task Scheduler Setup

To run this script automatically, create a Windows Task Scheduler task:

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., daily, weekly, or when log reaches certain size)
4. Set action to start the batch file with administrator privileges
5. Configure security settings to run with highest privileges

### Sample Task Scheduler Command

- **Program**: `C:\Windows\System32\cmd.exe`
- **Arguments**: `/c "C:\path\to\your\script\run-eventlog-manager.bat"`
- **Run with highest privileges**: Checked

## Troubleshooting

### Common Issues

1. **"Access Denied" Errors**
   - Ensure script is running with Administrator privileges
   - Check that the archive location is writable

2. **"Execution Policy" Errors**
   - The batch file handles this automatically
   - Alternatively, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

3. **"Event Log Not Found" Errors**
   - Verify that the Security event log exists and is accessible
   - Check Windows Event Log service is running

4. **Archive Location Issues**
   - Ensure the specified path is valid and accessible
   - Check disk space availability

### Log File Locations

On Windows 10 IoT Core, event log files are typically located at:
- `C:\Windows\System32\winevt\Logs\Security.evtx`

## Security Considerations

- Script requires Administrator privileges to access and modify event logs
- Archive files contain sensitive security information - secure appropriately
- Consider encryption for archive storage if required by your security policy
- Regularly review and clean old archive files as needed

## Support

This script is designed specifically for Windows 10 IoT Core environments. For other Windows versions, testing is recommended before production use.
