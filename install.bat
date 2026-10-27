@echo off
chcp 65001 >nul
title 安装 Antigravity Proxy Launcher
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
