# s-ui + sqlite3 — как править базу, не роняя VPN

**Когда читать:** перед любой прямой правкой `/usr/local/s-ui/db/s-ui.db` на TimeWeb (64.188.57.249) через `sqlite3` CLI — например, добавление клиента, obfs, смена inbound-конфига.

---

## Симптом поломки

- `systemctl status s-ui` — сервис активен, но в `journalctl -u s-ui` бесконечный цикл `INFO - starting core` каждые 5 секунд, ядро так и не поднимается
- `ss -ulnp | grep 443` — пусто, Hysteria2 не слушает UDP/443
- VPN не работает ни у кого: ни личный туннель, ни клиенты бота
- В логе (без фильтра `starting core`) — строка вида:
  `ERROR - sql: Scan error on column index N, name "<колонка>": unsupported Scan, storing driver.Value type string into type *json.RawMessage`

## Причина

Таблицы `inbounds` и `clients` в s-ui хранят JSON в колонках с типом `blob` (`options`, `out_json`, `config`). Штатно s-ui (Go-приложение) пишет туда байты. Если вставить/обновить значение через `sqlite3` CLI обычной строкой (`UPDATE ... SET options = '{"a":1}'`), SQLite сохраняет это со storage class **TEXT**, а не BLOB. Go-драйвер `database/sql` при чтении такой колонки возвращает `string`, а код s-ui ожидает `[]byte` для `json.RawMessage.Scan()` — падает с ошибкой выше. Из-за этого весь цикл сборки конфига ядра рвётся на каждой попытке, ядро не стартует.

Случалось дважды:
- **1 июля 2026** — мусорная запись `test-trigger` с пустым `config` (NULL вместо валидного JSON) в таблице `clients`
- **2 июля 2026** — ручной `UPDATE inbounds SET options = '...'` при добавлении obfs salamander

## Как чинить, если уже сломалось

```sql
-- привести существующее значение к BLOB на месте
UPDATE inbounds SET options = CAST(options AS BLOB) WHERE id=1;
UPDATE inbounds SET out_json = CAST(out_json AS BLOB) WHERE id=1;
```
Затем `systemctl restart s-ui`, проверить `journalctl -u s-ui -n 15` (должна появиться строка `udp server started at [::]:443`) и `ss -ulnp | grep 443`.

Если проблема в `clients.config` (NULL или мусорная тестовая запись) — смотреть `SELECT id,name,config FROM clients;`, искать NULL/пустые. `DELETE FROM` заблокирован в `.claude/settings.json` — чинить через `UPDATE ... SET enable=0` (отключить запись) вместо удаления.

## Как делать правильно (не ломать)

1. **Предпочтительно** — менять через веб-панель s-ui (https://64.188.57.249:2095/, логин у Вячеслава), она сама пишет BLOB корректно.
2. Если правишь через `sqlite3` напрямую — всегда оборачивай JSON в `CAST(... AS BLOB)` **сразу в самом INSERT/UPDATE**, не только при фиксе:
   ```sql
   UPDATE inbounds SET options = CAST('{"listen":"::","listen_port":443,"obfs":{"type":"salamander","password":"..."}}' AS BLOB) WHERE id=1;
   ```
3. **Всегда делай бэкап перед правкой:** `cp /usr/local/s-ui/db/s-ui.db /usr/local/s-ui/db/s-ui.db.bak-$(date +%Y%m%d%H%M)`
4. После любой правки — `systemctl restart s-ui` и обязательно проверяй `ss -ulnp | grep 443`, не полагайся только на `systemctl status` (он покажет active, даже если ядро внутри в crash loop)
5. Меняя что-то в конфиге инбаунда (например, включая obfs) — это ломает **всех текущих клиентов**, у которых нет соответствующей настройки на своей стороне. Обновлять сервер и все клиенты (свой Windows sing-box конфиг `C:\v2rayN\hy2-client\config.json` + шаблон клиента VPN-бота) синхронно, иначе временно все отваливаются

## Контекст

- Два разных Jarvis-сеанса (этот компьютер + Telegram-бот на Beget) имеют доступ к одному и тому же серверу TimeWeb и могут работать с ним одновременно — см. `MEMORY.md`, раздел «VPN-бот / s-ui — критичное правило»
