#!/usr/bin/env python3
"""
Fetches the latest glucose reading from LibreLinkUp.

Uses the community-maintained `libre-linkup-py` package rather than
hand-rolled HTTP calls — LibreLinkUp is an unofficial, reverse-engineered
API, and this library tracks upstream changes for you.

Install:
    pip install libre-linkup-py pydantic

Credentials are read from environment variables, expected to be set in
~/.config/tmux/.env (sourced by this script, not stored anywhere else):
    LIBRE_LINK_UP_USERNAME=you@example.com
    LIBRE_LINK_UP_PASSWORD=your-librelinkup-password
    LIBRE_LINK_UP_URL=https://api-eu2.libreview.io   # region-specific, see README

Outputs: "<value>|<trend-arrow>" on success, "--|" on failure.
Never prints stack traces to stdout — errors go to stderr so tmux's
status bar doesn't fill up with a traceback.
"""

import os
import sys
from pathlib import Path

ENV_FILE = Path.home() / ".config" / "tmux" / ".env"

TREND_ARROWS = {
    1: "  ",  # "⇊",  # falling quickly
    2: "  ",  # "↓",  # falling
    3: "  ",  # "→",  # stable
    4: "  ",  # "↑",  # rising
    5: "  ",  # "⇈",  # rising quickly
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


def main() -> int:
    load_env_file(ENV_FILE)

    username = os.environ.get("LIBRE_LINK_UP_USERNAME")
    password = os.environ.get("LIBRE_LINK_UP_PASSWORD")
    url = os.environ.get("LIBRE_LINK_UP_URL", "https://api.libreview.io")

    if not username or not password:
        print("Missing LIBRE_LINK_UP_USERNAME/PASSWORD", file=sys.stderr)
        print("--|")
        return 1

    try:
        from libre_link_up import LibreLinkUpClient
    except ImportError as exc:
        # Print the real exception — a missing transitive dep (e.g. pydantic)
        # shows up here too, and "not installed" would be misleading.
        print(f"libre-linkup-py import failed: {exc}", file=sys.stderr)
        print("--|")
        return 1

    try:
        client = LibreLinkUpClient(username=username, password=password, url=url)
        client.login()

        measurement = client.get_raw_graph_readings()["data"]["connection"][
            "glucoseMeasurement"
        ]

        value = measurement["ValueInMgPerDl"]
        trend_num = measurement.get("TrendArrow") or 3

        arrow = TREND_ARROWS.get(int(trend_num), "→")
        print(f"{int(value)}|{arrow}")
        return 0
    except Exception as exc:  # noqa: BLE001 — deliberately broad, this feeds a status bar
        print(f"LibreLinkUp fetch failed: {exc}", file=sys.stderr)
        print("--|")
        return 1


if __name__ == "__main__":
    sys.exit(main())
