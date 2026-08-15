#!/bin/bash
# Auto-sync memory files to GitHub. Runs from cron every ~10-15 min on the agent server.
set -e

WORKSPACE="/home/agent/workspace"
LOG="/home/agent/workspace-sync.log"
cd "$WORKSPACE"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

# Pull first so we never push from a stale base — avoids silent divergence
# between this server and other sessions (Windows, other servers).
if ! git pull --rebase origin main -q 2>>"$LOG"; then
  log "PULL FAILED — memory may be out of sync, needs manual look"
  exit 1
fi

CHANGED=$(git status --porcelain MEMORY.md LEARNED.md memory/ knowledge/ 2>/dev/null)

if [ -z "$CHANGED" ]; then
  exit 0
fi

git add MEMORY.md LEARNED.md memory/ knowledge/

if ! git commit -m "[agent] memory: auto-sync $(date '+%Y-%m-%d %H:%M')" -q; then
  log "COMMIT FAILED"
  exit 1
fi

if ! git push origin main -q 2>>"$LOG"; then
  log "PUSH FAILED — commit made locally but NOT on GitHub, needs manual look"
  exit 1
fi

log "synced ok"
