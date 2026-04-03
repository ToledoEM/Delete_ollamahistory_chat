# Ollama chat history cleaner

I made these scripts to clean only the chat history and the logs from Ollama GUI and server.
It does not remove models, users, or app settings.

Scripts are available for **macOS**, **Linux**, and **Windows** (untested :-/ ).

On macOS and Windows it checks common Ollama database paths automatically.
It also checks if `sqlite3` is installed and if the needed tables exist.

When you run it, it asks if you want a backup.
Default answer is **No**.

## Before and after

Before running the script:

![Before](img/before.png)

After running the script:

![After](img/after.png)

---

## macOS and Linux

### Install sqlite3

**macOS:**
```bash
brew install sqlite
```

**Debian / Ubuntu:**
```bash
sudo apt update && sudo apt install -y sqlite3
```

**Fedora:**
```bash
sudo dnf install -y sqlite
```

**Arch:**
```bash
sudo pacman -S sqlite
```

### How to run

```bash
chmod +x ./ollama_chat_deleter.sh
./ollama_chat_deleter.sh
```

If your DB is in another place, pass it like this:

```bash
OLLAMA_DB="/full/path/to/db.sqlite" ./ollama_chat_deleter.sh
```

If you do not want the backup question, you can force it:

```bash
OLLAMA_BACKUP=no ./ollama_chat_deleter.sh
```

or:

```bash
OLLAMA_BACKUP=yes ./ollama_chat_deleter.sh
```

### Delete Ollama logs

```bash
chmod +x ./ollama_logs_deleter.sh
./ollama_logs_deleter.sh
```

By default it uses:

```bash
$HOME/.ollama/logs
```

Before deleting, it prints all files/directories that will be removed and asks:

```text
Delete all items above? [y/N]:
```

Only `y` or `yes` will continue. Any other answer cancels the delete.

If your logs path is different, use:

```bash
OLLAMA_LOG_DIR="/full/path/to/logs" ./ollama_logs_deleter.sh
```

---

## Windows

### Install sqlite3

**Option 1 — winget (recommended):**

Open PowerShell and run:

```powershell
winget install SQLite.SQLite
```

After install, close and reopen PowerShell so `sqlite3` is on your PATH.

**Option 2 — manual:**

1. Go to https://sqlite.org/download.html
2. Under *Precompiled Binaries for Windows*, download `sqlite-tools-win-x64-*.zip`
3. Extract `sqlite3.exe` to a folder like `C:\tools\sqlite3\`
4. Add that folder to your PATH:
   - Open **Start** → search *Environment Variables*
   - Edit *Path* under *User variables*
   - Add the folder path and click OK
5. Reopen PowerShell and verify: `sqlite3 --version`

### Allow PowerShell scripts to run

Windows blocks unsigned scripts by default. Run this once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### How to run

```powershell
.\ollama_chat_deleter.ps1
```

The script looks for the database in these locations and uses the first one it finds:

- `%APPDATA%\Ollama\db.sqlite`
- `%LOCALAPPDATA%\Ollama\db.sqlite`

If your DB is somewhere else:

```powershell
$env:OLLAMA_DB = "C:\full\path\to\db.sqlite"
.\ollama_chat_deleter.ps1
```

To skip the backup prompt:

```powershell
$env:OLLAMA_BACKUP = "no"
.\ollama_chat_deleter.ps1
```

or:

```powershell
$env:OLLAMA_BACKUP = "yes"
.\ollama_chat_deleter.ps1
```

### Delete Ollama logs (Windows)

```powershell
.\ollama_logs_deleter.ps1
```

By default it uses:

```text
%USERPROFILE%\.ollama\logs
```

If your logs path is different:

```powershell
$env:OLLAMA_LOG_DIR = "C:\custom\log\path"
.\ollama_logs_deleter.ps1
```
