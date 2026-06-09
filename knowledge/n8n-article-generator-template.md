# n8n Генератор статей — двухшаговый диалог + статьи с иллюстрациями

**Источник:** получен от Вячеслава 2026-06-03, файл «Генератор статей.json»

**Когда читать:** когда нужен бот с двухшаговым диалогом (тема → количество), генерацией статей в цикле с иллюстрациями.

## Архитектура

```
Telegram Trigger
  → Роутер (Code) — определяет: тема или число?
  → IF "Тема или число?"
      [тема] → Спросить количество (Telegram)
      [число] → Loop Over Items
                  → Подбор стиля (Gemini Flash Lite) — имя автора
                  → AI Agent (Gemini Flash) — написать статью в этом стиле
                  → AI Agent1 (Gemini Flash Lite) — промпт для иллюстрации
                  → Генерация изображения (Polza API)
                  → Скачивание картинки (HTTP)
                  → Отправка фото (Telegram)
                  → Отправка статьи (Telegram)
                  → Loop (следующая статья)
```

## Ключевые паттерны

### 1. Двухшаговый диалог с сохранением темы
```js
const staticData = $getWorkflowStaticData('global');
const msg = $input.first().json.message.text.trim();
const chatId = $input.first().json.message.chat.id;
const num = parseInt(msg);

if (!isNaN(num) && num > 0 && num <= 20 && staticData['topic_' + chatId]) {
  // Число — генерируем статьи
  const topic = staticData['topic_' + chatId];
  delete staticData['topic_' + chatId];
  // создаём N items для цикла
} else {
  // Тема — сохраняем и спрашиваем количество
  staticData['topic_' + chatId] = msg;
  return [{ json: { chatId, topic: msg, action: 'ask' } }];
}
```
Ключ по `chatId` — разные пользователи не мешают друг другу.

### 2. Подбор стиля автора
Отдельный агент получает тему и возвращает только имя подходящего современного автора. Это имя подставляется в system prompt основного агента: "Ты пишешь в стиле {автор}".

### 3. Генерация изображения через Polza API
```
POST https://polza.ai/api/v1/media
Auth: httpHeaderAuth
Body: {
  "model": "google/gemini-2.5-flash-image",
  "input": {
    "prompt": "...",
    "aspect_ratio": "16:9",
    "output_format": "png"
  }
}
```
Возвращает `data[0].url` — скачиваем GET-запросом как бинарный файл, отправляем в Telegram как фото.

### 4. Порядок отправки
Сначала фото, потом текст статьи — выглядит как полноценный пост.

## Модели
- Подбор стиля + промпт иллюстрации: `google/gemini-3.1-flash-lite-preview` (дешевле)
- Написание статьи: `google/gemini-3-flash-preview`
- Генерация изображения: `google/gemini-2.5-flash-image`
