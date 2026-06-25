# Запуск Claude Code на Windows: проверяет туннель Hysteria2, поднимает его при необходимости,
# задаёт прокси-переменные и стартует claude. См. knowledge/claude-code-windows.md

$tunnelShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Hysteria2-VPN-Tunnel.lnk"
$jarvisPath = "C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis"
$proxyUrl = "http://127.0.0.1:10810"

function Test-Tunnel {
    (Test-NetConnection 127.0.0.1 -Port 10810 -WarningAction SilentlyContinue).TcpTestSucceeded
}

if (-not (Test-Tunnel)) {
    Write-Host "Туннель не отвечает на 10810 — запускаю Hysteria2-VPN-Tunnel..." -ForegroundColor Yellow
    if (Test-Path $tunnelShortcut) {
        Start-Process $tunnelShortcut
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Ярлык не найден: $tunnelShortcut" -ForegroundColor Red
    }
}

$attempts = 0
while (-not (Test-Tunnel) -and $attempts -lt 5) {
    Start-Sleep -Seconds 2
    $attempts++
}

if (-not (Test-Tunnel)) {
    Write-Host "Туннель так и не поднялся на 127.0.0.1:10810. Запусти Hysteria2-VPN-Tunnel вручную и попробуй снова." -ForegroundColor Red
    exit 1
}

Write-Host "Туннель работает." -ForegroundColor Green

$env:HTTPS_PROXY = $proxyUrl
$env:HTTP_PROXY = $proxyUrl

Set-Location $jarvisPath
claude
