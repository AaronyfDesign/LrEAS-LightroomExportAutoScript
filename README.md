# LrEAS — Lightroom Export Auto Script

> English | [中文](README_zh.md)

> LR exports JPEG → Photoshop replays Action to apply any filter/plugin → saves as `<filename>_<ACTION_NAME>.jpg` → cleans up original.  
> Fully automated, universal PS post-processing framework. Supports Portraiture, Nik Collection, Topaz, or any plugin that can be recorded as a Photoshop Action.

## Overview

LrEAS is a lightweight Lightroom export post-processing automation framework. It is not tied to any specific filter or plugin — the user records an arbitrary Action in Photoshop (containing filter operation steps), fills in the Action name in the script CONFIG, and the PS processing flow executes automatically after Lightroom export.

**Profile branches:**

| Branch | Scenario | Description |
| --- | --- | --- |
| `profile/autoportraiture` | Imagenomic Portraiture retouching | Portraiture-specific configuration instance |
| `main` | Generic framework | Default script, user records Action and configures |

## Compatibility

| Component | Tested Versions | Untested |
| --- | --- | --- |
| Adobe Photoshop | 2024, 2025, 2026 | Others |
| Lightroom Classic | 14.x | — |
| macOS | 15.x (Apple Silicon) | Intel / others |
| Windows | Pending testing | Win10+ theoretically supported |

| Platform | Script | PS Bridge | Notification | Tested |
| --- | --- | --- | --- | --- |
| macOS | `LrEAS.sh` | AppleScript → `do javascript` | macOS Notification Center | ✓ |
| Windows | `LrEAS.bat` | PowerShell COM → `DoJavaScript` | None (log only) | Pending |

> **Note:** `AutoPortraiture.lrplugin/` is a deprecated Lightroom SDK Lua plugin, no longer maintained. The current solution uses the export action scripts in `scripts/`.

## How It Works

1. Select the script in Lightroom's Export dialog under "Post-Processing After Export" (macOS: `LrEAS.sh` / Windows: `LrEAS.bat`)
2. LR passes the exported JPEG path to the script
3. The script launches Photoshop and executes JSX (macOS via AppleScript, Windows via PowerShell COM)
4. JSX replays the pre-recorded Action via `app.doAction(actionName, actionSet)`
5. Saves as `<filename>_<ACTION_NAME>.jpg`, deletes the original JPEG and temp PSD
6. macOS shows a notification / Windows logs to file

## Repository Structure

```
LrEAS/
├── scripts/
│   ├── LrEAS.sh                    # macOS script (Shell → AppleScript → JSX)
│   └── LrEAS.bat                   # Windows script (Batch → PowerShell COM → JSX)
├── docs/
│   ├── usage.md                    # Detailed usage guide
│   └── troubleshooting.md          # Troubleshooting notes (deprecated, historical reference)
├── AutoPortraiture.lrplugin/        # deprecated: LR SDK Lua plugin
├── LICENSE
├── README.md
└── .gitignore
```

## Quick Start

### macOS

```bash
# 1. Copy script to LR Export Actions directory
cp scripts/LrEAS.sh ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/
chmod +x ~/Library/Application\ Support/Adobe/Lightroom/Export\ Actions/LrEAS.sh

# 2. Record an Action in PS (see docs/usage.md)

# 3. In LR Export dialog, select LrEAS.sh under "Post-Processing"
```

### Windows

```bat
:: 1. Copy script to LR Export Actions directory
copy scripts\LrEAS.bat "%APPDATA%\Adobe\Lightroom\Export Actions\"

:: 2. Record an Action in PS (see docs/usage.md)

:: 3. In LR Export dialog, select LrEAS.bat under "Post-Processing"
```

A Photoshop Action containing the target filter steps must be pre-recorded. See [docs/usage.md](docs/usage.md) for recording examples.

## Configuration

### macOS (`scripts/LrEAS.sh`)

```bash
# Action name and Action Set name (must match what's recorded in PS)
ACTION_NAME="Portraiture"
ACTION_SET="AutoPortraiture"

# Photoshop version (tested: 2024, 2025, 2026, others untested)
PS_VERSION="2025"

# Output JPEG quality (1-12, 12 = highest)
JPEG_QUALITY=12
```

### Windows (`scripts/LrEAS.bat`)

```bat
set ACTION_NAME=Portraiture
set ACTION_SET=AutoPortraiture
set JPEG_QUALITY=12
```

Windows does not require `PS_VERSION` — PowerShell COM auto-detects the installed Photoshop instance.

Output filename is `<original_filename>_<ACTION_NAME>.jpg`. For example, with `ACTION_NAME="Portraiture"`, `AYF_5412.jpg` outputs `AYF_5412_Portraiture.jpg`.

Switching post-processing scenarios only requires changing `ACTION_NAME` and `ACTION_SET` to point to a different PS Action.

## Technical Notes

Filter invocation uses `app.doAction(actionName, actionSet)` to replay a pre-recorded Photoshop Action. The Action contains the complete filter operation steps (including parameter settings) and executes automatically on playback. The JSX core logic is identical across platforms — only the script shell differs.

| Aspect | macOS | Windows |
| --- | --- | --- |
| Script shell | Shell (`LrEAS.sh`) | Batch (`LrEAS.bat`) |
| PS bridge | AppleScript `do javascript` | PowerShell COM `DoJavaScript` |
| PS version config | `PS_VERSION` variable | COM auto-detect |
| Notification | macOS Notification Center | None (log only) |
| Log file | `~/Desktop/lreas.log` | `%USERPROFILE%\Desktop\lreas.log` |
| JSX code | Identical | Identical |
| Dependencies | Built into macOS | PowerShell 5.1+ (included with Win10) |

See [docs/usage.md](docs/usage.md) for detailed instructions.
