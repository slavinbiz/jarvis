# Lead Machine — поиск лидов через Telethon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Заменить поиск лидов на tgstat.ru (закрыт Cloudflare, искал каналы по имени) на поиск сообщений с триггер-фразами через Telegram `messages.searchGlobal` (Telethon), плюс добавить автозапуск по расписанию.

**Architecture:** `app/finder/scraper.py` вызывает `SearchGlobalRequest` через уже авторизованный Telethon-клиент (`app.sender.telethon_client.client`) для каждой из 9 триггер-фраз, сопоставляет найденные сообщения с сущностями (`chats`/`users`) из ответа, возвращает список лидов в прежнем формате dict. `app/main.py` получает фоновую задачу `search_loop()`, вызывающую это раз в час.

**Tech Stack:** Python 3.11, Telethon 1.36.0, FastAPI/asyncio, pytest + pytest-asyncio (asyncio_mode=auto).

## Global Constraints

- Репозиторий: `github.com/slavinbiz/lead-machine`, локально `C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine`, на сервере `/home/agent/projects/lead-machine` (Beget 91.193.25.237)
- Деплой: правка локально → commit → push → на сервере `git pull` → `docker compose -f docker-compose.prod.yml build app && docker compose -f docker-compose.prod.yml up -d`
- Dockerfile делает `COPY . .` — любая правка кода требует пересборки образа (`build`), не только `up -d`
- Тесты гоняются внутри контейнера: `docker compose -f docker-compose.prod.yml run --rm app python -m pytest <путь> -v`
- SSH на сервер: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "команда"`
- `TRIGGER_KEYWORDS` (9 фраз) — не менять
- `find_leads_by_triggers()` должна сохранить сигнатуру `async def find_leads_by_triggers() -> list[dict]` — `app/main.py`'s `search_and_save_leads()` вызывает её без изменений в остальной части

---

### Task 1: Переписать `app/finder/scraper.py` на Telethon-поиск

**Files:**
- Modify: `app/finder/scraper.py` (полностью переписывается)
- Modify: `tests/test_finder.py` (только часть про scraper, тесты `filter_leads` не трогать в этой задаче)
- Modify: `requirements.txt` (убрать `beautifulsoup4==4.12.3`, больше нигде не используется в `app/`)

**Interfaces:**
- Consumes: `app.sender.telethon_client.client` (существующий авторизованный `TelegramClient`, атрибуты `.is_connected()` синхронный, `.connect()` асинхронный, вызов `client(request)` — асинхронный RPC)
- Produces: `async def search_telegram(query: str, limit: int = 30) -> list[dict]`, `async def find_leads_by_triggers() -> list[dict]`, `TRIGGER_KEYWORDS: list[str]` — используются в `app/main.py` (Task 3) без изменений вызова

- [ ] **Step 1: Написать падающие тесты в `tests/test_finder.py`**

Замени верхнюю часть файла (импорт и первый тест — про `search_tgstat`) на:

```python
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from types import SimpleNamespace
from datetime import datetime, timezone
from telethon.tl.types import PeerChannel, PeerUser
from telethon.errors import FloodWaitError
from app.finder.scraper import search_telegram, find_leads_by_triggers, TRIGGER_KEYWORDS


def _fake_message(text, channel_id=100, user_id=200):
    return SimpleNamespace(
        message=text,
        peer_id=PeerChannel(channel_id=channel_id),
        from_id=PeerUser(user_id=user_id),
        date=datetime(2026, 7, 5, tzinfo=timezone.utc),
    )


def _fake_chat(chat_id=100, title="Test Channel", username="testchannel", participants_count=None):
    return SimpleNamespace(id=chat_id, title=title, username=username, participants_count=participants_count)


def _fake_user(user_id=200, username="ivan_petrov"):
    return SimpleNamespace(id=user_id, username=username)


def _mock_client(return_value=None, side_effect=None):
    mock_client = AsyncMock(return_value=return_value, side_effect=side_effect)
    mock_client.is_connected = MagicMock(return_value=True)
    return mock_client


@pytest.mark.asyncio
async def test_search_telegram_extracts_lead_fields():
    fake_result = SimpleNamespace(
        messages=[_fake_message("Ищем технаря в проект")],
        chats=[_fake_chat()],
        users=[_fake_user()],
    )
    with patch("app.finder.scraper.client", _mock_client(return_value=fake_result)):
        results = await search_telegram("ищем технаря")

    assert len(results) == 1
    lead = results[0]
    assert lead["school_name"] == "Test Channel"
    assert lead["channel_url"] == "https://t.me/testchannel"
    assert lead["contact_username"] == "@ivan_petrov"
    assert lead["trigger_text"] == "Ищем технаря в проект"
    assert lead["trigger_date"] == datetime(2026, 7, 5)
    assert lead["subscribers_count"] == 0


@pytest.mark.asyncio
async def test_search_telegram_uses_participants_count_when_available():
    fake_result = SimpleNamespace(
        messages=[_fake_message("Ищем технаря")],
        chats=[_fake_chat(participants_count=5000)],
        users=[_fake_user()],
    )
    with patch("app.finder.scraper.client", _mock_client(return_value=fake_result)):
        results = await search_telegram("ищем технаря")

    assert results[0]["subscribers_count"] == 5000


@pytest.mark.asyncio
async def test_search_telegram_skips_chats_without_username():
    fake_result = SimpleNamespace(
        messages=[_fake_message("Ищем технаря")],
        chats=[_fake_chat(username=None)],
        users=[_fake_user()],
    )
    with patch("app.finder.scraper.client", _mock_client(return_value=fake_result)):
        results = await search_telegram("ищем технаря")

    assert results == []


@pytest.mark.asyncio
async def test_search_telegram_handles_missing_user():
    fake_result = SimpleNamespace(
        messages=[_fake_message("Ищем технаря")],
        chats=[_fake_chat()],
        users=[],
    )
    with patch("app.finder.scraper.client", _mock_client(return_value=fake_result)):
        results = await search_telegram("ищем технаря")

    assert len(results) == 1
    assert results[0]["contact_username"] is None


@pytest.mark.asyncio
async def test_search_telegram_handles_flood_wait():
    with patch("app.finder.scraper.client", _mock_client(side_effect=FloodWaitError(request=None, capture=5))), \
         patch("app.finder.scraper.asyncio.sleep", new=AsyncMock()) as mock_sleep:
        results = await search_telegram("ищем технаря")

    assert results == []
    mock_sleep.assert_called_once_with(5)


@pytest.mark.asyncio
async def test_find_leads_by_triggers_dedupes_across_keywords():
    fake_result = SimpleNamespace(
        messages=[_fake_message("Ищем технаря")],
        chats=[_fake_chat()],
        users=[_fake_user()],
    )
    with patch("app.finder.scraper.client", _mock_client(return_value=fake_result)), \
         patch("app.finder.scraper.asyncio.sleep", new=AsyncMock()):
        results = await find_leads_by_triggers()

    assert len(results) == 1  # тот же channel_url найден по всем 9 фразам, но сохранён один раз


def test_trigger_keywords_unchanged():
    assert len(TRIGGER_KEYWORDS) == 9
    assert "ищем технаря" in TRIGGER_KEYWORDS
```

Удали старый `test_search_tgstat_returns_channels` и константу `MOCK_HTML` (они больше не соответствуют коду) — оставь в файле ниже только существующие тесты `filter_leads` (`test_filter_removes_small_channels`, `test_filter_removes_duplicates`) без изменений, они будут поправлены в Task 2.

- [ ] **Step 2: Запустить тесты, убедиться что падают**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "cd /home/agent/projects/lead-machine && docker compose -f docker-compose.prod.yml run --rm app python -m pytest tests/test_finder.py -v"`

Expected: FAIL с `ImportError: cannot import name 'search_telegram' from 'app.finder.scraper'` (функции ещё не существует)

- [ ] **Step 3: Переписать `app/finder/scraper.py`**

```python
import asyncio
import logging
from telethon.tl.functions.messages import SearchGlobalRequest
from telethon.tl.types import InputMessagesFilterEmpty, InputPeerEmpty, PeerChannel, PeerUser
from telethon.errors import FloodWaitError
from app.sender.telethon_client import client

logger = logging.getLogger(__name__)

TRIGGER_KEYWORDS = [
    "ищем технаря", "нужен технический специалист", "ищем специалиста",
    "настройка воронки", "нужен разработчик", "ищем smm", "ищем таргетолога",
    "нужна автоматизация", "ищем технического продюсера",
]


async def search_telegram(query: str, limit: int = 30) -> list[dict]:
    if not client.is_connected():
        await client.connect()

    try:
        result = await client(SearchGlobalRequest(
            q=query,
            filter=InputMessagesFilterEmpty(),
            min_date=None,
            max_date=None,
            offset_rate=0,
            offset_peer=InputPeerEmpty(),
            offset_id=0,
            limit=limit,
        ))
    except FloodWaitError as e:
        logger.warning(f"FloodWait on query '{query}': sleeping {e.seconds}s")
        await asyncio.sleep(e.seconds)
        return []
    except Exception as e:
        logger.warning(f"Search error for '{query}': {e}")
        return []

    chats_by_id = {c.id: c for c in result.chats}
    users_by_id = {u.id: u for u in result.users}

    results = []
    for m in result.messages:
        if not m.message:
            continue

        chat = chats_by_id.get(m.peer_id.channel_id) if isinstance(m.peer_id, PeerChannel) else None
        if not chat or not chat.username:
            continue

        user = users_by_id.get(m.from_id.user_id) if isinstance(m.from_id, PeerUser) else None

        results.append({
            "school_name": chat.title,
            "channel_url": f"https://t.me/{chat.username}",
            "contact_username": f"@{user.username}" if user and user.username else None,
            "trigger_text": m.message,
            "trigger_date": m.date.replace(tzinfo=None) if m.date else None,
            "subscribers_count": chat.participants_count or 0,
        })

    return results


async def find_leads_by_triggers() -> list[dict]:
    all_results = []
    seen_urls: set[str] = set()
    for keyword in TRIGGER_KEYWORDS:
        results = await search_telegram(keyword)
        for r in results:
            url = r.get("channel_url", "")
            if url and url not in seen_urls:
                seen_urls.add(url)
                all_results.append(r)
        await asyncio.sleep(6)  # rate limit: 6s between запросами, чтобы не словить FloodWait/бан аккаунта
    return all_results
```

Удали из `requirements.txt` строку `beautifulsoup4==4.12.3`.

- [ ] **Step 4: Запустить тесты, убедиться что проходят**

Run: тот же plink-запуск pytest из Step 2

Expected: `7 passed` (6 новых + `test_trigger_keywords_unchanged`), плюс два старых теста `filter_leads` из этого же файла тоже должны быть в выводе (пока не тронуты, Task 2)

- [ ] **Step 5: Закоммитить**

```bash
cd "C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine"
git add app/finder/scraper.py tests/test_finder.py requirements.txt
git commit -m "feat: поиск лидов через Telethon messages.searchGlobal вместо tgstat"
```

---

### Task 2: Упростить `app/finder/filters.py` — убрать фильтр по подписчикам

**Files:**
- Modify: `app/finder/filters.py`
- Modify: `tests/test_finder.py` (тесты `filter_leads`)

**Interfaces:**
- Consumes: ничего нового
- Produces: `def filter_leads(leads: list[dict]) -> list[dict]` — сигнатура не меняется, используется в `app/main.py:search_and_save_leads` без изменений

**Почему:** проверено на живых данных 2026-07-05 — `chat.participants_count` в ответе `searchGlobal` почти всегда `None` для групп/чатов (не для broadcast-каналов с полной статистикой). Фильтр `MIN_SUBSCRIBERS=1000` при `subscribers_count=0` (см. Task 1, `chat.participants_count or 0`) отсекал бы все реальные лиды. Оставляем только дедупликацию по `channel_url`.

- [ ] **Step 1: Обновить тест в `tests/test_finder.py`**

Замени:
```python
def test_filter_removes_small_channels():
    leads = [
        {"school_name": "Big School", "channel_url": "https://t.me/big", "subscribers_count": 5000},
        {"school_name": "Tiny Blog", "channel_url": "https://t.me/tiny", "subscribers_count": 200},
    ]
    result = filter_leads(leads)
    assert len(result) == 1
    assert result[0]["school_name"] == "Big School"
```
на:
```python
def test_filter_keeps_leads_regardless_of_subscriber_count():
    leads = [
        {"school_name": "Big School", "channel_url": "https://t.me/big", "subscribers_count": 5000},
        {"school_name": "Unknown Count", "channel_url": "https://t.me/unknown", "subscribers_count": 0},
    ]
    result = filter_leads(leads)
    assert len(result) == 2
```
(`test_filter_removes_duplicates` не трогать, остаётся как есть)

- [ ] **Step 2: Запустить тесты, убедиться что новый тест падает**

Run: тот же plink pytest запуск из Task 1

Expected: FAIL — `test_filter_keeps_leads_regardless_of_subscriber_count` показывает `assert 1 == 2` (старый фильтр по 1000 подписчиков всё ещё режет "Unknown Count" с `subscribers_count=0`)

- [ ] **Step 3: Убрать фильтр по подписчикам**

```python
def filter_leads(leads: list[dict]) -> list[dict]:
    seen_urls = set()
    result = []
    for lead in leads:
        url = lead.get("channel_url", "")
        if url in seen_urls:
            continue
        seen_urls.add(url)
        result.append(lead)
    return result
```

- [ ] **Step 4: Запустить тесты, убедиться что все проходят**

Run: тот же plink pytest запуск

Expected: все тесты в `tests/test_finder.py` PASSED (9 штук: 6 из Task 1 + `test_trigger_keywords_unchanged` + 2 из этой задачи)

- [ ] **Step 5: Закоммитить**

```bash
cd "C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine"
git add app/finder/filters.py tests/test_finder.py
git commit -m "fix: убрать фильтр по подписчикам — searchGlobal почти всегда не отдаёт participants_count"
```

---

### Task 3: Автозапуск поиска по расписанию в `app/main.py`

**Files:**
- Modify: `app/main.py`
- Create: `tests/test_search_loop.py`

**Interfaces:**
- Consumes: `search_and_save_leads()` (уже определена в `app/main.py`, не меняется)
- Produces: `async def search_loop()` — регистрируется как фоновая задача в `lifespan()`, наружу не экспортируется/не используется другими модулями

- [ ] **Step 1: Написать падающий тест в `tests/test_search_loop.py`**

```python
import pytest
from unittest.mock import AsyncMock, patch
from app.main import search_loop


@pytest.mark.asyncio
async def test_search_loop_calls_search_and_save_leads_then_sleeps():
    with patch("app.main.search_and_save_leads", new=AsyncMock()) as mock_search, \
         patch("app.main.asyncio.sleep", new=AsyncMock(side_effect=[None, StopAsyncIteration])):
        with pytest.raises(StopAsyncIteration):
            await search_loop()

    assert mock_search.call_count == 2
```

- [ ] **Step 2: Запустить тест, убедиться что падает**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "cd /home/agent/projects/lead-machine && docker compose -f docker-compose.prod.yml run --rm app python -m pytest tests/test_search_loop.py -v"`

Expected: FAIL — `ImportError: cannot import name 'search_loop' from 'app.main'`

- [ ] **Step 3: Добавить `search_loop()` в `app/main.py`**

Добавь функцию сразу после существующей `dispatch_loop()` (перед `@asynccontextmanager`):

```python
async def search_loop():
    while True:
        await search_and_save_leads()
        await asyncio.sleep(3600)  # раз в час
```

Обнови `lifespan()`, добавив третий `create_task` (файл сейчас содержит два — `dispatch_loop` и `dp.start_polling`):

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    asyncio.create_task(dispatch_loop())
    asyncio.create_task(search_loop())
    asyncio.create_task(dp.start_polling(get_bot()))
    yield
```

- [ ] **Step 4: Запустить тест, убедиться что проходит**

Run: тот же plink-запуск из Step 2

Expected: `1 passed`

- [ ] **Step 5: Закоммитить**

```bash
cd "C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine"
git add app/main.py tests/test_search_loop.py
git commit -m "feat: автоматический поиск лидов раз в час (search_loop)"
```

---

### Task 4: Деплой на сервер и проверка на живых данных

**Files:** нет изменений кода — только деплой и верификация

**Interfaces:** нет (финальная проверка всей цепочки)

- [ ] **Step 1: Запушить все три коммита**

```bash
cd "C:\Users\User\Documents\ИИ и прочее\lid-mashine\lead-machine"
git push origin main
```

- [ ] **Step 2: Обновить код на сервере и пересобрать образ**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "cd /home/agent/projects/lead-machine && git pull && docker compose -f docker-compose.prod.yml build app"`

Expected: `Image lead-machine-app Built` без ошибок

- [ ] **Step 3: Перезапустить и убедиться что стартует без ошибок**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "cd /home/agent/projects/lead-machine && docker compose -f docker-compose.prod.yml up -d && sleep 8 && docker compose -f docker-compose.prod.yml logs app --tail=20"`

Expected: `Application startup complete`, `Run polling for bot @SlavinLeads_bot`, никаких traceback

- [ ] **Step 4: Вручную вызвать поиск и проверить реальные лиды**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "curl -s -m 10 -X POST http://localhost:8000/search && sleep 75 && cd /home/agent/projects/lead-machine && docker compose -f docker-compose.prod.yml logs app --tail=15"`

Expected: в логах строка `Saved N new leads` с N > 0 (реальный поиск занимает ~9×6сек пауз между фразами = ~1 минута, отсюда `sleep 75`)

- [ ] **Step 5: Проверить содержимое базы**

Run: `"/c/Program Files/PuTTY/plink" -ssh -batch -hostkey "SHA256:TZAJK5jnGtdsay1IOax4sdWYmYdM65fO5t94v/w2ays" -pw 'uB4Z5DrT~c~s' root@91.193.25.237 "cd /home/agent/projects/lead-machine && docker compose -f docker-compose.prod.yml exec -T db psql -U lead -d lead_machine -c \"SELECT school_name, channel_url, contact_username, left(trigger_text,50) FROM leads ORDER BY created_at DESC LIMIT 10;\""`

Expected: реалистичные названия каналов/чатов (не `durov`/тестовые записи из старого деплоя), непустой `trigger_text` с реальным текстом сообщения

- [ ] **Step 6: Обновить дневник и MEMORY.md**

Добавь в `memory/2026-07-05.md` (или создай, если файла ещё нет за сегодня) раздел с итогом: Telethon-поиск лидов задеплоен и подтверждён рабочим на реальных данных, автозапуск раз в час. Обнови `PROJECTS.md` в jarvis-репозитории — секцию Lead Machine, статус "Что дальше" (убрать пункт про TELEGRAM_API_ID/HASH, он закрыт).

```bash
cd "c:\Users\User\Documents\ИИ и прочее\вайбкодинг\Дмитрий Ледовских-курс\jarvis"
git add memory/2026-07-05.md PROJECTS.md
git commit -m "diary: Lead Machine — Telethon-поиск лидов задеплоен и работает на реальных данных"
git push origin main
```

## Спек-ревью (самопроверка)

1. **Покрытие спека:** поиск через `searchGlobal` — Task 1; rate-limiting/FloodWait — Task 1 (в самой функции + тест); автозапуск — Task 3; известное ограничение по подписчикам — Task 2 (решено, не отложено); тестирование на живых данных — Task 4. Всё покрыто.
2. **Плейсхолдеры:** отсутствуют, весь код — рабочий, проверен вручную на сервере перед написанием плана (реальный вызов `SearchGlobalRequest` с реальными данными).
3. **Типы/сигнатуры:** `search_telegram(query: str, limit: int = 30) -> list[dict]` и `find_leads_by_triggers() -> list[dict]` используются одинаково в Task 1 и Task 3 (через `search_and_save_leads`, которая не меняется). `filter_leads(leads: list[dict]) -> list[dict]` не меняет сигнатуру между Task 1 и Task 2.
