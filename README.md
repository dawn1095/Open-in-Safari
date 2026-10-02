# Open in Safari 扩展程序手动安装指南

本指南将帮助你在 macOS 上手动完成 Edge/Chrome 扩展程序与本地 Safari 启动脚本的对接。由于浏览器安全限制，必须严格执行以下步骤。

### **第一阶段：加载浏览器扩展**

1. 打开 Microsoft Edge 浏览器，访问 `edge://extensions/`（如果是 Chrome 请访问 `chrome://extensions/`）。
2. 在页面左侧或右上角开启 **“开发人员模式”**。
3. 点击 **“加载解压后的扩展”**，选择仓库中的 `extensions` 文件夹（其中包含 `manifest.json` 和 `background.js`）。
4. **关键步骤**：安装完成后，在扩展卡片上找到一串由 32 位字符组成的 **“ID”**（例如：`abcdefghijklmnopabcdefghijklmnop`）。请记录下来，后续配置需要使用。

---

### **第二阶段：本地宿主环境配置（一键自动安装）**

我们提供了一个自动化的安装脚本，可以帮你省去修改和拷贝配置文件的繁琐步骤。

1. **保存宿主文件夹**：
   将下载好的包含了 `open_safari_host.py` 和 `install.command` 等文件的文件夹移动到一个永久存放的目录（例如你的“文档”或“应用程序”等文件夹下）。
   *注意：安装完成后不要移动或删除此文件夹，里面包含着运行该扩展所需的本地组件。*

2. **运行安装脚本**：
   双击运行目录下的 **`install.command`** 文件。
   - 如果 macOS 提示“无法打开，因为来自未知的开发者”，请右键该文件并选择“打开”。
   - 终端窗口将会弹出，并引导你输入第一阶段记录的 **扩展 ID**。如果 ID 不是 32 位小写字母，脚本会直接报错并退出。
   - 脚本会自动基于模板生成 Native Messaging 配置，不会修改仓库内的源码文件。
   - 脚本会自动为检测到的浏览器部署配置，支持 Edge、Edge Beta/Dev/Canary、Chrome、Chrome Beta/Dev/Canary、Chrome for Testing、Chromium、Arc、Brave、Vivaldi。

当你看到终端提示 “🎉 安装完成！” 时，即可关闭终端窗口。

---

### **第三阶段：测试与调试**

1. 点击浏览器工具栏中的“Open in Safari”图标。
2. 如果 Safari 成功弹出并加载当前页面，则部署成功。
3. **常见问题排查**：
   - **报错 "Native host not found"**：检查 JSON 文件名是否与 `background.js` 中调用的名称一致，检查 JSON 是否放在了正确的 `NativeMessagingHosts` 文件夹下。
   - **报错 "Native host has exited"**：通常是本地主机启动后异常退出。请按顺序检查：`open_safari_host.py` 仍在原路径、脚本有执行权限、重新运行一次 `install.command` 重新生成并部署最新配置，然后在扩展管理页点击“重新加载”扩展再测试。
   - **点击无反应**：检查 JSON 里的 `path` 是否为绝对路径，且 Python 脚本是否有执行权限；如果你重新“加载解压后的扩展”导致扩展 ID 变化，也必须重新运行 `install.command`。
   - **权限错误**：检查 JSON 里的 `allowed_origins` 是否准确包含了当前的扩展 ID。
   - **提示仅支持 http/https**：扩展现在会主动拒绝 `file://`、`javascript:`、`chrome://` 等非网页链接，这是预期行为。

### **开发自检**

工具链由 `pyproject.toml` + `uv.lock` 统一接管（ruff 负责 lint + 格式化，替代 black/flake8/isort）：

```bash
uv sync                  # 首次：按 uv.lock 装齐 dev 依赖（pytest / ruff / mypy）
uv run pytest            # 运行测试
uv run ruff check .      # 静态检查（门禁，当前必须零告警）
uv run ruff format .     # 格式化（暂不作为门禁，批量重排影响面大，需单独评估）
uv run mypy              # 类型检查（门禁，当前必须零错误）
bash -n host/install.command   # 校验安装脚本语法
```

> **运行时解释器约束**：`host/open_safari_host.py` 由浏览器按 shebang `#!/usr/bin/python3` 直接拉起，
> 只能使用系统自带 `python3`（macOS 当前为 3.9），因此 `requires-python`、ruff `target-version` 均取 `py39`。
> 禁止把 shebang 改成 uv 托管解释器的绝对路径——那会写死本机路径，脚本分发到其他机器后立即失效。
>
> **版本号**：唯一真身在 `extensions/manifest.json` 的 `version`；`pyproject.toml` 的 `[project].version`
> 为派生镜像，由 `tests/test_version_consistency.py` 强校验。
