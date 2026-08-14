# Запуск Claude Code на Windows: проверяет свой Hysteria2-туннель (Fornex), поднимает его при необходимости,
# задаёт прокси и стартует claude. См. knowledge/claude-code-windows.md

$tunnelScript = "C:\Users\User\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\Hysteria2-VPN-Tunnel.lnk"
$jarvisPath = "C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis"
$proxyUrl = "http://127.0.0.1:10810"

function Test-Tunnel {
    (Test-NetConnection 127.0.0.1 -Port 10810 -WarningAction SilentlyContinue).TcpTestSucceeded
}

if (-not (Test-Tunnel)) {
    Write-Host "Hysteria2-туннель не отвечает на 10810 — запускаю..." -ForegroundColor Yellow
    if (Test-Path $tunnelScript) {
        Start-Process $tunnelScript
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Ярлык туннеля не найден: $tunnelScript" -ForegroundColor Red
    }
}

$attempts = 0
while (-not (Test-Tunnel) -and $attempts -lt 5) {
    Start-Sleep -Seconds 2
    $attempts++
}

if (-not (Test-Tunnel)) {
    Write-Host "Туннель так и не поднялся на 127.0.0.1:10810. Запусти ярлык Hysteria2-VPN-Tunnel вручную и попробуй снова." -ForegroundColor Red
    exit 1
}

Write-Host "Туннель работает." -ForegroundColor Green

$env:HTTPS_PROXY = $proxyUrl
$env:HTTP_PROXY = $proxyUrl

Set-Location $jarvisPath
claude
