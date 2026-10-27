@echo off
chcp 65001 >nul
title 卸载 Antigravity Proxy Launcher 快捷方式
set "SHORTCUT=%USERPROFILE%\Desktop\Antigravity IDE (Clash代理).lnk"
if exist "%SHORTCUT%" (
    del "%SHORTCUT%"
    echo [√] 已成功移除桌面快捷方式。
) else (
    echo [!] 未在桌面找到快捷方式，无需清理。
)
pause
