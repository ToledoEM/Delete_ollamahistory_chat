# Ollama log directory wipe script (Windows)
#
# Usage:
#   .\ollama_logs_deleter.ps1
#   $env:OLLAMA_LOG_DIR = "C:\custom\log\path"; .\ollama_logs_deleter.ps1

$ErrorActionPreference = "Stop"

$LogDir = if ($env:OLLAMA_LOG_DIR) {
    $env:OLLAMA_LOG_DIR
} else {
    "$env:USERPROFILE\.ollama\logs"
}

if (-not (Test-Path $LogDir -PathType Container)) {
    Write-Host "Log directory not found: $LogDir" -ForegroundColor Red
    exit 1
}

$items = Get-ChildItem -Path $LogDir -Recurse -Force
if ($items.Count -eq 0) {
    Write-Host "No log files to delete in: $LogDir"
    exit 0
}

Write-Host "Files/directories that will be deleted:"
$items | ForEach-Object { Write-Host "  $($_.FullName)" }
Write-Host ""

$answer = Read-Host "Delete all items above? [y/N]"

if ($answer.ToLower() -in "y","yes") {
    # Remove children; leave the log directory itself intact
    Get-ChildItem -Path $LogDir -Force | Remove-Item -Recurse -Force
    Write-Host "Deleted Ollama logs in: $LogDir"
} else {
    Write-Host "Cancelled. No files were deleted."
}
