# LrEAS 使用指南

## 环境要求

### macOS

- macOS（已测试 15.x Apple Silicon）
- Lightroom Classic（已测试 14.x）
- Adobe Photoshop（已测试 2024、2025、2026，其余版本未测试）

### Windows

- Windows 10 或更高（需 PowerShell 5.1+，系统自带）
- Lightroom Classic（已测试 14.x）
- Adobe Photoshop（已测试 2024、2025、2026，其余版本未测试）
- Windows 版待实际测试

### 通用

- 任意 PS 滤镜/插件（如 Imagenomic Portraiture、Nik Collection、Topaz Labs 等），需安装在 Photoshop 中

## 安装

### 1. 安装脚本

**macOS：**

```bash
cp scripts/LrEAS.sh ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/
chmod +x ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/LrEAS.sh
```

**Windows：**

```bat
copy scripts\LrEAS.bat "%APPDATA%\Adobe\Lightroom\Export Actions\"
```

### 2. 在 Photoshop 中录制 Action

LrEAS 通过 `app.doAction(actionName, actionSet)` 回放预录的 PS Action，不绑定特定滤镜。需要先在 PS 中录制一个包含目标滤镜步骤的 Action：

1. 打开 Photoshop，打开任意一张照片
2. 窗口 → 动作（Window → Actions），调出动作面板
3. 点击面板菜单 → 新建动作集（Action Set），命名（如 `AutoPortraiture`）
4. 在该集下新建动作（Action），命名（如 `Portraiture`），点击「开始记录」
5. 执行目标滤镜操作（如 滤镜 → Imagenomic → Portraiture）
6. 在滤镜界面中调整参数，点击确定
7. 回到动作面板，点击「停止录制」按钮

记住 Action 名称和 Set 名称，填入脚本 CONFIG 即可。

### 3. 在 Lightroom 中配置导出

在 Lightroom 中选中照片，打开导出对话框（macOS: `Cmd + Shift + E` / Windows: `Ctrl + Shift + E`）：

1. 图像格式：JPEG
2. 质量：100%
3. 向下滚动到"导出后"（Post-Processing）下拉菜单
4. macOS 选择 `LrEAS.sh` / Windows 选择 `LrEAS.bat`
5. 点击导出

导出完成后，脚本自动运行：Photoshop 打开 JPEG → 回放 Action → 另存为 `<原文件名>_<ACTION_NAME>.jpg` → 删除原始 JPEG → 清理临时文件。macOS 会弹出通知，Windows 写入日志。

## 配置参数

### macOS (`scripts/LrEAS.sh`)

```bash
# Action 名称和 Action Set 名称（需与 PS 中录制的一致）
ACTION_NAME="Portraiture"
ACTION_SET="AutoPortraiture"

# Photoshop 版本（已测试：2024、2025、2026，其余版本未测试）
PS_VERSION="2025"

# 输出 JPEG 质量 (1-12, 12 = 最高)
JPEG_QUALITY=12
```

### Windows (`scripts/LrEAS.bat`)

```bat
set ACTION_NAME=Portraiture
set ACTION_SET=AutoPortraiture
set JPEG_QUALITY=12
```

Windows 版不需要 `PS_VERSION`，PowerShell COM 自动查找已安装的 Photoshop 实例。

输出文件名为 `<原文件名>_<ACTION_NAME>.jpg`。例如 `ACTION_NAME="Portraiture"` 时，`AYF_5412.jpg` 的输出为 `AYF_5412_Portraiture.jpg`。

修改后同步到 Export Actions 目录：

**macOS：**

```bash
cp scripts/LrEAS.sh ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/
```

**Windows：**

```bat
copy scripts\LrEAS.bat "%APPDATA%\Adobe\Lightroom\Export Actions\"
```

## 平台差异说明

| 维度 | macOS | Windows |
| --- | --- | --- |
| 脚本 | `LrEAS.sh`（Shell） | `LrEAS.bat`（批处理） |
| PS 桥接 | AppleScript → `do javascript` | PowerShell COM → `DoJavaScript` |
| PS 版本配置 | 需手动设置 `PS_VERSION` | COM 自动查找，无需配置 |
| 通知 | macOS 通知中心 | 无通知，仅日志 |
| 日志路径 | `~/Desktop/lreas.log` | `%USERPROFILE%\Desktop\lreas.log` |
| JSX 代码 | 完全相同 | 完全相同 |
| 路径处理 | 原生正斜杠 | 脚本内部自动将 `\` 转为 `/` 传给 JSX |

## 场景示例

LrEAS 不绑定特定滤镜，切换场景只需录制不同 Action 并修改 CONFIG。以下为几个常见场景的配置示例：

### 场景一：Portraiture 磨皮

PS 中录制 Action：滤镜 → Imagenomic → Portraiture 3/4 → 调参 → 确定。

```bash
ACTION_NAME="Portraiture"
ACTION_SET="AutoPortraiture"
```

输出：`photo_Portraiture.jpg`

### 场景二：Nik Collection 黑白转换

PS 中录制 Action：滤镜 → Nik Collection → Silver Efex Pro → 调参 → 确定。

```bash
ACTION_NAME="SilverEfex"
ACTION_SET="NikCollection"
```

输出：`photo_SilverEfex.jpg`

### 场景三：Topaz 降噪

PS 中录制 Action：滤镜 → Topaz Labs → Topaz DeNoise AI → 调参 → 确定。

```bash
ACTION_NAME="DeNoise"
ACTION_SET="TopazLabs"
```

输出：`photo_DeNoise.jpg`

### 场景四：多步骤组合

PS 中录制一个包含多步操作的 Action：例如先 Portraiture 磨皮 → 再 USM 锐化 → 再色彩调整。

```bash
ACTION_NAME="FullRetouch"
ACTION_SET="MyWorkflow"
```

输出：`photo_FullRetouch.jpg`

## 批量处理

在 Lightroom 中选中多张照片后导出，LR 会逐张导出 JPEG 并为每张调用一次脚本。Photoshop 依次处理每张照片，全程无需手动干预。macOS 每张处理完成后弹出通知，Windows 在日志中记录。

## 输出说明

每张照片处理完成后：

- 生成 `<原文件名>_<ACTION_NAME>.jpg`（与导出目录相同位置）
- 原始 JPEG（LR 导出的）被删除
- 临时 PSD 文件（如有）被删除
- 最终只保留处理后的 JPEG 一个文件

## 日志

| 平台 | 路径 |
| --- | --- |
| macOS | `~/Desktop/lreas.log` |
| Windows | `%USERPROFILE%\Desktop\lreas.log`（即 `C:\Users\用户名\Desktop\lreas.log`） |

每条记录包含时间戳和操作状态，可用于排错。示例：

```
2026-07-14 02:20:00 | === Export Action called ===
2026-07-14 02:20:00 | Input: /path/to/photo.jpg
2026-07-14 02:20:00 | Output: /path/to/photo_Portraiture.jpg
2026-07-14 02:20:00 | JSX script created (action=AutoPortraiture/Portraiture)
2026-07-14 02:20:00 | Launching Photoshop (PS 2025)...
2026-07-14 02:20:10 | Photoshop exit code: 0
2026-07-14 02:20:10 | SUCCESS: 15MB: /path/to/photo_Portraiture.jpg
2026-07-14 02:20:10 | Deleted original: /path/to/photo.jpg
2026-07-14 02:20:10 | === Done ===
```

## 常见问题

**导出后没有生成输出文件**

检查日志文件。确认 PS 中已录制 Action，且 Action 名称和 Set 名称与脚本 CONFIG 中的 `ACTION_NAME` 和 `ACTION_SET` 一致。如果 Action 不存在，`app.doAction()` 会静默失败（被 try-catch 捕获），照片仍会被保存但未经滤镜处理。

**滤镜效果没生效**

确认目标插件已正确安装在 Photoshop 中，且录制 Action 时确实执行了滤镜步骤（不只是打开又关闭了滤镜窗口）。可以在 PS 中手动回放该 Action 验证效果是否生效。

**Photoshop 没有弹到前台**

脚本禁用了 PS 对话框（`app.displayDialogs = DialogModes.NO`），Photoshop 在后台静默处理。

**macOS：使用的是其他版本的 Photoshop**

修改脚本 CONFIG 中的 `PS_VERSION` 为你的版本号（如 `"2024"`、`"2026"`）。已测试版本：2024、2025、2026，其余版本未测试。

**Windows：PowerShell 报错**

确认系统有 PowerShell 5.1 或更高（Win10 1809+ 自带）。在 PowerShell 中执行 `$PSVersionTable.PSVersion` 查看版本。如果 Photoshop COM 对象创建失败，确认 Photoshop 已正确安装且注册了 COM 组件。

**文件名包含中文**

已验证支持，中文路径可正常处理。

**路径有空格**

LR 传给脚本的路径已正确处理空格，无需额外转义。
