# LrEAS — Lightroom Export Auto Script

> [English](README.md) | 中文

> LR 导出 JPEG → Photoshop 回放 Action 应用任意滤镜/插件 → 另存为 `<文件名>_<ACTION_NAME>.jpg` → 删除原始文件。
> 全自动化、通用 PS 后处理框架。支持 Portraiture、Nik Collection、Topaz 或任何可录制为 PS Action 的插件。

## 概述

LrEAS 是一个轻量级的 Lightroom 导出后处理自动化框架。它不绑定特定滤镜或插件——用户在 Photoshop 中录制任意 Action（包含滤镜操作步骤），在脚本 CONFIG 中填入 Action 名称，Lightroom 导出后 PS 处理流程即自动执行。

**配置分支：**

| 分支 | 场景 | 说明 |
| --- | --- | --- |
| `profile/autoportraiture` | Imagenomic Portraiture 磨皮 | Portraiture 专用配置实例 |
| `main` | 通用框架 | 默认脚本，用户录制 Action 并配置 |

## 兼容性

| 组件 | 已测试版本 | 未测试 |
| --- | --- | --- |
| Adobe Photoshop | 2024、2025、2026 | 其他版本 |
| Lightroom Classic | 14.x | — |
| macOS | 15.x（Apple Silicon） | Intel / 其他 |
| Windows | 待测试 | Win10+ 理论支持 |

| 平台 | 脚本 | PS 桥接 | 通知 | 已测试 |
| --- | --- | --- | --- | --- |
| macOS | `LrEAS.sh` | AppleScript → `do javascript` | macOS 通知中心 | ✓ |
| Windows | `LrEAS.bat` | PowerShell COM → `DoJavaScript` | 无（仅日志） | 待测试 |

> **注意：** `AutoPortraiture.lrplugin/` 是已弃用的 Lightroom SDK Lua 插件，不再维护。当前方案使用 `scripts/` 中的导出动作脚本。

## 工作原理

1. 在 Lightroom 导出对话框的"导出后"（Post-Processing）中选择脚本（macOS: `LrEAS.sh` / Windows: `LrEAS.bat`）
2. LR 将导出的 JPEG 路径传给脚本
3. 脚本启动 Photoshop 并执行 JSX（macOS 通过 AppleScript，Windows 通过 PowerShell COM）
4. JSX 通过 `app.doAction(actionName, actionSet)` 回放预录的 Action
5. 另存为 `<文件名>_<ACTION_NAME>.jpg`，删除原始 JPEG 和临时 PSD
6. macOS 弹出通知 / Windows 记录日志

## 仓库结构

```
LrEAS/
├── scripts/
│   ├── LrEAS.sh                    # macOS 脚本（Shell → AppleScript → JSX）
│   └── LrEAS.bat                   # Windows 脚本（Batch → PowerShell COM → JSX）
├── docs/
│   ├── usage.md                    # 详细使用指南
│   └── troubleshooting.md          # 故障排除（已弃用，仅供参考）
├── AutoPortraiture.lrplugin/        # 已弃用：LR SDK Lua 插件
├── LICENSE
├── README.md
└── .gitignore
```

## 快速开始

### macOS

```bash
# 1. 复制脚本到 LR 导出动作目录
cp scripts/LrEAS.sh ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/
chmod +x ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/LrEAS.sh

# 2. 在 PS 中录制 Action（详见 docs/usage.md）

# 3. 在 LR 导出对话框的"导出后"选择 LrEAS.sh
```

### Windows

```bat
:: 1. 复制脚本到 LR 导出动作目录
copy scripts\LrEAS.bat "%APPDATA%\Adobe\Lightroom\Export Actions\"

:: 2. 在 PS 中录制 Action（详见 docs/usage.md）

:: 3. 在 LR 导出对话框的"导出后"选择 LrEAS.bat
```

需预先在 Photoshop 中录制包含目标滤镜步骤的 Action。录制示例详见 [docs/usage.md](docs/usage.md)。

## 配置

### macOS（`scripts/LrEAS.sh`）

```bash
# Action 名称和 Action Set 名称（需与 PS 中录制的一致）
ACTION_NAME="Portraiture"
ACTION_SET="AutoPortraiture"

# Photoshop 版本（已测试：2024、2025、2026，其余版本未测试）
PS_VERSION="2025"

# 输出 JPEG 质量（1-12，12 = 最高）
JPEG_QUALITY=12
```

### Windows（`scripts/LrEAS.bat`）

```bat
set ACTION_NAME=Portraiture
set ACTION_SET=AutoPortraiture
set JPEG_QUALITY=12
```

Windows 不需要 `PS_VERSION`——PowerShell COM 自动检测已安装的 Photoshop 实例。

输出文件名为 `<原文件名>_<ACTION_NAME>.jpg`。例如 `ACTION_NAME="Portraiture"` 时，`AYF_5412.jpg` 的输出为 `AYF_5412_Portraiture.jpg`。

切换后处理场景只需将 `ACTION_NAME` 和 `ACTION_SET` 改为指向不同的 PS Action 即可。

## 技术说明

滤镜调用使用 `app.doAction(actionName, actionSet)` 回放预录的 Photoshop Action。Action 中包含完整的滤镜操作步骤（含参数设置），回放时自动执行。各平台的 JSX 核心逻辑完全相同——仅脚本外壳不同。

| 方面 | macOS | Windows |
| --- | --- | --- |
| 脚本外壳 | Shell（`LrEAS.sh`） | Batch（`LrEAS.bat`） |
| PS 桥接 | AppleScript `do javascript` | PowerShell COM `DoJavaScript` |
| PS 版本配置 | `PS_VERSION` 变量 | COM 自动检测 |
| 通知 | macOS 通知中心 | 无（仅日志） |
| 日志文件 | `~/Desktop/lreas.log` | `%USERPROFILE%\Desktop\lreas.log` |
| JSX 代码 | 相同 | 相同 |
| 依赖 | macOS 内置 | PowerShell 5.1+（Win10 自带） |

详细说明请参见 [docs/usage.md](docs/usage.md)。
