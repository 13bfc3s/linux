#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

### -- CONFIGS -----------------------------------------------------------------
SSH_USER="{REDACTED}"
SSH_HOST="{REDACTED}"
REMOTE_DIR="{REDACTED}"
LOCAL_DIR="{REDACTED}"
DISCORD_WEBHOOK="{REDACTED}"
LOG_FILE="./.log"
LOCK_FILE="./.lock"
### ----------------------------------------------------------------------------

# make log dir
mkdir -p "$(dirname "$LOG_FILE")"

# set lock
if [[ -e "$LOCK_FILE" ]]; then
  echo "Sync already running. Exiting."
  exit 1
else
  : > "$LOCK_FILE"
fi

cleanup() {
  rm -f "$LOCK_FILE"
}
trap cleanup EXIT

send_discord_notification() {
  local message="$1"
  curl -s -H "Content-Type: application/json" \
       -X POST -d "{\"content\": \"${message}\"}" \
       "$DISCORD_WEBHOOK" >/dev/null 2>&1
}

: > "$LOG_FILE"

# rsync for legal torrenting
rsync_exit=0
rsync -avh --ignore-existing \
  --exclude='temp/' \
  --exclude='qbittorrent/' \
  --exclude='*.!qb' \
  --exclude='*.parts' \
  -e ssh "${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}" "${LOCAL_DIR}" \
  >>"$LOG_FILE" 2>&1 || rsync_exit=$?

# grab file list
mapfile -t files < <(
  awk '
    /^receiving incremental file list/ { in_list=1; next }
    in_list && NF==0 { exit }
    in_list && !/\/$/ && !/^\./ {
      fname=$0; getline; fsize=$1; print fname "\t" fsize
    }
  ' "$LOG_FILE"
)

# grab summary
summary_line=$(grep -E '^sent [0-9]+ bytes +received' "$LOG_FILE" || true)
rec=""
speed=""
if [[ -n "$summary_line" ]]; then
  rec=$(echo "$summary_line" | sed -n 's/.*received \([0-9.]*[KMG] bytes\).*/\1/p')
  speed=$(echo "$summary_line" | sed -n 's/.*received [0-9.]*[KMG] bytes  \([0-9.]*[KMG] bytes\/sec\).*/\1/p')
fi

# send notification
final_msg="✅ Sync complete.\n"
if (( ${#files[@]} > 0 )); then
  final_msg+="Transferred files:\n"
  for line in "${files[@]}"; do
    IFS=$'\t' read -r fname fsize <<< "$line"
    final_msg+="• ${fname} (${fsize})\n"
  done
fi
if [[ -n "$rec" && -n "$speed" ]]; then
  final_msg+="Received ${rec} at ${speed}"
fi
# but not empty notifications
if [[ ${#files[@]} -gt 0 || -n "$rec" ]]; then
  send_discord_notification "$final_msg"
fi

exit "$rsync_exit"
