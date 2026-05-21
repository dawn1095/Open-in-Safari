#!/usr/bin/python3
from __future__ import annotations

import json
import struct
import subprocess
import sys
from typing import Any
from urllib.parse import urlparse


def read_bytes(count: int) -> bytes:
    """Read an exact number of bytes from stdin unless EOF is reached."""
    bytes_read = 0
    buffer = b""
    while bytes_read < count:
        chunk = sys.stdin.buffer.read(count - bytes_read)
        if not chunk:
            break
        buffer += chunk
        bytes_read += len(chunk)
    return buffer


def get_message() -> dict[str, Any]:
    """Read a single native messaging payload from stdin."""
    raw_length = read_bytes(4)
    if len(raw_length) != 4:
        sys.exit(0)
    message_length = struct.unpack("=I", raw_length)[0]
    message_data = read_bytes(message_length)
    if len(message_data) != message_length:
        sys.exit(0)
    message = message_data.decode("utf-8")
    return json.loads(message)


def send_message(message_content: dict[str, Any]) -> None:
    """Write a native messaging payload to stdout."""
    content = json.dumps(message_content).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("=I", len(content)))
    sys.stdout.buffer.write(content)
    sys.stdout.buffer.flush()


def is_allowed_url(url: str | None) -> bool:
    if not isinstance(url, str) or not url:
        return False
    if url != url.strip() or any(char.isspace() for char in url):
        return False

    parsed = urlparse(url)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def open_in_safari(url: str) -> dict[str, str]:
    result = subprocess.run(
        ["/usr/bin/open", "-a", "Safari", url],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode == 0:
        return {"status": "success", "url": url}
    return {"status": "error", "error": "Failed to launch Safari"}


def handle_message(message: dict[str, Any]) -> dict[str, str]:
    url = message.get("url")
    if not is_allowed_url(url):
        return {"status": "error", "error": "Invalid or unsafe URL protocol"}
    return open_in_safari(url)


def main() -> None:
    try:
        send_message(handle_message(get_message()))
    except Exception as e:
        send_message({"status": "error", "error": str(e)})


if __name__ == "__main__":
    main()
