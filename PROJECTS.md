# Проекты

### Лендинг сантехника
- Стек: Supabase + Telegram-бот
- Статус: в разработке
- Репо: github.com/slavinbiz/viacheslav-digital
- Что дальше: уточнить

### Мини-апп (TMA)
- Стек: Telegram Mini App
- Статус: развёрнут на Vercel
- Репо: github.com/slavinbiz/viacheslav-tma
- Что дальше: уточнить

### Lead Machine
- Стек: Python, aiogram, Telethon, Redis, FastAPI, OpenRouter (Kimi 2.6)
- Статус (2026-06-24): задеплоен на VPS Beget Latvia 91.193.25.237 (тот же сервер, что и Jarvis). FastAPI + dispatch_loop работают, БД и миграции прошли, Telethon-сессия перенесена (уже авторизована). Не работает только Control Bot — TELEGRAM_BOT_TOKEN в .env это плейсхолдер, не настоящий токен
- Репо: github.com/slavinbiz/lead-machine
- Локально: `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine`
- На сервере: `/home/agent/projects/lead-machine` (docker compose, контейнеры app/db/redis)
- Что дальше: **создать Telegram-бота через @BotFather** для Lead Machine (отдельно от Jarvis), вписать токен в `.env` на сервере (`TELEGRAM_BOT_TOKEN=`), перезапустить `docker compose -f docker-compose.prod.yml up -d --build app`
- Детали деплоя — knowledge/lead-machine-deploy.md

### VPN на продажу
- Стек: 3x-ui (личный VPN) + s-ui (для клиентов, multi-user Hysteria2) на TimeWeb 64.188.57.249
- Идея: продавать доступ к VPN по 100₽/мес, контроль — только срок действия (без лимитов трафика)
- Статус (2026-06-16): TLS создан, инбаунд hysteria2-443 на UDP/443 работает (s-ui запущен). Тестовый клиент test-july (пароль JITQrtrP3D, expiry 17.07.2026) создан. Подключение пока не работает — разбираемся с файрволом TimeWeb (три группы у сервера, UDP/443 добавлен в Brainy Cepheus)
- Что дальше (продолжить вечером):
  1. Проверить tcpdump — доходят ли UDP-пакеты на 443 после добавления правила
  2. Если да — тест подключения с ссылкой `hysteria2://JITQrtrP3D@64.188.57.249:443?security=tls&insecure=1&sni=www.bing.com&fastopen=0#hysteria2-443`
  3. Если нет — проверить группы Daring Cepheus и Friendly Vulpecula
  4. Документация в infrastructure.md

## Шаблон проекта

<!-- Копируй этот блок для каждого нового проекта -->
<!--
### Название проекта
- Стек:
- Статус: идея / в разработке / production
- Репо:
- Что дальше:
-->
