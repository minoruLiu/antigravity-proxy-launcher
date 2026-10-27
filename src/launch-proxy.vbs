' ==============================================================================
' Antigravity Proxy Launcher for Windows
' 自动读取 Windows 系统代理/Clash 端口，注入环境变量并静默拉起 Antigravity IDE
' ==============================================================================
Option Explicit

Dim WshShell, FSO, objEnv
Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set objEnv = WshShell.Environment("PROCESS")

Dim scriptDir
scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' 1. 读取 Windows 注册表系统代理 (WinINet)
Dim proxyEnable, proxyServer, finalProxy
proxyEnable = 0
proxyServer = ""
finalProxy = ""

On Error Resume Next
proxyEnable = WshShell.RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxyEnable")
proxyServer = WshShell.RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxyServer")
On Error GoTo 0

If proxyEnable = 1 And Trim(proxyServer) <> "" Then
    Dim rawProxy
    rawProxy = Trim(proxyServer)
    If InStr(rawProxy, "=") > 0 Then
        Dim pairs, p, kv
        pairs = Split(rawProxy, ";")
        For Each p In pairs
            If InStr(p, "=") > 0 Then
                kv = Split(p, "=")
                If LCase(Trim(kv(0))) = "http" Or LCase(Trim(kv(0))) = "https" Then
                    rawProxy = Trim(kv(1))
                    Exit For
                End If
            End If
        Next
    End If
    If InStr(rawProxy, "://") = 0 Then
        finalProxy = "http://" & rawProxy
    Else
        finalProxy = rawProxy
    End If
End If

' 2. 若未开启系统代理，尝试从 config.ini 读取备用默认代理
If finalProxy = "" Then
    Dim iniPath
    iniPath = FSO.BuildPath(scriptDir, "config.ini")
    If Not FSO.FileExists(iniPath) Then
        iniPath = FSO.BuildPath(FSO.GetParentFolderName(scriptDir), "config.ini")
    End If
    
    If FSO.FileExists(iniPath) Then
        Dim iniFile, line
        Set iniFile = FSO.OpenTextFile(iniPath, 1)
        Do While Not iniFile.AtEndOfStream
            line = Trim(iniFile.ReadLine())
            If InStr(line, "=") > 0 And Left(line, 1) <> ";" And Left(line, 1) <> "#" Then
                Dim parts
                parts = Split(line, "=", 2)
                If LCase(Trim(parts(0))) = "default_proxy" Then
                    finalProxy = Trim(parts(1))
                End If
            End If
        Loop
        iniFile.Close
    End If
End If

' 3. 注入代理环境变量
If finalProxy <> "" Then
    objEnv("HTTP_PROXY")  = finalProxy
    objEnv("HTTPS_PROXY") = finalProxy
    objEnv("ALL_PROXY")   = Replace(finalProxy, "http://", "socks5://")
    objEnv("NO_PROXY")    = "localhost,127.0.0.1,::1"
End If

' 4. 自动定位 Antigravity IDE 安装路径
Dim localApp, progFiles, candidates, c, exePath
localApp = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
progFiles = WshShell.ExpandEnvironmentStrings("%PROGRAMFILES%")

candidates = Array( _
    localApp & "\Programs\Antigravity IDE\Antigravity IDE.exe", _
    localApp & "\Programs\Antigravity\Antigravity.exe", _
    progFiles & "\Antigravity IDE\Antigravity IDE.exe", _
    progFiles & "\Antigravity\Antigravity.exe" _
)

exePath = ""
For Each c In candidates
    If FSO.FileExists(c) Then
        exePath = c
        Exit For
    End If
Next

If exePath = "" Then
    MsgBox "未检测到 Antigravity IDE 安装路径！请确认已正确安装 Antigravity IDE。", 16, "Antigravity Proxy Launcher"
    WScript.Quit 1
End If

' 5. 透传外部参数
Dim args, i, q
q = Chr(34)
args = ""
For i = 0 To WScript.Arguments.Count - 1
    args = args & " " & q & WScript.Arguments(i) & q
Next

' 6. 静默启动
WshShell.Run q & exePath & q & args, 0, False
