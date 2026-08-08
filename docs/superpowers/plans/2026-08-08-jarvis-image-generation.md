# Генерация картинок к постам для Jarvis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Jarvis (Telegram-бот `@dgarvise_bot`) умеет по просьбе в чате сгенерировать иллюстрацию к посту через бесплатный Pollinations.ai и прислать её тегом `[ФОТО: путь]`.

**Architecture:** Никакого кода не пишем. Добавляем один знание-файл `knowledge/image-generation.md`, который Jarvis читает как инструкцию и исполняет через свой штатный Bash-инструмент (curl + node для urlencode). Существующий парсер медиа-тегов в `bot/index.js` (`extractMediaTags`/`sendMediaItem`) уже умеет отправлять файл по тегу `[ФОТО: путь]` — трогать его не нужно.

**Tech Stack:** Markdown (knowledge-файл), Bash/curl/node (исполняется самим Jarvis на сервере в момент запроса), Pollinations.ai HTTP API.

## Global Constraints

- НЕ менять `bot/index.js`, `bot/secrets-menu.js` и любой другой код бота — `~/.agent/bot/` read-only зона для агента, плюс `/update` перезатирает `bot/` из апстрима
- НЕ трогать `.env` / секреты — вне зоны допуска агента
- Сервис — Pollinations.ai, без API-ключа, без карты (см. спеку `docs/superpowers/specs/2026-08-08-jarvis-image-generation-design.md`)
- Генерация — только по явной просьбе в чате, не автоматически на каждый пост
- Файл сохранять в `/home/agent/workspace/.media/` (та же папка, что и входящие медиа)
- Формат коммитов: `[agent] action: описание`, MEMORY.md ≤ 200 строк — при добавлении строки проверить, что лимит не превышен

---

### Task 1: Знание для Jarvis — `knowledge/image-generation.md`

**Files:**
- Create: `knowledge/image-generation.md`

**Interfaces:**
- Produces: markdown-документ, который Jarvis подгружает как контекст (через `knowledge/`-конвенцию проекта, ничего программно не парсит — просто файл, который агент читает по необходимости)

- [ ] **Step 1: Написать файл `knowledge/image-generation.md`**

```markdown
# Генерация картинок к постам (Pollinations.ai)

Читать, когда Вячеслав просит сделать картинку/иллюстрацию к посту или к сообщению в чат.

## Когда использовать

- Только по прямой просьбе в чате: «сделай картинку к посту», «сгенерируй иллюстрацию», «нарисуй картинку» и т.п.
- НЕ генерировать автоматически к каждому посту в @santex_s_ai — это лишний расход времени/лимитов без спроса
- Публикации в канал у бота нет — картинка присылается в личный чат, дальше Вячеслав постит сам (как и с текстом поста сейчас)

## Как составить промпт

- Промпт для Pollinations — на английском (модели понимают английский лучше)
- Описывай сцену по смыслу поста конкретно: кто/что изображено, стиль (flat illustration / photo-realistic / minimalist icon), настроение
- НЕ рассчитывай на читаемый текст, логотипы или интерфейсы с текстом на картинке — модель flux рисует текст криво, в промпте не проси конкретных надписей
- Пример хорошего промпта: `cheerful middle-aged plumber sitting at a laptop with glowing AI icons around him, flat illustration style, warm colors, no text`

## Команда генерации

Url-encode промпта делай через node (он уже есть на сервере — рантайм самого бота), не вручную:

```bash
PROMPT_ENC=$(node -e "process.stdout.write(encodeURIComponent(process.argv[1]))" "cheerful middle-aged plumber sitting at a laptop with glowing AI icons around him, flat illustration style, warm colors, no text")

OUT="/home/agent/workspace/.media/generated_$(date +%s).jpg"

curl -sfL -o "$OUT" \
  "https://image.pollinations.ai/prompt/${PROMPT_ENC}?width=1280&height=720&model=flux&nologo=true"
```

Параметры:
- `width=1280&height=720` — формат под Telegram-пост (16:9), можно менять под задачу
- `model=flux` — модель по умолчанию, универсальная
- `nologo=true` — уменьшает шанс водяного знака (не гарантирует без регистрации)
- Анонимный лимит Pollinations — 1 запрос / 15 секунд, для разовой картинки к посту достаточно

## Проверка перед отправкой

`curl -sfL` уже упадёт с ненулевым кодом выхода при HTTP-ошибке (флаг `-f`). Дополнительно проверь, что файл реально картинка, а не пустышка:

```bash
file "$OUT"
```

Ожидается что-то вроде `JPEG image data`. Если curl вернул ошибку или `file` показывает не картинку — скажи прямо, что генерация не удалась, не выдумывай, что картинка готова.

## Прикрепление к ответу

В финальном сообщении добавь тег на отдельной строке — бот сам отправит файл в чат:

```
[ФОТО: /home/agent/workspace/.media/generated_1234567890.jpg]
```

Путь должен быть ровно тот, что вернул `$OUT` в команде выше (реальный путь скачанного файла, не выдуманный).

## Если нужно качество выше или без водяного знака

Это бесплатный вариант с ограничениями (иногда логотип, иногда неидеальная композиция). Если станет мешать — есть запасной план на Polza API (Gemini 2.5 Flash Image, ~3-4₽/картинку, нужна регистрация с картой на polza.ai по реферальной ссылке `https://polza.ai/?referral=rk4YP1eJRj`, ключ кладётся в `.env` вручную Вячеславом). Не переключаться на него самостоятельно — спросить, готов ли Вячеслав завести аккаунт.
```

- [ ] **Step 2: Проверить, что файл создан и не пустой**

Run: `wc -l knowledge/image-generation.md`
Expected: число строк > 0 (документ не пустой, порядка 40-55 строк)

- [ ] **Step 3: Commit**

```bash
git add knowledge/image-generation.md
git commit -m "[agent] feat: знание для Jarvis — генерация картинок к постам через Pollinations.ai"
```

---

### Task 2: Ссылка из MEMORY.md + актуализация решения

**Files:**
- Modify: `MEMORY.md` (раздел «Ссылки на knowledge/», раздел «Ключевые решения»)

**Interfaces:**
- Consumes: путь `knowledge/image-generation.md` из Task 1 (файл уже должен существовать)

- [ ] **Step 1: Добавить строку в раздел «Ссылки на knowledge/»**

Найти в `MEMORY.md` блок, начинающийся с `## Ссылки на knowledge/`, и добавить в конец списка новую строку:

```markdown
- [image-generation.md](knowledge/image-generation.md) — генерация иллюстраций к постам через Pollinations.ai (бесплатно, без ключа)
```

- [ ] **Step 2: Обновить строку решения про картинки в разделе «Ключевые решения»**

Найти существующую строку (добавлена в предыдущей сессии 08.08):

```markdown
- **Картинки к постам (Jarvis, в работе с 08.08):** генерация через Polza API (`google/gemini-2.5-flash-image`), без правки кода бота — знание кладём в `knowledge/image-generation.md`, вызов через Bash/curl по команде в чате. Регистрация на Polza — по партнёрской ссылке `https://polza.ai/?referral=rk4YP1eJRj`. Ключ `POLZA_API_KEY` в `.env` на Fornex добавляет сам Вячеслав (зона запрещена для агента). Детали memory/2026-08-08.md
```

Заменить на:

```markdown
- **Картинки к постам (Jarvis, готово с 08.08):** генерация через Pollinations.ai (бесплатно, без ключа) — `knowledge/image-generation.md`, вызов через Bash/curl по команде в чате, без правки кода бота. Polza API (Gemini 2.5 Flash Image, ~3-4₽/картинку) — запасной вариант на будущее, реферальная ссылка `https://polza.ai/?referral=rk4YP1eJRj` сохранена в memory/2026-08-08.md, не подключаем пока не понадобится
```

- [ ] **Step 3: Проверить лимит длины файла**

Run: `wc -l MEMORY.md`
Expected: ≤ 200 строк. Если превышен — не консолидировать в рамках этой задачи, а завести отдельный TODO в дневнике (вне скоупа этого плана)

- [ ] **Step 4: Commit**

```bash
git add MEMORY.md
git commit -m "[agent] docs: ссылка на image-generation.md + актуализация решения (Pollinations вместо Polza)"
```

---

### Task 3: Ручная проверка механизма генерации

**Files:**
- None (проверка, не изменение кода)

**Interfaces:**
- Consumes: команду curl из `knowledge/image-generation.md` (Task 1)

- [ ] **Step 1: Прогнать команду генерации локально (эмулируя то, что будет делать Jarvis)**

```bash
curl -sfL -o /tmp/pollinations_test.jpg \
  "https://image.pollinations.ai/prompt/cheerful-plumber-with-laptop-flat-illustration-no-text?width=1280&height=720&model=flux&nologo=true"
echo "exit code: $?"
```

Expected: exit code 0, файл `/tmp/pollinations_test.jpg` создан

- [ ] **Step 2: Проверить, что скачался валидный JPEG**

Run: `file /tmp/pollinations_test.jpg`
Expected: вывод содержит `JPEG image data`

- [ ] **Step 3: Если Step 1/2 не прошли — зафиксировать проблему в дневник, прежде чем считать задачу готовой**

Если curl вернул ошибку или файл не JPEG — дописать в `memory/2026-08-08.md` (раздел TODO) конкретную ошибку и не помечать фичу как рабочую, пока не разобрано. Если прошло успешно — перейти к Step 4.

- [ ] **Step 4: Удалить тестовый файл**

Run: `rm /tmp/pollinations_test.jpg`

- [ ] **Step 5: Записать результат теста в дневник**

Добавить в `memory/2026-08-08.md` в раздел «Сделано» текущей сессии (или новую сессию, если день сменился) короткую запись: локальный тест curl-команды из `knowledge/image-generation.md` прошёл успешно, фича готова к использованию Jarvis в Telegram.

- [ ] **Step 6: Commit**

```bash
git add memory/2026-08-08.md
git commit -m "[agent] docs: подтверждён рабочий curl для генерации картинок Pollinations.ai"
```

---

## Definition of Done

- `knowledge/image-generation.md` создан, закоммичен, содержит рабочую curl-команду с urlencode через node
- `MEMORY.md` содержит ссылку на новый knowledge-файл и актуальное решение (Pollinations вместо Polza), не превышает 200 строк
- Curl-команда из документа вручную проверена и подтверждённо скачивает валидный JPEG
- (Вне этого плана, отдельная проверка Вячеславом) — реальный запрос Jarvis в Telegram «сделай картинку к посту» присылает картинку через `[ФОТО: ...]`
