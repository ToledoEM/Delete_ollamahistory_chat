# Ollama GUI chat-history wipe script (Windows)
# Deletes ONLY chat data (chats/messages/tool_calls/attachments)
# Keeps settings, users, models intact
# Optional backup (default: no backup)
#
# Usage:
#   .\ollama_chat_deleter.ps1
#   $env:OLLAMA_DB = "C:\path\to\db.sqlite"; .\ollama_chat_deleter.ps1
#   $env:OLLAMA_BACKUP = "yes";              .\ollama_chat_deleter.ps1

$ErrorActionPreference = "Stop"

function Get-DefaultDbPath {
    $candidates = @(
        "$env:APPDATA\Ollama\db.sqlite",
        "$env:LOCALAPPDATA\Ollama\db.sqlite"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c -PathType Leaf) { return $c }
    }
    return $candidates[0]
}

function Write-Log { param([string]$msg) Write-Host $msg }

function Should-CreateBackup {
    $choice = $env:OLLAMA_BACKUP
    if ($choice) {
        switch ($choice.ToLower()) {
            { $_ -in "1","y","yes","true" } { return $true }
            { $_ -in "0","n","no","false" } { return $false }
            default {
                Write-Log "ERROR: OLLAMA_BACKUP must be one of: 1,0,yes,no,true,false"
                exit 1
            }
        }
    }

    # Interactive prompt
    $answer = Read-Host "Create DB backup before deleting chats? [y/N]"
    return ($answer.ToLower() -in "y","yes")
}

# ---- Resolve DB path ----
$DB = if ($env:OLLAMA_DB) { $env:OLLAMA_DB } else { Get-DefaultDbPath }

if ([string]::IsNullOrWhiteSpace($DB)) {
    Write-Log "ERROR: database path is empty."
    exit 1
}

Write-Log "Using DB path: $DB"

# ---- Check DB exists ----
if (-not (Test-Path $DB -PathType Leaf)) {
    Write-Log "ERROR: db not found: $DB"
    Write-Log "If your db is elsewhere, run like:"
    Write-Log '  $env:OLLAMA_DB = "C:\full\path\to\db.sqlite"; .\ollama_chat_deleter.ps1'
    exit 1
}

# ---- Check sqlite3 installed ----
if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
    Write-Host "sqlite3 not found."
    Write-Host ""
    Write-Host "Install sqlite3 with:"
    Write-Host "  winget install SQLite.SQLite"
    Write-Host "  OR download from https://sqlite.org/download.html"
    Write-Host "  and add sqlite3.exe to your PATH."
    exit 1
}

# ---- Stop Ollama process ----
$ollamaProcs = Get-Process -Name "ollama","Ollama" -ErrorAction SilentlyContinue
if ($ollamaProcs) {
    Write-Log "Stopping Ollama..."
    $ollamaProcs | Stop-Process -Force
    Start-Sleep -Seconds 1
}

# ---- Optional backup ----
if (Should-CreateBackup) {
    $ts  = (Get-Date -Format "yyyyMMdd-HHmmss")
    $bak = "$DB.bak.$ts"
    Copy-Item $DB $bak
    Write-Log "Backup created: $bak"
} else {
    Write-Log "Skipping backup (default)."
}

# ---- Validate expected tables ----
$tables = sqlite3 $DB "SELECT name FROM sqlite_master WHERE type='table';"

foreach ($t in @("chats","messages","tool_calls","attachments")) {
    if ($tables -notcontains $t) {
        Write-Log "ERROR: expected table '$t' not found."
        Write-Log "Tables present: $($tables -join ', ')"
        exit 1
    }
}

# ---- Delete chat history ----
$sql = @"
PRAGMA foreign_keys=ON;
BEGIN IMMEDIATE;
DELETE FROM attachments;
DELETE FROM tool_calls;
DELETE FROM messages;
DELETE FROM chats;
COMMIT;
"@

try {
    $sql | sqlite3 $DB
} catch {
    Write-Log "WARN: strict delete failed; retrying compatibility delete."
    @"
DELETE FROM attachments;
DELETE FROM tool_calls;
DELETE FROM messages;
DELETE FROM chats;
"@ | sqlite3 $DB
}

sqlite3 $DB "VACUUM;"

# ---- Clean WAL/SHM files if present ----
foreach ($ext in "-wal","-shm") {
    $f = "$DB$ext"
    if (Test-Path $f) { Remove-Item $f -Force }
}

Write-Log "Done. Chat history wiped from: $DB"
