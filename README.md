# linux

.bash_aliases

- just some workspace prepping.. don't forget to `source ~/.bashrc` after installation
- source secrets from `~/.bash_secrets` if present
- modern-tool aware: uses `rg`, `bat`, `eza`/`exa`, `zoxide`, `fzf`, and `direnv` when installed
- add your private values to `~/.bash_secrets` and do not commit that file

.
.
.

syncthing_discord_notify.py

- polls Syncthing `ItemFinished` events and posts `Sync: <path>` to Discord
- requires `DISCORD_WEBHOOK_URL`
- optional: `SYNCTHING_FOLDER_FILTER=<folder-id>[,<folder-id>...]`
- optional: `SYNCTHING_CONFIG_PATH`, `SYNCTHING_STATE_PATH`, `SYNCTHING_LOG_PATH`
- supports `--test`

qbittorrent-discord-notify.sh

- qBittorrent "run external program on torrent finished" hook
- requires `DISCORD_WEBHOOK_URL`
- recommended command:
  `/path/to/qbittorrent-discord-notify.sh "%N" "%L" "%G" "%F" "%R" "%D" "%C" "%Z" "%T" "%I" "%J" "%K"`
