#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${OLLAMA_LOG_DIR:-$HOME/.ollama/logs}"

if [[ ! -d "$LOG_DIR" ]]; then
  echo "Log directory not found: $LOG_DIR" >&2
  exit 1
fi

# Nothing to do if log dir is already empty.
if ! find "$LOG_DIR" -mindepth 1 -print -quit | grep -q .; then
  echo "No log files to delete in: $LOG_DIR"
  exit 0
fi

echo "Files/directories that will be deleted:"
find "$LOG_DIR" -mindepth 1 -print
echo

printf "Delete all items above? [y/N]: "
if ! read -r answer; then
  answer=""
fi

answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
case "$answer" in
  y|yes)
    find "$LOG_DIR" -mindepth 1 -delete
    echo "Deleted Ollama logs in: $LOG_DIR"
    ;;
  *)
    echo "Cancelled. No files were deleted."
    ;;
esac
