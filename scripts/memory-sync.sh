#!/bin/bash
# Auto-sync memory files to GitHub
set -e

WORKSPACE="/home/agent/workspace"
cd "$WORKSPACE"

# Check for changes in memory files only
CHANGED=$(git status --porcelain MEMORY.md LEARNED.md memory/ knowledge/ 2>/dev/null)

if [ -z "$CHANGED" ]; then
  exit 0
fi

git add MEMORY.md LEARNED.md memory/ knowledge/ 2>/dev/null || true
git commit -m "[agent] memory: auto-sync $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || true
git push origin main 2>/dev/null || true
