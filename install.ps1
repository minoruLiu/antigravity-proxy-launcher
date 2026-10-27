# ==============================================================================
# Antigravity Proxy Launcher 一键安装脚本
# ==============================================================================
$ErrorActionPreference = 'Stop'

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Antigravity Proxy Launcher 安装器" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath = Join-Path $scriptDir "src\launch-proxy.vbs"

if (-not (Test-Path $vbsPath)) {
    Write-Host "[!] 错误：未找到核心脚本 $vbsPath" -ForegroundColor Red
    exit 1
}

# 1. 查找 Antigravity IDE.exe
$candidates = @(
    "$env:LOCALAPPDATA\Programs\Antigravity IDE\Antigravity IDE.exe",
    "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
    "$env:ProgramFiles\Antigravity IDE\Antigravity IDE.exe",
    "$env:ProgramFiles\Antigravity\Antigravity.exe"
)

$exePath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $exePath) {
    Write-Host "[!] 警告：未在默认路径检测到 Antigravity IDE，快捷方式将使用系统默认图标。" -ForegroundColor Yellow
} else {
    Write-Host "[√] 找到 Antigravity IDE：$exePath" -ForegroundColor Green
}

# 2. 创建桌面快捷方式
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop "Antigravity IDE (Clash代理).lnk"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $scriptDir
if ($exePath) {
    $shortcut.IconLocation = "$exePath,0"
}
$shortcut.Description = "以代理模式静默启动 Antigravity IDE"
$shortcut.Save()

Write-Host "[√] 桌面快捷方式创建成功：" -ForegroundColor Green
Write-Host "    $shortcutPath" -ForegroundColor White
Write-Host ""
Write-Host "恭喜！现在只需双击桌面的「Antigravity IDE (Clash代理)」即可享受无 TUN 规则分流代理！" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
