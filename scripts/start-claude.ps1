# Запуск Claude Code на Windows: проверяет VPN Happ, поднимает его при необходимости,
# задаёт прокси и стартует claude. См. knowledge/claude-code-windows.md

$happExe = "C:\Program Files\FlyFrogLLC\Happ\Happ.exe"
$jarvisPath = "C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis"
$proxyUrl = "http://127.0.0.1:10809"

function Test-Tunnel {
    (Test-NetConnection 127.0.0.1 -Port 10809 -WarningAction SilentlyContinue).TcpTestSucceeded
}

if (-not (Test-Tunnel)) {
    Write-Host "Happ VPN не отвечает на 10809 — запускаю Happ..." -ForegroundColor Yellow
    if (Test-Path $happExe) {
        Start-Process $happExe
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Happ не найден по пути: $happExe" -ForegroundColor Red
    }
}

$attempts = 0
while (-not (Test-Tunnel) -and $attempts -lt 5) {
    Start-Sleep -Seconds 2
    $attempts++
}

if (-not (Test-Tunnel)) {
    Write-Host "Happ так и не поднял прокси на 127.0.0.1:10809. Запусти Happ вручную (и включи подключение) и попробуй снова." -ForegroundColor Red
    exit 1
}

Write-Host "VPN работает." -ForegroundColor Green

$env:HTTPS_PROXY = $proxyUrl
$env:HTTP_PROXY = $proxyUrl

Set-Location $jarvisPath
claude
