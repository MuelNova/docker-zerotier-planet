chcp 65001
@echo off
setlocal enabledelayedexpansion
:: 检查是否以管理员权限运行
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ^>^> 请以管理员权限运行该脚本
    pause
    exit /b 1
)

:: 设置变量
set "downloadUrl=http://YOUR_IP:3444/planet" :: 修改为你的公网 IP
set "destinationFolder=%ProgramData%\Zerotier\One"
set "networkID=YOUR_NETWORK_ID" :: 修改为你的网络 ID
:: 检查是否存在网络
set "networkExists="
for /f "tokens=3,4,9 delims= " %%a in ('zerotier-cli listnetworks ^| findstr /c:"%networkID%"') do (
    echo ^>^> [%%b] 分配 IP 为: %%c
    set "networkExists=1"
)

:: 如果网络存在，询问是否继续
if defined networkExists (
    set /p "continue=网络已存在，强制进行？[yN]"
    set "continue=!continue:~0,1!"  REM 去除空格
    if /i "!continue!"=="Y" (
        cls
    ) else (
        echo ^>^> 取消操作, 3s 后退出...
        timeout /t 3 /nobreak
        exit /b 0
    )
)

:: 备份原始文件
set "filePath=%destinationFolder%\planet"
if exist "%filePath%" (
    set "timestamp=%date:/=-%_%time::=-%"
    set "timestamp=!timestamp:.=-!"
    set "timestamp=!timestamp: =-!"
    set "backupFilePath=%destinationFolder%\planet_!timestamp!"
    echo !backupFilePath!
    move "%filePath%" "!backupFilePath!"
    echo ^>^> 已备份原始文件到 !backupFilePath!
)

:: 下载文件
powershell -command "Invoke-WebRequest -Uri '%downloadUrl%' -OutFile '%filePath%'"

:: 检查文件是否成功下载
if exist "%filePath%" (
    echo ^>^> 文件已成功下载到 %filePath%
    
    :: 加入网络
    echo ^>^> 尝试加入到网络 %networkID%...
    zerotier-cli join %networkID%
    echo ^>^> 成功！
    
    :: 重新启动 ZeroTierOneService 服务
    echo ^>^> 尝试重启 ZeroTierOneService...
    net stop ZeroTierOneService
    net start ZeroTierOneService
    echo ^>^> ZeroTierOneService 服务已重新启动！
    echo ^>^> 等待 25s 获取 IP...
    timeout /t 25 /nobreak

    :: 获取分配的 IP
    for /f "tokens=3,4,9 delims= " %%a in ('@echo off ^| zerotier-cli listnetworks ^| findstr /c:"%networkID%"') do (
        echo ^>^> [%%b] 分配 IP 为: %%c
        pause
    )
) else (
    echo ^>^> 下载文件时发生错误
)