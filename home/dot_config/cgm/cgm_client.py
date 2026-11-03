#!/usr/bin/env python3
"""Fetch and cache neutral CGM data from LibreLinkUp.

Credentials are loaded from ~/.config/cgm/.env. The command always emits one
JSON object so status-bar adapters can fail closed without parsing tracebacks.
"""

from __future__ import annotations

import fcntl
import json
import os
import sys
import tempfile
import time
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

CONFIG_DIR = Path.home() / ".config" / "cgm"
ENV_FILE = CONFIG_DIR / ".env"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "cgm"
CACHE_FILE = CACHE_DIR / "latest.json"
LOCK_FILE = CACHE_DIR / "refresh.lock"

CACHE_TTL = 55
FAILURE_TTL = 15
STALE_AFTER = 10 * 60  # sensor age; LibreLinkUp normally updates every minute
HTTP_TIMEOUT = (5, 10)  # connect, read

TREND_ARROWS = {
    1: "",  # falling quickly
    2: "",  # falling
    3: "",  # stable
    4: "",  # rising
    5: "",  # rising quickly
}


def load_env_file(path: Path) -> None:
    if not path.exists():
        return

    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def classify(value: int) -> str:
    if value < 70 or value > 180:
        return "critical"
    if value < 80 or value > 160:
        return "warning"
    return "normal"


def unavailable(now: int, error: str | None = None) -> dict[str, Any]:
    result: dict[str, Any] = {
        "available": False,
        "value": None,
        "trend": "",
        "severity": "unavailable",
        "unit": "mg/dL",
        "fetched_at": now,
    }
    if error:
        result["error"] = error
    return result


def read_cache() -> dict[str, Any] | None:
    try:
        data = json.loads(CACHE_FILE.read_text())
        return data if isinstance(data, dict) else None
    except (OSError, json.JSONDecodeError):
        return None


def is_fresh(data: dict[str, Any] | None, now: int) -> bool:
    if not data:
        return False

    fetched_at = data.get("fetched_at")
    if not isinstance(fetched_at, int):
        return False

    age = now - fetched_at
    ttl = FAILURE_TTL if data.get("error") else CACHE_TTL
    return 0 <= age < ttl


def write_cache(data: dict[str, Any]) -> None:
    CACHE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        CACHE_DIR.chmod(0o700)
    except OSError:
        pass

    fd, temporary_name = tempfile.mkstemp(prefix="latest.", dir=CACHE_DIR)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as temporary:
            json.dump(data, temporary, ensure_ascii=False, separators=(",", ":"))
            temporary.write("\n")
        os.replace(temporary_name, CACHE_FILE)
    finally:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass


def fetch() -> dict[str, Any]:
    load_env_file(ENV_FILE)

    username = os.environ.get("LIBRE_LINK_UP_USERNAME")
    password = os.environ.get("LIBRE_LINK_UP_PASSWORD")
    url = os.environ.get("LIBRE_LINK_UP_URL", "https://api.libreview.io")

    if not username or not password:
        raise RuntimeError("missing LIBRE_LINK_UP_USERNAME/PASSWORD")

    import requests
    from libre_link_up import LibreLinkUpClient

    # libre-linkup-py does not currently expose a timeout and calls requests
    # directly. Bound all of its HTTP calls so a status-bar refresh cannot hold
    # the cache lock forever.
    original_request = requests.sessions.Session.request

    def request_with_timeout(
        session: requests.Session, method: str, url: str, **kwargs: Any
    ) -> requests.Response:
        kwargs.setdefault("timeout", HTTP_TIMEOUT)
        return original_request(session, method, url, **kwargs)

    requests.sessions.Session.request = request_with_timeout
    try:
        client = LibreLinkUpClient(username=username, password=password, url=url)
        client.login()
        measurement = client.get_raw_graph_readings()["data"]["connection"][
            "glucoseMeasurement"
        ]
    finally:
        requests.sessions.Session.request = original_request

    value = int(measurement["ValueInMgPerDl"])
    try:
        # FactoryTimestamp is UTC; Timestamp is phone-local.
        measured_at = int(
            datetime.strptime(measurement["FactoryTimestamp"], "%m/%d/%Y %I:%M:%S %p")
            .replace(tzinfo=UTC)
            .timestamp()
        )
    except (KeyError, TypeError, ValueError):
        measured_at = None  # unknown age is shown as stale

    return {
        "available": True,
        "value": value,
        "trend": TREND_ARROWS.get(measurement.get("TrendArrow"), "?"),
        "severity": classify(value),
        "unit": "mg/dL",
        "measured_at": measured_at,
    }


def emit(data: dict[str, Any]) -> None:
    # Age is computed at display time so cached readings keep ageing.
    if data.get("available") is True:
        measured_at = data.get("measured_at")
        age = int(time.time()) - measured_at if isinstance(measured_at, int) else None
        stale = age is None or not -60 <= age <= STALE_AFTER
        text = f"{data['value']} {data['trend']}"
        if stale:
            text += f" {age // 60 if age is not None else '?'}m"
        data = {**data, "text": text, "severity": "stale" if stale else data["severity"]}
    print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))


def main() -> int:
    now = int(time.time())
    cached = read_cache()
    if is_fresh(cached, now):
        emit(cached)
        return 0

    CACHE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    with LOCK_FILE.open("a+") as lock:
        try:
            LOCK_FILE.chmod(0o600)
        except OSError:
            pass
        try:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            # Another status-bar process is refreshing. Never queue behind it;
            # emit() marks an old reading as stale.
            if cached is not None and cached.get("available") is True:
                emit(cached)
            else:
                emit(unavailable(now, "refresh in progress"))
            return 0

        # Another consumer may have refreshed before we acquired the lock.
        now = int(time.time())
        cached = read_cache()
        if is_fresh(cached, now):
            emit(cached)
            return 0

        try:
            result = fetch()
        except Exception as exc:  # noqa: BLE001 - status bars must fail closed
            print(f"CGM refresh failed: {exc}", file=sys.stderr)
            # Keep the last reading; emit() marks it stale once it is old.
            if cached is not None and cached.get("available") is True:
                result = {**cached, "error": str(exc)}
            else:
                result = unavailable(now, str(exc))
        # Start the cooldown when the request ends, not when it began.
        result["fetched_at"] = int(time.time())

        try:
            write_cache(result)
        except OSError as exc:
            print(f"CGM cache write failed: {exc}", file=sys.stderr)

        emit(result)
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
