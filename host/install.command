#!/usr/bin/env bash
set -Eeuo pipefail

# === Open in Safari 扩展本地主机一键安装脚本 (macOS) ===
echo "======================================"
echo "    Open in Safari 本地安装程序"
echo "======================================"
echo ""

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

cleanup() {
    if [[ -n "${GENERATED_MANIFEST:-}" && -f "${GENERATED_MANIFEST}" ]]; then
        rm -f "${GENERATED_MANIFEST}"
    fi
}

trap cleanup EXIT

error() {
    echo "❌ 错误：$1" >&2
    exit 1
}

# 1. 获取当前脚本所在的绝对路径
DIR="$SCRIPT_DIR"
HOST_SCRIPT="$DIR/open_safari_host.py"
MANIFEST_TEMPLATE="$DIR/com.tabbit.open_in_safari.template.json"

[[ -f "$HOST_SCRIPT" ]] || error "找不到本地脚本 '$HOST_SCRIPT'！请确保您没有移动安装包内的文件。"
[[ -f "$MANIFEST_TEMPLATE" ]] || error "找不到清单模板 '$MANIFEST_TEMPLATE'！请确保您没有移动安装包内的文件。"

if ! command -v python3 >/dev/null 2>&1; then
    error "系统未检测到 python3，无法安装本地主机。"
fi

# 2. 赋予 Python 脚本可执行权限
echo "[1/4] 赋予本地脚本可执行权限..."
chmod +x "$HOST_SCRIPT"

# 3. 获取用户输入的 扩展 ID (由于必须自己加载解压，ID 可能改变，除非指定了 key)
echo ""
echo "[2/4] 请输入浏览器为您生成的“扩展 ID” (32 位小写字母，例如: abcdefgh...):"
read -p "ID： " EXT_ID

[[ -n "$EXT_ID" ]] || error "必须输入扩展 ID。"
[[ "$EXT_ID" =~ ^[a-p]{32}$ ]] || error "扩展 ID 格式无效，应为 32 位小写字母（Chrome/Edge unpacked extension ID）。"

# 4. 基于模板生成 Native Messaging 清单，避免污染源码仓库
echo "[3/4] 生成浏览器本地主机配置..."
GENERATED_MANIFEST="$(mktemp "${TMPDIR:-/tmp}/open-in-safari.XXXXXX.json")"
EXTENSION_ORIGIN="chrome-extension://$EXT_ID/"
export HOST_SCRIPT EXTENSION_ORIGIN MANIFEST_TEMPLATE GENERATED_MANIFEST

python3 - <<'PY'
import json
import os
from pathlib import Path

template_path = Path(os.environ["MANIFEST_TEMPLATE"])
output_path = Path(os.environ["GENERATED_MANIFEST"])

manifest = json.loads(template_path.read_text(encoding="utf-8"))
manifest["path"] = os.environ["HOST_SCRIPT"]
manifest["allowed_origins"] = [os.environ["EXTENSION_ORIGIN"]]

output_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=4) + "\n",
    encoding="utf-8",
)
PY

# 5. 复制 JSON 清单到对应的浏览器 NativeMessagingHosts 目录
echo ""
echo "正在将配置安装到浏览器..."

CHROMIUM_DIRS=(
    "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
    "$HOME/Library/Application Support/Microsoft Edge Beta/NativeMessagingHosts"
    "$HOME/Library/Application Support/Microsoft Edge Dev/NativeMessagingHosts"
    "$HOME/Library/Application Support/Microsoft Edge Canary/NativeMessagingHosts"
    "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
    "$HOME/Library/Application Support/Google/Chrome Beta/NativeMessagingHosts"
    "$HOME/Library/Application Support/Google/Chrome Dev/NativeMessagingHosts"
    "$HOME/Library/Application Support/Google/Chrome Canary/NativeMessagingHosts"
    "$HOME/Library/Application Support/Google/Chrome for Testing/NativeMessagingHosts"
    "$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
    "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    "$HOME/Library/Application Support/Vivaldi/NativeMessagingHosts"
    "$HOME/Library/Application Support/Arc/User Data/NativeMessagingHosts"
)

INSTALLED=0
MANIFEST_NAME="com.tabbit.open_in_safari.json"

for NM_DIR in "${CHROMIUM_DIRS[@]}"; do
    # 取巧判断：如果浏览器 Application Support 目录存在，就尝试建 NativeMessagingHosts 并复制
    PARENT_DIR="$(dirname "$NM_DIR")"
    if [[ -d "$PARENT_DIR" ]]; then
        mkdir -p "$NM_DIR"
        cp "$GENERATED_MANIFEST" "$NM_DIR/$MANIFEST_NAME"
        echo "✅ 成功部署到: $NM_DIR"
        INSTALLED=1
    fi
done

if [[ "$INSTALLED" -eq 1 ]]; then
    echo ""
    echo "🎉 安装完成！请保留 '$DIR' 文件夹（这是您的本地主机运行环境）。"
    echo "现在您可以前往浏览器测试 'Open in Safari' 插件了。"
else
    echo ""
    echo "⚠️ 警告：似乎没有在您的 Mac 上检测到常见的 Chromium 浏览器（Edge, Chrome, Arc 等）。"
    echo "您可能需要手动将生成的 '$MANIFEST_NAME' 复制到您浏览器的 NativeMessagingHosts 目录下。"
fi

echo ""
echo "=== 按任意键退出 ==="
read -n 1 -s -r
