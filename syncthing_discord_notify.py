#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


CONFIG_PATH = os.environ.get(
    "SYNCTHING_CONFIG_PATH",
    os.path.expanduser("~/.local/state/syncthing/config.xml"),
)
STATE_PATH = os.environ.get(
    "SYNCTHING_STATE_PATH",
    os.path.expanduser("~/.local/state/syncthing/discord-notify-state.json"),
)
LOG_PATH = os.environ.get(
    "SYNCTHING_LOG_PATH",
    os.path.expanduser("~/.local/state/syncthing/discord-notify.log"),
)
WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL", "").strip()
EVENT_TYPES = "ItemFinished"
POLL_TIMEOUT = 60


def log(message: str) -> None:
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a", encoding="utf-8") as handle:
        handle.write(f"{stamp} {message}\n")


def folder_filter() -> set[str]:
    raw = os.environ.get("SYNCTHING_FOLDER_FILTER", "").strip()
    if not raw:
        return set()
    return {item.strip() for item in raw.split(",") if item.strip()}


def load_syncthing_config() -> tuple[str, str]:
    root = ET.parse(CONFIG_PATH).getroot()
    gui = root.find("gui")
    if gui is None:
        raise RuntimeError("missing <gui> in Syncthing config")

    address = gui.findtext("address", default="127.0.0.1:8384").strip()
    apikey = gui.findtext("apikey", default="").strip()
    if not apikey:
        raise RuntimeError("missing Syncthing GUI API key")
    return address, apikey


def load_state() -> int:
    try:
        with open(STATE_PATH, "r", encoding="utf-8") as handle:
            return int(json.load(handle).get("last_event_id", 0))
    except FileNotFoundError:
        return 0
    except Exception as exc:
        log(f"state load failed: {exc}")
        return 0


def save_state(last_event_id: int) -> None:
    tmp_path = f"{STATE_PATH}.tmp"
    with open(tmp_path, "w", encoding="utf-8") as handle:
        json.dump({"last_event_id": last_event_id}, handle)
    os.replace(tmp_path, STATE_PATH)


def request_json(url: str, headers: dict[str, str], data: bytes | None = None) -> object:
    req = urllib.request.Request(url, headers=headers, data=data)
    with urllib.request.urlopen(req, timeout=POLL_TIMEOUT + 10) as response:
        return json.loads(response.read().decode("utf-8"))


def fetch_events(base_url: str, headers: dict[str, str], since: int) -> list[dict]:
    query = urllib.parse.urlencode(
        {
            "since": since,
            "timeout": POLL_TIMEOUT,
            "events": EVENT_TYPES,
        }
    )
    result = request_json(f"{base_url}/rest/events?{query}", headers)
    if not isinstance(result, list):
        raise RuntimeError("unexpected event payload")
    return result


def send_discord_notification(path: str) -> None:
    if not WEBHOOK_URL:
        raise RuntimeError("DISCORD_WEBHOOK_URL is required")

    payload = json.dumps({"content": f"Sync: {path}"})
    subprocess.run(
        [
            "curl",
            "--silent",
            "--show-error",
            "--fail",
            "-H",
            "Content-Type: application/json",
            "-d",
            payload,
            WEBHOOK_URL,
        ],
        check=True,
        timeout=POLL_TIMEOUT + 10,
    )


def should_notify(event: dict, folders: set[str]) -> bool:
    if event.get("type") != "ItemFinished":
        return False

    data = event.get("data") or {}
    if data.get("error") not in (None, ""):
        return False
    if data.get("type") != "file":
        return False
    if folders and data.get("folder") not in folders:
        return False
    return data.get("action") in {"update", "metadata", "delete"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true", help="send a sample Discord notification and exit")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    base_address, apikey = load_syncthing_config()
    folders = folder_filter()
    base_url = base_address if base_address.startswith(("http://", "https://")) else f"http://{base_address}"
    headers = {"X-API-Key": apikey, "Authorization": f"Bearer {apikey}"}

    if args.test:
        send_discord_notification("test-notification.txt")
        log("sent test notification")
        return 0

    last_event_id = load_state()
    log(f"notifier started for {base_url}, since={last_event_id}")

    while True:
        try:
            for event in fetch_events(base_url, headers, last_event_id):
                event_id = int(event.get("id", last_event_id))
                last_event_id = max(last_event_id, event_id)
                if should_notify(event, folders):
                    item = event["data"]["item"]
                    send_discord_notification(item)
                    log(f"notified {item}")
            save_state(last_event_id)
        except KeyboardInterrupt:
            log("notifier stopped")
            return 0
        except urllib.error.HTTPError as exc:
            log(f"http error {exc.code}: {exc.reason}")
            time.sleep(10)
        except urllib.error.URLError as exc:
            log(f"url error: {exc.reason}")
            time.sleep(10)
        except Exception as exc:
            log(f"unexpected error: {exc}")
            time.sleep(10)


if __name__ == "__main__":
    sys.exit(main())
