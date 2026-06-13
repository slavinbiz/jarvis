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

1. **Сайт** (`slavinbiz/viacheslav-digital`) — лендинг сантехника. HTML + Tailwind CDN, Supabase для заявок, Telegram-бот для уведомлений. Локально: `C:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\my project`
2. **Мини-апп** (`slavinbiz/viacheslav-tma`) — Telegram Mini App мастера. Онбординг, бриф-форма, dashboard. Развёрнут: `viacheslav-tma.vercel.app`
3. **Крипто-бот Pamp-Damp** — сигнальный бот Binance. WebSocket все USDT-пары, памп/дамп 6%+. Сервер: TimeWeb `64.188.57.249`. Локально: `C:\crypto_bot\`
4. **Lead Machine** (`slavinbiz/lead-machine`) — TGstat scraper + AI-диалоги (Kimi) + очередь Redis. Задеплоен на Beget 91.193.25.237 (2026-06-24), не хватает реального TELEGRAM_BOT_TOKEN для Control Bot (нужно завести бота через @BotFather). Детали: knowledge/lead-machine-deploy.md. Локально: `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine`

---

## Инфраструктура

- **Beget Latvia** — 91.193.25.237 — Jarvis-бот + Lead Machine (docker compose). Оплата ~17-го, напоминание 12-го. Доступ — root-пароль (спросить у Вячеслава), подключение с этого компа через PuTTY plink/pscp (нет ключа, нет expect)
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
- **Что бесит в общении ИИ:**
  - Подхалимаж и шаблонные фразы: «Отличный вопрос!», «Конечно!», «Давай разберёмся!»
  - Длинные ответы из 5+ пунктов, когда хватит меньше
  - Повторять вопрос перед ответом
  - «Если нужна помощь — обращайтесь» и подобные штампы
  - Размытые «может быть, возможно» — если не уверен, скажи прямо

---

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

## Ссылки на knowledge/

- [n8n-telegram-bot-template.md](knowledge/n8n-telegram-bot-template.md) — шаблон n8n Telegram-бота с мультиагентностью
- [n8n-skazochnik-template.md](knowledge/n8n-skazochnik-template.md) — генератор длинного контента по главам
- [n8n-article-generator-template.md](knowledge/n8n-article-generator-template.md) — двухшаговый диалог + статьи с иллюстрациями
- [n8n-negotiator-template.md](knowledge/n8n-negotiator-template.md) — сессионный roleplay-бот
- [vibe-coding-2026.md](knowledge/vibe-coding-2026.md) — как топ-вайбкодеры строят в 2026
- [infrastructure.md](knowledge/infrastructure.md) — все облачные сервисы: серверы, цены, даты оплаты
- [lead-machine-deploy.md](knowledge/lead-machine-deploy.md) — деплой Lead Machine на Beget: доступ, проблемы и фиксы, команды перезапуска

---

## Правила работы с этим файлом (для Агента)

- **Дописывай в конец нужного раздела**, не переписывай файл целиком.
- **Файл ≤ 200 строк.** Если разрастается — консолидируй.
- **Дневные заметки** идут в `memory/YYYY-MM-DD.md`, не сюда.
- **Большие справочники** идут в `knowledge/`, не сюда.
- **Перед каждой сессией** — перечитай этот файл.
