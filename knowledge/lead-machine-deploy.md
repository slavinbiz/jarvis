# Деплой Lead Machine — что сделано и как туда попасть

**Когда читать:** при вопросах про Lead Machine, его сервер, перезапуск, или баги деплоя.

## Доступ к серверу

- IP: 91.193.25.237 (Beget Latvia, тот же сервер что Jarvis-бот)
- root-пароль — `uB4Z5DrT~c~s` (актуален на 2026-06-28; если не подходит — сбросить в cp.beget.com → сервер)
- На этой машине (Windows) нет SSH-ключа на сервер и нет `expect` — подключение через **PuTTY plink/pscp** с паролем напрямую:
  ```
  "/c/Program Files/PuTTY/plink.exe" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw "ПАРОЛЬ" root@91.193.25.237 "команда"
  "/c/Program Files/PuTTY/pscp.exe" -batch -hostkey "SHA256:..." -pw "ПАРОЛЬ" локальный_файл root@91.193.25.237:путь
  ```
- Репо `lead-machine` на GitHub приватный — клонировать на сервере по HTTPS не вышло (нет токена там). Решение: тарболл локально → pscp → распаковать на сервере. Если нужно повторить деплой кода — так же: правим локально, коммитим/пушим в GitHub (для истории), и pscp точечно нужные файлы на сервер (либо весь тарболл).

## Что на сервере

- Путь: `/home/agent/projects/lead-machine` (владелец agent:agent)
- Стек поднят через `docker compose -f docker-compose.prod.yml` — 3 контейнера: `app`, `db` (postgres:16), `redis`
- `app` использует `network_mode: host` → достаёт до db/redis через `localhost`, поэтому **обязательно** нужны `ports: 127.0.0.1:5432:5432` и `127.0.0.1:6379:6379` в db/redis (их не было в исходном docker-compose.prod.yml — добавлено)
- `.env` на сервере содержит реальные секреты + `DB_PASSWORD` (для подстановки `${DB_PASSWORD}` в compose). `app/config.py` Settings помечен `extra="ignore"`, чтобы лишний DB_PASSWORD не валил pydantic-валидацию
- Дockerfile делает `COPY . .` — **.env копируется в образ при сборке**. Любая правка `.env` требует `docker compose -f docker-compose.prod.yml build` заново, иначе старые значения останутся в образе

## Известные проблемы / фиксы (2026-06-24)

1. Диск сервера был забит на 99% (2.9 ГБ мёртвого кэша VS Code Tunnel в `/root/.vscode/cli/servers` — туннель не был даже запущен). Почистили: `rm -rf /root/.vscode/cli/servers/*`, `apt-get clean`, `journalctl --vacuum-time=3d`
2. Docker не был установлен — поставили через `get.docker.com`
3. aiogram 3.7.0 не принимает `parse_mode=` в конструкторе `Bot()` — нужен `default=DefaultBotProperties(parse_mode=...)`. Исправлено в `app/bot/control.py`, закоммичено в репо
4. ~~TELEGRAM_BOT_TOKEN в .env — плейсхолдер~~ — закрыто, `@SlavinLeads_bot` работает
5. ~~TELEGRAM_API_ID/HASH — плейсхолдер, Telethon не авторизован~~ — закрыто 2026-07-05: my.telegram.org стабильно блокировал создание приложения с основного номера Вячеслава (ошибка на всех VPN/браузерах), обошли публичной парой Telegram Desktop (`611335`/`d524b414d21f4d37f08684c1df41ac9c`). Telethon-сессия авторизована под отдельным номером +79064252045 (не личный — риск блокировки за автоматическую рассылку)

## Деплой кода (сервер НЕ git-репозиторий)

Код на сервере лежит без `.git` — деплой тарболлом, не `git pull`:
```bash
# локально
cd "C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine"
tar -czf /tmp/lead-machine-update.tar.gz app/ requirements.txt
"/c/Program Files/PuTTY/pscp" -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw "ПАРОЛЬ" /tmp/lead-machine-update.tar.gz root@91.193.25.237:/tmp/lead-machine-update.tar.gz

# на сервере
cd /home/agent/projects/lead-machine
tar -xzf /tmp/lead-machine-update.tar.gz && rm /tmp/lead-machine-update.tar.gz
chown -R agent:agent app requirements.txt
docker compose -f docker-compose.prod.yml build app
docker compose -f docker-compose.prod.yml up -d
```
Локальный git-репозиторий (`github.com/slavinbiz/lead-machine`) — источник правды для истории, но сервер синхронизируется вручную тарболлом. Стоит когда-нибудь завести сервер в git (как сделали для vpn-bot), но пока не сделано.

## Команды для перезапуска после правок

```bash
cd /home/agent/projects/lead-machine
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml run --rm app alembic upgrade head   # если были новые миграции
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs app --tail=50   # проверить
```
