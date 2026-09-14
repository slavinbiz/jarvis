#!/bin/bash
# Auto-sync memory files to GitHub. Runs from cron every ~10-15 min on the agent server.
set -e

WORKSPACE="/home/agent/workspace"
LOG="/home/agent/workspace-sync.log"
ALERT_SENT_MARKER="/home/agent/.sync-alert-sent"
FAIL_THRESHOLD=4
cd "$WORKSPACE"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

# Алерт в Telegram напрямую владельцу, если синк падает подряд FAIL_THRESHOLD
# раз (~1 час при 15-мин cron) — не ждём ежедневную проверку bugfixer, раньше
# зависший rebase молчал 157 попыток подряд (~40 часов) до находки
# (найдено 13.09.2026). Шлёт один раз за инцидент (маркер-файл), не спамит
# каждые 15 мин, сбрасывается сам при следующем успешном синке.
alert_if_stuck() {
  local recent_fails
  recent_fails=$(tail -"$FAIL_THRESHOLD" "$LOG" 2>/dev/null | grep -c "FAILED")
  if [ "$recent_fails" -ge "$FAIL_THRESHOLD" ] && [ ! -f "$ALERT_SENT_MARKER" ]; then
    local creds="/home/agent/projects/santex-poster/credentials.json"
    if [ -f "$creds" ]; then
      local token
      token=$(python3 -c "import json; print(json.load(open('$creds'))['TELEGRAM_BOT_TOKEN'])" 2>/dev/null)
      if [ -n "$token" ]; then
        curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
          -d chat_id=888224075 \
          -d text="⚠️ Синк памяти Jarvis падает $FAIL_THRESHOLD+ раз подряд (~1 час). Похоже на реальный конфликт в git — нужна ручная проверка." \
          > /dev/null 2>&1
        touch "$ALERT_SENT_MARKER"
      fi
    fi
  fi
}

CHANGED=$(git status --porcelain 2>/dev/null)

# Commit any local edits first (bot writes these files directly) — only then
# pull --rebase, so rebase has something of ours to replay and never sees
# "unstaged changes". Pulling replaced the old behaviour of pushing straight
# from a stale base, which silently diverged from other sessions.
# Использует `git add -A` (весь workspace, с учётом .gitignore), а не список
# из 4 путей — раньше правки GOALS.md/.claude/ оставались unstaged и глушили
# rebase молча на 2 недели (найдено 05.09.2026 через bugfixer).
if [ -n "$CHANGED" ]; then
  git add -A
  if ! git commit -m "[agent] memory: auto-sync $(date '+%Y-%m-%d %H:%M')" -q; then
    log "COMMIT FAILED"
    alert_if_stuck
    exit 1
  fi
fi

if ! git pull --rebase origin main -q 2>>"$LOG"; then
  log "PULL FAILED — memory may be out of sync, needs manual look"
  alert_if_stuck
  exit 1
fi

# Nothing local and nothing new from remote — done. Heartbeat once an hour so
# a truly dead cron (vs. "ran fine, nothing to do") is distinguishable in the
# log — раньше 2 дня тишины выглядели как сломанный синк, хотя обе стороны
# просто коммитили сами в реальном времени (найдено 07.09.2026, false alarm).
if [ -z "$CHANGED" ]; then
  LAST_LINE=$(tail -1 "$LOG" 2>/dev/null)
  if [[ "$LAST_LINE" != *"$(date '+%Y-%m-%d %H')"* ]]; then
    log "checked, nothing to sync"
  fi
  exit 0
fi

if ! git push origin main -q 2>>"$LOG"; then
  log "PUSH FAILED — commit made locally but NOT on GitHub, needs manual look"
  alert_if_stuck
  exit 1
fi

rm -f "$ALERT_SENT_MARKER"
log "synced ok"
