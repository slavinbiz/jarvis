# Lead Machine — поиск лидов через Telethon вместо tgstat

**Дата:** 2026-07-05
**Проект:** Lead Machine (github.com/slavinbiz/lead-machine, сервер Beget 91.193.25.237)

## Проблема

`app/finder/scraper.py` искал каналы на tgstat.ru, у которых НАЗВАНИЕ совпадает с триггер-фразой (например канал "ищем smm") — концептуально неверно: нужно ловить людей, которые пишут сообщения с этой фразой прямо сейчас, а не каналы с таким именем. Плюс tgstat.ru закрыт Cloudflare JS-челленджем — обычный HTTP-скрапер (httpx/BeautifulSoup) в принципе не может его пройти.

Telethon-сессия на сервере теперь авторизована (аккаунт `produser_viacheslav`, +79064252045) — можно искать напрямую через Telegram API, без стороннего сайта-агрегатора.

## Решение

### Поиск: `messages.searchGlobal` через Telethon

Переписываю `app/finder/scraper.py`: для каждой из `TRIGGER_KEYWORDS` (9 фраз, без изменений) — один вызов `client(SearchGlobalRequest(q=фраза, filter=InputMessagesFilterEmpty(), offset_rate=0, offset_peer=InputPeerEmpty(), offset_id=0, limit=30))`. Это тот же глобальный поиск, что в приложении Telegram.

Из каждого найденного сообщения (`result.messages`) достаём, сверяясь с сущностями в `result.chats`/`result.users`:
- `trigger_text` — текст сообщения
- `trigger_date` — дата сообщения
- `school_name` — название чата/канала (поле в БД называется исторически `school_name`, переименовывать не будем — не в рамках этой задачи)
- `channel_url` — `https://t.me/<username>` чата, если есть username
- `contact_username` — username автора сообщения (`from_id`), если резолвится
- `subscribers_count` — если у канала в ответе есть `participants_count`, использовать; если нет — 0 (см. ограничение ниже)

Функция `find_leads_by_triggers()` сохраняет прежнюю сигнатуру (список dict) — `app/main.py` не меняется в части вызова, только добавляется автопланировщик (ниже).

### Rate-limiting и обработка ошибок

- Пауза между фразами увеличивается с 2 до 5-7 секунд (`asyncio.sleep`)
- `FloodWaitError` — ловим, спим `e.seconds`, продолжаем со следующей фразы (не роняем весь цикл)
- Прочие исключения на отдельной фразе — логируем и пропускаем, не прерывая обработку остальных фраз (аналогично текущему `except httpx.HTTPError: return []`, но на уровне одной фразы, не всей функции)

### Автозапуск по расписанию

В `app/main.py` добавляется `search_loop()` — фоновая задача по образцу существующего `dispatch_loop()`:
```python
async def search_loop():
    while True:
        await search_and_save_leads()
        await asyncio.sleep(3600)  # раз в час
```
Регистрируется в `lifespan()` через `asyncio.create_task(search_loop())` рядом с существующими задачами. Ручной `POST /search` остаётся как есть — для внепланового запуска.

### Известное ограничение

`MIN_SUBSCRIBERS = 1000` в `app/finder/filters.py` может неправильно отсекать лиды, если `participants_count` не приходит в ответе `searchGlobal` (для мелких чатов/приватных групп это поле часто отсутствует без отдельного `GetFullChannelRequest`, который недёшево дёргать на каждый результат). После первого реального прогона — проверить на живых данных: если фильтр слишком агрессивно режет (например, оставляет 0 лидов при видимых кандидатах в логах) — либо ослабить порог, либо убрать фильтр по подписчикам совсем (оставить только дедупликацию по `channel_url`, которая и так в `filters.py`).

## Изменяемые файлы

- `app/finder/scraper.py` — полностью переписывается на Telethon (убирается httpx/BeautifulSoup/TGSTAT_SEARCH_URL, `TRIGGER_KEYWORDS` остаётся)
- `app/main.py` — добавляется `search_loop()` + регистрация в `lifespan()`
- `app/finder/filters.py` — не трогаем сразу, корректируем по результатам первого прогона при необходимости
- `requirements.txt` — `beautifulsoup4` можно убрать, если больше нигде не используется (проверить перед удалением)

## Тестирование

1. Деплой на сервер (git push → `git pull` на сервере → `docker compose build && up -d`, как обычно для этого проекта)
2. Ручной вызов `POST /search`, смотрим логи (`docker compose logs app`) — должны появиться реальные (не тестовые) лиды с осмысленным `trigger_text`/`contact_username`, не 0 как было с tgstat
3. Проверяем в БД (`SELECT * FROM leads ORDER BY created_at DESC LIMIT 10`) — реалистичные названия каналов, не `durov`/тестовые записи
4. Ждём тикающий автозапуск (следующий час) — убеждаемся, что `search_loop()` сработал сам, без ручного вызова (по логу "Starting lead search..." без предшествующего `POST /search` в логе)
