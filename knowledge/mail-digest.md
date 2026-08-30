# Разбор почты slavin68@mail.ru

## Ключевой факт (30.08.2026)

IMAP `mail.ru` блокирует зарубежные IP. Поэтому:
- **С Fornex (Германия) — не работает.** Telegram-бот Джарвиса там живёт, доступа к почте у него нет.
- **С этой Windows-машины (IP РФ) — работает** сразу, без плясок с DNS/VPN.

Вывод: проверять почту может только эта Windows-сессия Claude Code, не Telegram.

## Где credentials

`/home/agent/projects/mail-digest/credentials.json` на Fornex (`root@213.193.196.125`). Ключи в файле: `EMAIL`, `APP_PASSWORD`, `IMAP_HOST`, `IMAP_PORT`.

**Не выводить значения в чат** — только использовать программно.

## Как проверить (рабочий рецепт)

1. Скопировать credentials во временный файл в scratchpad (НЕ в проект):
```bash
scp root@213.193.196.125:/home/agent/projects/mail-digest/credentials.json "<scratchpad>/mail_creds.json"
```
2. Прочитать почту через `imaplib` (Python) — писать вывод в UTF-8 файл, не печатать напрямую в консоль (Windows-консоль в cp1251 ломается на эмодзи/кириллице):
```python
import json, imaplib, email
from email.header import decode_header

def dh(s):
    if not s: return ''
    out = ''
    for text, enc in decode_header(s):
        out += text.decode(enc or 'utf-8', errors='ignore') if isinstance(text, bytes) else text
    return out

with open(r'<path>\mail_creds.json', encoding='utf-8') as f:
    c = json.load(f)
m = imaplib.IMAP4_SSL(c['IMAP_HOST'], int(c['IMAP_PORT']), timeout=15)
m.login(c['EMAIL'], c['APP_PASSWORD'])
m.select('INBOX')
status, data = m.search(None, 'ALL')
ids = data[0].split()
# дальше fetch последних писем, запись в файл, Read этого файла
m.logout()
```
3. **Обязательно удалить временный файл с паролем** после использования (`rm mail_creds.json`).

## Контекст

29-30.08.2026 Вячеслав почистил инбокс вручную. До чистки было ~245-344 писем, почти всё — инфомаркетинговая рассылка (Академия Интернет-Маркетинга Евгения Андрианова, ИИ Университет, курсы фриланса), рабочей переписки почти нет.
