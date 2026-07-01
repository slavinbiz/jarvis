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
- Статус (2026-06-28): задеплоен на VPS Beget Latvia 91.193.25.237 (тот же сервер, что и Jarvis). Control Bot `@SlavinLeads_bot` запущен и отвечает на `/start`. Не работает: отправка сообщений лидам через Telethon — `TELEGRAM_API_ID/HASH` не получены, поля-заглушки
- Репо: github.com/slavinbiz/lead-machine
- Локально: `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine`
- На сервере: `/home/agent/projects/lead-machine` (docker compose, контейнеры app/db/redis)
- Что дальше: получить `TELEGRAM_API_ID/HASH` (my.telegram.org), проверить команды `/leads /queue /dialogs /stats /search`, первый прогон Finder/Dispatcher на реальных лидах
- Детали деплоя — knowledge/lead-machine-deploy.md

### VPN-бот (продажа VPN)
- Стек: s-ui (multi-user Hysteria2) на TimeWeb 64.188.57.249, бот на aiogram 3.x — `@djarvisvpn_bot`, код `C:\Users\User\projects\vpn-bot\`
- Статус (2026-07-01): **запущен и продаёт** — триал 3 дня, 150₽/мес, реферальная программа (+7 дней за друга). В базе s-ui реальные клиенты (`vpnbot_888224075`, `vpnbot_6124820268`, `vpnbot_1120620453`)
- Баг `enable=0` у новых клиентов s-ui — пофикшен 2026-06-25 SQL-триггером `fix_enable_on_insert` (автоматически ставит `enable=1` при INSERT). Больше не блокер
- Продвижение: органика через @santex_ai + реферальная программа (реклама VPN в РФ ограничена)
- Что дальше: следить за конверсией триал→платный, посты в @santex_ai

### Бот-репетитор
- Стек: Python + aiogram + DeepSeek (код) + Claude Haiku / GPT-4o mini (ответы)
- Статус: идея
- Целевая аудитория: 7 класс — математика, русский язык, история
- Что дальше: составить ТЗ, написать код через DeepSeek

## Шаблон проекта

<!-- Копируй этот блок для каждого нового проекта -->
<!--
### Название проекта
- Стек:
- Статус: идея / в разработке / production
- Репо:
- Что дальше:
-->
