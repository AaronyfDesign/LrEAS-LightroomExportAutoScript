@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM LrEAS — Lightroom Export Auto Script (Windows)
REM
REM 工作流程：
REM   1. LR 导出 JPEG 后，将文件路径作为 %1 传给本脚本
REM   2. 脚本通过 PowerShell COM 调 Photoshop 执行 JSX
REM   3. JSX 在 PS 中：打开 JPEG -> 回放 Action -> 另存为 JPEG
REM   4. 脚本删除原始 JPEG 和临时 PSD（如有）
REM
REM 滤镜调用方式：
REM   通过 app.doAction(ACTION_NAME, ACTION_SET) 回放预录的 PS Action
REM ============================================================

REM ==================== CONFIG ====================
REM Action 名称和 Action Set 名称（需与 PS 中录制的一致）
set ACTION_NAME=Portraiture
set ACTION_SET=AutoPortraiture

REM 输出 JPEG 质量 (1-12, 12 = 最高)
set JPEG_QUALITY=12
REM ================================================

set INPUT_FILE=%~1
set LOGFILE=%USERPROFILE%\Desktop\lreas.log

REM 获取时间戳
for /f "tokens=1-6 delims=/: " %%a in ("%date% %time%") do (
    set TS=%%a-%%b-%%c %%d:%%e:%%f
)

echo %TS% ^| === Export Action called === >> "%LOGFILE%"
echo %TS% ^| Input: %INPUT_FILE% >> "%LOGFILE%"

if "%INPUT_FILE%"=="" (
    echo %TS% ^| ERROR: No input file provided >> "%LOGFILE%"
    exit /b 1
)

if not exist "%INPUT_FILE%" (
    echo %TS% ^| ERROR: File not found: %INPUT_FILE% >> "%LOGFILE%"
    exit /b 1
)

REM 解析文件名和目录
for %%F in ("%INPUT_FILE%") do (
    set DIRNAME=%%~dpF
    set BASENAME=%%~nxF
    set FILENAME=%%~nF
)

REM 去掉 DIRNAME 末尾的反斜杠
if "!DIRNAME:~-1!"=="\" set DIRNAME=!DIRNAME:~0,-1!

set OUTPUT_FILE=!DIRNAME!\!FILENAME!_%ACTION_NAME%.jpg

REM 将路径中的反斜杠转为正斜杠供 JSX 使用（Photoshop File 对象兼容正斜杠）
set JSX_INPUT=%INPUT_FILE:\=/%
set JSX_OUTPUT=!OUTPUT_FILE:\=/!

echo %TS% ^| Output: %OUTPUT_FILE% >> "%LOGFILE%"

REM 生成 JSX 临时文件
set JSX_FILE=%TEMP%\lreas_%RANDOM%.jsx

REM 写入 JSX 脚本
(
echo (function^(^) {
echo     var inputFile = "%JSX_INPUT%";
echo     var outputFile = "%JSX_OUTPUT%";
echo     var jpegQuality = %JPEG_QUALITY%;
echo     var actionName = "%ACTION_NAME%";
echo     var actionSet = "%ACTION_SET%";
echo.
echo     app.displayDialogs = DialogModes.NO;
echo.
echo     var file = new File(inputFile^);
echo     if (!file.exists^) {
echo         $.writeln("ERROR: File not found: " + inputFile^);
echo         return;
echo     }
echo     var doc = app.open(file^);
echo     if (!doc^) {
echo         $.writeln("ERROR: Failed to open document"^);
echo         return;
echo     }
echo.
echo     try {
echo         var bgLayer = doc.artLayers.getByName("Background"^);
echo         if (bgLayer^) bgLayer.duplicate(^(^);
echo     } catch (e^) {}
echo.
echo     try {
echo         app.doAction(actionName, actionSet^);
echo         $.writeln("Action applied: " + actionSet + "/" + actionName^);
echo     } catch (e^) {
echo         $.writeln("Action failed: " + e.toString(^)^);
echo     }
echo.
echo     doc.flatten(^);
echo.
echo     var outFile = new File(outputFile^);
echo     var jpegOpts = new JPEGSaveOptions(^);
echo     jpegOpts.quality = jpegQuality;
echo     jpegOpts.matte = MatteType.NONE;
echo     doc.saveAs(outFile, jpegOpts, true, Extension.LOWERCASE^);
echo.
echo     doc.close(SaveOptions.DONOTSAVECHANGES^);
echo     app.displayDialogs = DialogModes.ALL;
echo     $.writeln("LrEAS: Done"^);
echo }^(^);
) > "%JSX_FILE%"

echo %TS% ^| JSX script created (action=%ACTION_SET%/%ACTION_NAME%^) >> "%LOGFILE%"

REM 通过 PowerShell COM 调用 Photoshop 执行 JSX
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop';" ^
    "try {" ^
    "  $ps = New-Object -ComObject Photoshop.Application;" ^
    "  $jsx = Get-Content -Path '%JSX_FILE%' -Raw -Encoding UTF8;" ^
    "  $ps.DoJavaScript($jsx);" ^
    "  exit 0;" ^
    "} catch {" ^
    "  Write-Output $_.Exception.Message;" ^
    "  exit 1;" ^
    "}"

set PS_RESULT=%ERRORLEVEL%
echo %TS% ^| Photoshop exit code: %PS_RESULT% >> "%LOGFILE%"

REM 检查输出文件
if exist "%OUTPUT_FILE%" (
    for %%S in ("%OUTPUT_FILE%") do set OUT_SIZE=%%~zS
    set /a SIZE_MB=!OUT_SIZE! / 1048576
    echo %TS% ^| SUCCESS: !SIZE_MB!MB: %OUTPUT_FILE% >> "%LOGFILE%"
) else (
    echo %TS% ^| ERROR: Output not found >> "%LOGFILE%"
)

REM 删除原始 JPEG
if exist "%INPUT_FILE%" del /f /q "%INPUT_FILE%"
echo %TS% ^| Deleted original: %INPUT_FILE% >> "%LOGFILE%"

REM 删除临时 PSD
set PSD_FILE=!DIRNAME!\!FILENAME!.psd
if exist "%PSD_FILE%" (
    del /f /q "%PSD_FILE%"
    echo %TS% ^| Deleted temp PSD: %PSD_FILE% >> "%LOGFILE%"
)

REM 清理临时 JSX
if exist "%JSX_FILE%" del /f /q "%JSX_FILE%"
echo %TS% ^| === Done === >> "%LOGFILE%"
