"""版本号单一真身的一致性校验。

`extensions/manifest.json` 的 `version` 字段是版本号唯一真身（浏览器扩展商店展示）；
`pyproject.toml` 的 `[project].version` 是派生镜像，本用例强校验二者一致。
"""

from __future__ import annotations

import json
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[1]


def test_pyproject_version_matches_manifest_version() -> None:
    """pyproject.toml 的版本镜像必须与扩展清单 manifest.json 同值。"""
    pyproject = tomllib.loads((ROOT / "pyproject.toml").read_text(encoding="utf-8"))
    manifest = json.loads((ROOT / "extensions" / "manifest.json").read_text(encoding="utf-8"))
    assert pyproject["project"]["version"] == manifest["version"]
