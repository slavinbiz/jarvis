# demin.digital — план правок после аудита

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Устранить два замечания из аудита: убрать собственный сайт из портфолио и заменить email на корпоративный.

**Architecture:** Правки в одном файле `index.html` репозитория `slavinbiz/viacheslav-digital`. Деплой автоматический через Vercel при push в master.

**Tech Stack:** HTML, Git, Vercel (автодеплой)

---

## Предварительный шаг: клонировать репозиторий

- [ ] Клонировать репо локально:
```bash
git clone https://github.com/slavinbiz/viacheslav-digital.git
cd viacheslav-digital
```

---

### Task 1: Убрать «Лендинг Цифровой Мастер» из портфолио

**Files:**
- Modify: `index.html:1228-1241`

Текущий код (строки 1228–1241):
```html
<div class="portfolio-card reveal reveal-delay-1">
  <div class="portfolio-thumb">
    <div class="portfolio-thumb-inner" style="background:#1a1200;padding:0;overflow:hidden;">
      <img src="case-site.jpg" alt="Лендинг Цифровой Мастер" style="width:100%;height:100%;object-fit:cover;object-position:top;">
    </div>
    <div class="portfolio-thumb-overlay"><a href="https://viacheslav-digital.vercel.app" target="_blank" class="portfolio-overlay-btn">Открыть сайт →</a></div>
  </div>
  <div class="portfolio-info">
    <span class="portfolio-tag">Сайт</span>
    <h3>Лендинг Цифровой Мастер</h3>
    <p class="portfolio-result">Реальный проект · в продакшне</p>
  </div>
</div>
```

- [ ] **Шаг 1: Удалить весь блок** `<div class="portfolio-card reveal reveal-delay-1">` с карточкой «Лендинг Цифровой Мастер» (строки 1228–1241 включительно).

- [ ] **Шаг 2: Проверить что сетка не сломалась** — открыть `index.html` в браузере, убедиться что секция «Реальные проекты» отображается корректно, карточек стало на одну меньше.

- [ ] **Шаг 3: Коммит**
```bash
git add index.html
git commit -m "fix: убрать собственный сайт из портфолио"
```

---

### Task 2: Заменить email на корпоративный

**Files:**
- Modify: `index.html:1553,1559`

Текущий код (строки 1553–1559):
```html
<a href="mailto:slavin68@mail.ru" class="contact-tg">
  ...
  <div class="contact-tg-text">
    <strong>slavin68@mail.ru</strong>
    <span>Пишите на почту</span>
  </div>
</a>
```

- [ ] **Шаг 1: Настроить пересылку** на домене `demin.digital` — зайти в панель управления доменом (reg.ru / Cloudflare / другой провайдер), создать email-алиас `hello@demin.digital` с пересылкой на `slavin68@mail.ru`. Новые письма будут приходить на старый ящик.

- [ ] **Шаг 2: Заменить в index.html** оба упоминания старого email:
```html
<!-- было -->
<a href="mailto:slavin68@mail.ru" class="contact-tg">
  <div class="contact-tg-text">
    <strong>slavin68@mail.ru</strong>

<!-- стало -->
<a href="mailto:hello@demin.digital" class="contact-tg">
  <div class="contact-tg-text">
    <strong>hello@demin.digital</strong>
```

- [ ] **Шаг 3: Проверить** — открыть `index.html` в браузере, найти секцию «Написать», убедиться что отображается `hello@demin.digital`.

- [ ] **Шаг 4: Коммит**
```bash
git add index.html
git commit -m "fix: email заменён на hello@demin.digital"
```

---

### Task 3: Задеплоить и проверить на живом сайте

- [ ] **Шаг 1: Запушить в master**
```bash
git push origin master
```

- [ ] **Шаг 2: Дождаться деплоя** — зайти на https://vercel.com/dashboard, убедиться что деплой прошёл успешно (статус «Ready»).

- [ ] **Шаг 3: Проверить на живом сайте** https://www.demin.digital/
  - Секция «Реальные проекты» — карточки «Лендинг Цифровой Мастер» нет
  - Секция «Написать» — отображается `hello@demin.digital`

- [ ] **Шаг 4: Отметить задачи выполненными** в дизайн-документе `docs/superpowers/specs/2026-05-24-demin-digital-audit-design.md`
