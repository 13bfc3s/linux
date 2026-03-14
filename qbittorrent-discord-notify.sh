#!/usr/bin/env bash
set -euo pipefail

webhook_url=${DISCORD_WEBHOOK_URL:-}
if [[ -z "$webhook_url" ]]; then
  echo "DISCORD_WEBHOOK_URL is required" >&2
  exit 1
fi

name=${1:-}
category=${2:-}
tags=${3:-}
content_path=${4:-}
root_path=${5:-}
save_path=${6:-}
file_count=${7:-}
size_bytes=${8:-}
tracker=${9:-}
info_hash_v1=${10:-}
info_hash_v2=${11:-}
torrent_id=${12:-}

json=$(python3 - "$name" "$category" "$tags" "$content_path" "$root_path" "$save_path" "$file_count" "$size_bytes" "$tracker" "$info_hash_v1" "$info_hash_v2" "$torrent_id" <<'PY'
import json
import sys

(
    name,
    category,
    tags,
    content_path,
    root_path,
    save_path,
    file_count,
    size_bytes,
    tracker,
    info_hash_v1,
    info_hash_v2,
    torrent_id,
) = sys.argv[1:]

content = (
    f"Torrent done: {name}\n"
    f"Category: {category or '-'}\n"
    f"Tags: {tags or '-'}\n"
    f"Save path: {save_path}\n"
    f"Content path: {content_path}\n"
    f"Root path: {root_path}\n"
    f"Files: {file_count} Size: {size_bytes}\n"
    f"Tracker: {tracker or '-'}\n"
    f"Hash v1: {info_hash_v1 or '-'}\n"
    f"Hash v2: {info_hash_v2 or '-'}\n"
    f"Torrent ID: {torrent_id}"
)

print(json.dumps({"content": content}))
PY
)

curl --silent --show-error --fail \
  -H 'Content-Type: application/json' \
  -d "$json" \
  "$webhook_url" >/dev/null
