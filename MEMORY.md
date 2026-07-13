# MEMORY.md — долгосрочная память Агента

> Что Агент знает обо мне на длинной дистанции: профиль, проекты, инфраструктура, стек, предпочтения. Читается в начале каждой сессии. Лимит — 200 строк.

---

## Кто я

- **Имя:** Вячеслав
- **Роль:** Сантехник в найме, осваивает ИИ и вайбкодинг
- **Чем занимаюсь:** Работаю сантехником по найму, параллельно изучаю ИИ-инструменты и начинаю писать боты и сайты с нуля.

## Контакты и аккаунты

*Пока пусто.*

---

## Активные проекты

5. **VPN-бот** (`@djarvisvpn_bot`) — продажа Hysteria2+Trojan VPN (единый профиль, автопереключение). Триал 3 дня, 150 ₽/мес, реферальная программа (+7 дней за друга). Сервер: TimeWeb `64.188.57.249` (`/root/vpn-bot`, systemd `vpn-bot`). Код: `C:\Users\User\projects\vpn-bot\`, репозиторий `github.com/slavinbiz/vpn-bot` (приватный) — деплой через git push/pull, НЕ scp. Продвижение: органика через @santex_ai + реферальная программа (реклама VPN в РФ ограничена).

1. **Сайт** (`slavinbiz/viacheslav-digital`) — лендинг. Развёрнут: `www.demin.digital` (Vercel `viacheslav-digital.vercel.app`). HTML + Tailwind CDN, Supabase для заявок, Telegram-бот для уведомлений. Локально: `C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\my project`
2. **Мини-апп** (`slavinbiz/viacheslav-tma`) — Telegram Mini App мастера. Онбординг, бриф-форма, dashboard. Развёрнут: `viacheslav-tma.vercel.app`
3. **Крипто-бот Pamp-Damp** — сигнальный бот Binance. WebSocket все USDT-пары, памп/дамп 6%+. Сервер: TimeWeb `64.188.57.249`. Локально: `C:\crypto_bot\` (свой git-репозиторий, ветка `master`, без GitHub remote — деплой на сервер через scp одного файла). С 2026-07-12 под systemd (`crypto-bot.service`, автоперезапуск) — раньше стоял без присмотра через screen и падал незамеченным. Добавлен EMA-фильтр тренда: к каждому сигналу подмешивается вердикт 🟢/🟡/🔴/⚪ по тренду 1H (EMA50/EMA200) и положению цены к EMA20 на 15m, помогает решить стоит ли входить в сделку. Порог настраивается в `bot_settings.json` (`EMA_DISTANCE_THRESHOLD_PCT`). С 2026-07-13 — автопроверка сигналов: через 15/60/240 мин после сигнала бот сам сверяет цену и шлёт в Telegram, пошла ли она в сторону сигнала (заменяет ручную сверку с TradingView). Детали — knowledge/infrastructure.md
4. **Lead Machine** (`slavinbiz/lead-machine`) — TGstat scraper + AI-диалоги (Kimi) + очередь Redis. Задеплоен на Beget с 2026-06-24 (docker compose, `/home/agent/projects/lead-machine`), детали в knowledge/lead-machine-deploy.md. Локально: `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine`. **С 2026-07-13 нет автоотправки** — после жалобы получателя аккаунт-отправитель словил блок на 3 дня. Теперь любое сообщение (первое и ответы) уходит черновиком в бот `@SlavinLeads_bot` с кнопками Отправить/Стоп, реальная отправка только вручную. Детали в дневнике `memory/2026-07-13.md`

---

## Инфраструктура

- **Beget Latvia** — 91.193.25.237 — Jarvis-бот (этот сервер). Оплата ~17-го, напоминание 12-го.
- **TimeWeb** — 64.188.57.249 — крипто-бот Pamp-Damp. Оплата ~16-го, напоминание 11-го.
- **Vercel** — мини-апп `viacheslav-tma.vercel.app`

## Пути к проектам на компьютере

| Проект | Путь |
|--------|------|
| Jarvis | `C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis` |
| Сайт | `C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\my project` |
| Мини-апп | `C:\Users\User\Documents\viacheslav-tma` |
| Крипто-бот | `C:\crypto_bot\` |
| Lead Machine | `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine` |

---

## Стек и инструменты

- **Frontend:** HTML + Tailwind CDN (один файл) — сайт и мини-апп
- **Backend/боты:** Python (крипто-бот, Lead Machine), Node.js/Grammy (Jarvis-бот)
- **AI:** Kimi 2.6 via OpenRouter (Lead Machine), Gemini via Polza API (n8n боты)
- **БД:** Supabase (сайт), PostgreSQL + Redis (Lead Machine)
- **Telegram API:** Binance Public API + WebSocket (крипто-бот), Telethon (Lead Machine)

---

## Предпочтения

- **Обращение:** ты
- **Стиль ответов:** Ответ + краткое пояснение в 2-3 предложения. Сначала суть, потом контекст если нужен.
- **Язык общения:** Русский для общения, английский для кода и всего связанного с разработкой
- **Канал @santex_s_ai:** заголовок поста всегда жирным (`<b>`), эмодзи в тексте, публикация через @dgarvise_bot (он админ канала)
- **Что бесит в общении ИИ:**
  - Подхалимаж и шаблонные фразы: «Отличный вопрос!», «Конечно!», «Давай разберёмся!»
  - Длинные ответы из 5+ пунктов, когда хватит меньше
  - Повторять вопрос перед ответом
  - «Если нужна помощь — обращайтесь» и подобные штампы
  - Размытые «может быть, возможно» — если не уверен, скажи прямо

---

## VPN-бот / s-ui — критичное правило

- **НИКОГДА не писать JSON в blob-колонки s-ui (`options`, `out_json`, `config` в таблицах `inbounds`/`clients`) через сырой `sqlite3` без `CAST(... AS BLOB)`** — иначе Go-driver падает на `sql: Scan error ... unsupported Scan, storing driver.Value type string into type *json.RawMessage`, ядро Hysteria2 не стартует, VPN лежит у всех (личный + все клиенты бота). Ломалось так дважды (1 и 2 июля 2026) — подробности knowledge/s-ui-sqlite-editing.md
- Меняя конфиг Hysteria2 (obfs и т.п.) на сервере — обновлять ВСЕ клиенты одновременно (свой Windows-туннель + шаблон клиента VPN-бота), иначе рвёт текущие подключения
- Параллельно с этим компьютером Jarvis работает ещё и через Telegram-бота на Beget — та сессия тоже может лезть в TimeWeb/s-ui. Перед правками VPN-инфры сверяться со свежими дневниками memory/

## VPN-бот — технические детали

- s-ui REST API авторизация не работает → прямой доступ к SQLite `/usr/local/s-ui/db/s-ui.db`
- После изменений в SQLite — `systemctl restart s-ui` (функция `_reload_sui()` в sui.py)
- Hysteria2 inbound ID=1, порт 443, тег `hysteria2-443`
- Клиенты идентифицируются по `name = vpnbot_<user_id>`
- Telegraph инструкция: https://telegra.ph/Kak-podklyuchit-Jarvis-VPN-06-27
- Тестовый клиент `test-july` пароль `JITQrtrP3D` — не удалять

## Ключевые решения

- **Google Calendar:** MCP tools нестабильны на VPS — используем прямой REST API с Bearer токеном. Токен обновлять в начале каждой сессии (протухает за ~60 мин).
- **Голосовые сообщения:** работают через Jarvis-бот, транскрибируются корректно — можно диктовать задачи и события календаря.
- **Ежемесячные напоминалки:** manage-schedule.js не поддерживает `monthly`, создано 12 событий `once` на каждый месяц (Beget 12-го, TimeWeb 11-го).
- **Репетитор-бот:** DeepSeek пишет код (экономия токенов), Claude Haiku/GPT-4o mini отвечает ученику. Стек: Python + aiogram.

---

## Установка и настройка

- **2026-05-24** — Установлена архитектура Агента из `Ntmib/jarvis-architect`. Репозиторий: `github.com/slavinbiz/jarvis`.
- **2026-05-24** — Установлены скиллы: `discovery-interview`, `content-creator`, `fullstack-developer`, `frontend-design`. Активирован плагин `superpowers`.

---

## Google Calendar

- **Аккаунт:** slavin507@gmail.com
- **4 календаря:** slavin507@gmail.com, Семейная группа, Агентство «Голосовые решения», Todoist
- **Токен:** ключ `google-calendar|579e90e4bdd6e384` в `/home/agent/.claude/.credentials.json`
- **Refresh:** `client_id=950211183011-relma4bf08ipm9git59iigr9fmj9b64e.apps.googleusercontent.com` + `clientSecret` из `mcpOAuthClientConfig[579e90e4bdd6e384]` → POST `https://oauth2.googleapis.com/token`
- **События:** прямой запрос к Google Calendar REST API (MCP tools пока нестабильны на VPS)
- **Токен истекает** каждые ~60 мин — обновлять через refresh в начале каждой сессии

## SSH-доступ к серверам

- На Windows-машине есть ключ `~/.ssh/id_ed25519` — прямой root-доступ без пароля на **обе** машины: TimeWeb `64.188.57.249` и Beget `91.193.25.237`. Не нужен plink/пароль (устаревшая инфа в старых дневниках) — просто `ssh -i ~/.ssh/id_ed25519 root@<ip>`.

- **OAuth-токен Claude Code на Beget может не обновиться сам** и уйти в 401 на все сообщения бота — чинить через полный релогин (`claude auth login --claudeai` в `tmux`, код авторизации даёт Вячеслав), не через ручной refresh (быстро rate-limit). Инцидент 2026-07-01, детали в дневнике.

## Ключевые решения (Windows)

- **Claude Code на Windows:** запускать из отдельного PowerShell (не VS Code terminal), с явным `$env:HTTPS_PROXY = "http://127.0.0.1:10810"`, из папки jarvis. Туннель Hysteria2 на порту 10810 обязателен.
- **Быстрый запуск:** ярлык «Claude Code» на рабочем столе → `scripts/start-claude.ps1` (сам поднимает туннель, выставляет прокси, стартует `claude`).
- **VS Code расширение Claude Code:** не работает (403 geo-block). Только CLI.
- **`.ps1` с кириллицей:** сохранять как UTF-8 с BOM, иначе Windows PowerShell 5.1 ломает русские буквы в пути/тексте и скрипт не парсится.

## Ссылки на knowledge/

- [n8n-telegram-bot-template.md](knowledge/n8n-telegram-bot-template.md) — шаблон n8n Telegram-бота с мультиагентностью
- [n8n-skazochnik-template.md](knowledge/n8n-skazochnik-template.md) — генератор длинного контента по главам
- [n8n-article-generator-template.md](knowledge/n8n-article-generator-template.md) — двухшаговый диалог + статьи с иллюстрациями
- [n8n-negotiator-template.md](knowledge/n8n-negotiator-template.md) — сессионный roleplay-бот
- [vibe-coding-2026.md](knowledge/vibe-coding-2026.md) — как топ-вайбкодеры строят в 2026
- [infrastructure.md](knowledge/infrastructure.md) — все облачные сервисы: серверы, цены, даты оплаты
- [claude-code-windows.md](knowledge/claude-code-windows.md) — как запускать Claude Code на Windows через Hysteria2 туннель
- [s-ui-sqlite-editing.md](knowledge/s-ui-sqlite-editing.md) — как править базу s-ui через sqlite3, не роняя VPN (BLOB vs TEXT баг)
- [telegram-post-templates.md](knowledge/telegram-post-templates.md) — шаблон постов о продаже продукта в @santex_s_ai + разбор способов оплаты для самозанятого (ЮMoney, Продамус)
- [ai-agent-repos.md](knowledge/ai-agent-repos.md) — 33 open-source репозитория AI-агентов по категориям (фреймворки, coding agents, MCP, память, инструменты) — референс для архитектурных решений

---

## Правила работы с этим файлом (для Агента)

- **Дописывай в конец нужного раздела**, не переписывай файл целиком.
- **Файл ≤ 200 строк.** Если разрастается — консолидируй.
- **Дневные заметки** идут в `memory/YYYY-MM-DD.md`, не сюда.
- **Большие справочники** идут в `knowledge/`, не сюда.
- **Перед каждой сессией** — перечитай этот файл.
