#!/usr/bin/env bash
set -euo pipefail

# Ollama GUI chat-history wipe script (macOS + Linux)
# Deletes ONLY chat data (chats/messages/tool_calls/attachments)
# Keeps settings, users, models intact
# Optional backup (default: no backup)
# script commented by GPT5.3-Codex

# Detect runtime OS once and reuse it.
OS="$(uname -s)"

default_db_path() {
  case "$OS" in
    Darwin)
      # Prefer known macOS desktop paths; use the first existing one.
      local candidates=(
        "$HOME/Library/Application Support/Ollama/db.sqlite"
        "$HOME/Library/Containers/com.ollama.app/Data/Library/Application Support/Ollama/db.sqlite"
      )
      local c
      for c in "${candidates[@]}"; do
        if [[ -f "$c" ]]; then
          printf '%s\n' "$c"
          return 0
        fi
      done
      # Fall back to the primary documented path.
      printf '%s\n' "${candidates[0]}"
      ;;
    Linux)
      printf '%s\n' "$HOME/.local/share/Ollama/db.sqlite"
      ;;
    *)
      printf '%s\n' "$HOME/Library/Application Support/Ollama/db.sqlite"
      ;;
  esac
}

# Resolve DB path from env override or OS default.
DB="${OLLAMA_DB:-$(default_db_path)}"

# Log helper writes to stderr for visibility.
log() { printf '%s\n' "$*" >&2; }

should_create_backup() {
  # OLLAMA_BACKUP lets automation skip interactive prompt.
  local choice="${OLLAMA_BACKUP:-}"
  local normalized=""

  if [[ -n "$choice" ]]; then
    # Normalize input so Yes/YES/yes work the same.
    normalized="$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')"
    case "$normalized" in
      1|y|yes|true)
        return 0
        ;;
      0|n|no|false)
        return 1
        ;;
      *)
        log "ERROR: OLLAMA_BACKUP must be one of: 1,0,yes,no,true,false"
        exit 1
        ;;
    esac
  fi

  # Ask only when stdin is interactive.
  if [[ -t 0 ]]; then
    local answer
    printf 'Create DB backup before deleting chats? [y/N]: ' >&2
    if ! read -r answer; then
      answer=""
    fi
    normalized="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
    case "$normalized" in
      y|yes) return 0 ;;
      *) return 1 ;;
    esac
  fi

  # Non-interactive mode defaults to no backup.
  return 1
}

# ---- Validate DB path ----
if [[ -z "${DB// }" ]]; then
  log "ERROR: database path is empty."
  exit 1
fi

log "OS detected: $OS"
log "Using DB path: $DB"

# ---- Check DB exists ----
if [[ ! -f "$DB" ]]; then
  log "ERROR: db not found: $DB"
  log "If your db is elsewhere, run like:"
  log "  OLLAMA_DB=\"/full/path/to/db.sqlite\" $0"
  exit 1
fi

# ---- Check sqlite3 installed ----
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found."
  echo
  echo "Install sqlite3 with:"
  echo "  macOS  : brew install sqlite"
  echo "  Debian : sudo apt update && sudo apt install -y sqlite3"
  echo "  Ubuntu : sudo apt update && sudo apt install -y sqlite3"
  echo "  Fedora : sudo dnf install -y sqlite"
  echo "  Arch   : sudo pacman -S sqlite"
  exit 1
fi

# ---- Quit Ollama safely ----
# Ignore stop errors if Ollama is already closed.
if [[ "$OS" == "Darwin" ]] && command -v osascript >/dev/null 2>&1; then
  osascript -e 'quit app "Ollama"' >/dev/null 2>&1 || true
  pkill -x Ollama >/dev/null 2>&1 || true
fi
pkill -x ollama >/dev/null 2>&1 || true

# ---- Optional backup DB ----
if should_create_backup; then
  ts="$(date +%Y%m%d-%H%M%S)"
  bak="${DB}.bak.${ts}"
  cp "$DB" "$bak"
  log "Backup created: $bak"
else
  log "Skipping backup (default)."
fi

# ---- Validate expected tables ----
# Read schema table names once before validation.
tables="$(sqlite3 "$DB" "SELECT name FROM sqlite_master WHERE type='table';")"

need_table() {
  local t="$1"
  if ! grep -qx "$t" <<<"$tables"; then
    log "ERROR: expected table '$t' not found."
    log "Tables present:"
    log "$tables"
    exit 1
  fi
}

for t in chats messages tool_calls attachments; do
  need_table "$t"
done

# ---- Delete chat history only ----
# Try strict transactional mode first; fall back to compatibility mode if needed.
if ! sqlite3 "$DB" <<'EOF'
PRAGMA foreign_keys=ON;
BEGIN IMMEDIATE;
DELETE FROM attachments;
DELETE FROM tool_calls;
DELETE FROM messages;
DELETE FROM chats;
COMMIT;
EOF
then
  log "WARN: strict delete failed; retrying compatibility delete."
  sqlite3 "$DB" <<'EOF'
DELETE FROM attachments;
DELETE FROM tool_calls;
DELETE FROM messages;
DELETE FROM chats;
EOF
fi

# Keep VACUUM separate for compatibility with more sqlite build/runtime combinations.
sqlite3 "$DB" "VACUUM;"

# ---- Clean WAL/SHM files if present ----
rm -f "${DB}-wal" "${DB}-shm" || true

log "Done. Chat history wiped from: $DB"
