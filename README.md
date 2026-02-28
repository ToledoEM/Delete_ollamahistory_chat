# Ollama chat history cleaner

I made these scripts to clean only the chat history and the logs from Ollama GUI and server.
It does not remove models, users, or app settings.

The script works on macOS and Linux.

On macOS it checks common Ollama database paths.
It also checks if `sqlite3` is installed and if the needed tables exist.

When you run it, it asks if you want a backup.
Default answer is **No**.

## Before and after

Before running the script:

![Before](img/before.png)

After running the script:

![After](img/after.png)

## How to run

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

## Delete Ollama logs

Use this script to delete files inside Ollama logs directory:

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
