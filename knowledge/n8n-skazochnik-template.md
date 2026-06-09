# n8n Сказочник — генератор длинного контента с публикацией на Telegraph

**Источник:** получен от Вячеслава 2026-06-03, файл «Сказочник.json»

**Когда читать:** когда нужно генерировать длинный многошаговый контент (сказка, история, статья с главами) и публиковать на Telegraph.

## Архитектура

```
Telegram Trigger
  → Plot Generator (Gemini 3.1 Pro) — генерирует JSON со структурой
  → Parse Plot (Code) — парсит JSON, создаёт items по главам
  → splitInBatches (цикл по главам)
      → Build Chapter Context (Code) — собирает контекст
      → Write Chapter (Gemini 3.1 Pro) — пишет главу
      → Save Chapter (Code) — сохраняет текст и резюме
      → [уведомление в Telegram: "Глава X написана!"]
  → Collect All Chapters (Code) — собирает всё в один текст
  → Get Telegraph Token (HTTP) — создаёт аккаунт Telegraph
  → Format for Telegraph (Code) — конвертирует markdown в Telegraph nodes
  → Publish to Telegraph (HTTP POST) — публикует
  → Show Link → Send to Telegram
```

## Ключевые паттерны

### 1. Хранение состояния через staticData
```js
const staticData = $getWorkflowStaticData('global');
staticData.plot = plot;
staticData.chapterTexts = [];
staticData.chapterSummaries = [];
staticData.chatId = $('Telegram Trigger').first().json.message.chat.id;
```
Единственный способ передавать данные между итерациями `splitInBatches` в n8n.

### 2. Контекст для каждой главы
- Предыдущая глава: полный текст (для продолжения)
- Более ранние главы: только краткие резюме (экономия токенов)
- Все главы: план (title + outline) — для общей связности

### 3. Разделитель ---SUMMARY--- в промпте
Писатель добавляет после текста главы `---SUMMARY---` и краткое резюме. Код разбивает по разделителю:
```js
const parts = output.split('---SUMMARY---');
const chapterText = parts[0].trim();
const summary = parts.length > 1 ? parts[1].trim() : 'Глава написана.';
```

### 4. Промежуточные уведомления
После Plot Generator отправляет "Сюжет придуман!". После каждой главы — "Глава X написана!" Пользователь видит прогресс.

### 5. Публикация на Telegraph
```
GET https://api.telegra.ph/createAccount?short_name=StoryBot&author_name=AI+Story+Generator
POST https://api.telegra.ph/createPage
  body: { access_token, title, content (JSON nodes), author_name }
```
Telegraph возвращает `result.url` — отдаём пользователю.

## Формат JSON для сюжета
```json
{
  "title": "",
  "synopsis": "",
  "characters": [{"name": "", "description": ""}],
  "chapters": [{"number": 1, "title": "", "outline": ""}]
}
```

## Модель
`google/gemini-3.1-pro-preview` через OpenAI-совместимый API (PolzaAI), timeout 120s.
