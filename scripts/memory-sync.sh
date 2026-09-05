#!/bin/bash
# Auto-sync memory files to GitHub. Runs from cron every ~10-15 min on the agent server.
set -e

WORKSPACE="/home/agent/workspace"
LOG="/home/agent/workspace-sync.log"
cd "$WORKSPACE"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

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
    exit 1
  fi
fi

if ! git pull --rebase origin main -q 2>>"$LOG"; then
  log "PULL FAILED — memory may be out of sync, needs manual look"
  exit 1
fi

# Nothing local and nothing new from remote — done.
if [ -z "$CHANGED" ]; then
  exit 0
fi

if ! git push origin main -q 2>>"$LOG"; then
  log "PUSH FAILED — commit made locally but NOT on GitHub, needs manual look"
  exit 1
fi

log "synced ok"
