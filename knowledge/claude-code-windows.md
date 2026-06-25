# Claude Code на Windows — инструкция запуска

**Когда читать:** при вопросах про запуск Claude Code на Windows-компьютере Вячеслава.

---

## Требования

- Node.js v26+ (установлен)
- Claude Code CLI: `npm install -g @anthropic-ai/claude-code` (установлен)
- Hysteria2 туннель на порту 10810 (нужен для обхода блокировки Anthropic в РФ)
- Claude Pro подписка (slavin507@gmail.com)

---

## Как запустить

### 1. Проверить туннель
Открыть PowerShell, ввести:
```
Test-NetConnection 127.0.0.1 -Port 10810
```
- `TcpTestSucceeded: True` → туннель работает, идём дальше
- `TcpTestSucceeded: False` → запустить ярлык: Win+R → `shell:startup` → двойной клик **Hysteria2-VPN-Tunnel**

### 2. Открыть новый PowerShell
Обязательно отдельное окно (не терминал внутри VS Code — там интерактивный режим не работает).

### 3. Задать прокси и запустить
```powershell
$env:HTTPS_PROXY = "http://127.0.0.1:10810"
$env:HTTP_PROXY = "http://127.0.0.1:10810"
cd "C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis"
claude
```

### 4. Принять предупреждения
- **"Yes, I trust this folder"** → Enter
- **"Bypass Permissions mode"** → выбрать 2 (Yes, I accept) → Enter
- **Fullscreen renderer** → Enter или 2, без разницы

### 5. Работа
Строка `>` внизу — поле ввода. Кликнуть мышкой на неё если не печатает.

---

## Важные детали

- **VS Code расширение (боковая панель)** — не работает, выдаёт 403. Использовать только CLI.
- **Happ VPN** — только браузер, для терминала не подходит.
- **PowerShell с туннелем** — не закрывать, иначе туннель упадёт.
- **Прокси** — задавать в каждом новом PowerShell окне (они не сохраняются между сессиями).
- **Bypass Permissions** включён в настройках jarvis проекта — это нормально для автономной работы.

---

## Если что-то не работает

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `ECONNREFUSED` | Туннель не запущен | Запустить Hysteria2-VPN-Tunnel |
| `ERR_BAD_REQUEST` | Прокси не задан явно | Задать `$env:HTTPS_PROXY` |
| `UnsupportedProxyProtocol` | Прокси указан как socks5:// | Использовать http:// |
| Claude Code сразу закрывается | VS Code terminal | Открыть отдельный PowerShell |
