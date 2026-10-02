from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

MODULE_PATH = Path(__file__).resolve().parents[1] / "host" / "open_safari_host.py"
SPEC = importlib.util.spec_from_file_location("open_safari_host", MODULE_PATH)
assert SPEC and SPEC.loader
HOST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HOST)


@pytest.mark.parametrize(
    ("url", "expected"),
    [
        ("https://example.com", True),
        ("http://example.com/path?q=1", True),
        ("ftp://example.com", False),
        ("javascript:alert(1)", False),
        ("httpnotreally://example.com", False),
        ("", False),
        (None, False),
    ],
)
def test_is_allowed_url(url: str | None, expected: bool) -> None:
    assert HOST.is_allowed_url(url) is expected


def test_open_in_safari_reports_success(monkeypatch: pytest.MonkeyPatch) -> None:
    calls: list[list[str]] = []

    class CompletedProcess:
        returncode = 0

    def fake_run(command: list[str], check: bool, stdout: int, stderr: int):
        calls.append(command)
        return CompletedProcess()

    monkeypatch.setattr(HOST.subprocess, "run", fake_run)

    assert HOST.open_in_safari("https://example.com") == {
        "status": "success",
        "url": "https://example.com",
    }
    assert calls == [["/usr/bin/open", "-a", "Safari", "https://example.com"]]


def test_open_in_safari_reports_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    class CompletedProcess:
        returncode = 1

    def fake_run(command: list[str], check: bool, stdout: int, stderr: int):
        return CompletedProcess()

    monkeypatch.setattr(HOST.subprocess, "run", fake_run)

    assert HOST.open_in_safari("https://example.com") == {
        "status": "error",
        "error": "Failed to launch Safari",
    }


def test_handle_message_rejects_invalid_urls() -> None:
    assert HOST.handle_message({"url": "javascript:alert(1)"}) == {
        "status": "error",
        "error": "Invalid or unsafe URL protocol",
    }
