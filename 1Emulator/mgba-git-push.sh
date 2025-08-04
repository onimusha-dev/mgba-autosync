#!/bin/bash

set -e

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

REPO_DIR="$HOME/GBA"
LOG_FILE="$REPO_DIR/auto_git_sync.log"
DATE_FULL=$(date +"%a %b %d %Y %H:%M:%S")
TIME_SHORT=$(date +"%H:%M:%S")

touch "$LOG_FILE"

{
  echo -e "\n==== $DATE_FULL ===="

  cd "$REPO_DIR" || { echo "❌ Repo dir not found"; exit 1; }

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [[ "$CURRENT_BRANCH" == "HEAD" ]]; then
    echo "❌ Detached HEAD. Abort."
    exit 1
  fi

  echo "🌿 Branch: $CURRENT_BRANCH"

  echo "⬇️ Pulling from remote..."
  git pull origin "$CURRENT_BRANCH" || echo "⚠️ Pull failed"

  echo "➕ Adding changes..."
  git add .

  if git diff --cached --quiet; then
    echo "🟰 No changes to commit."
  else
    echo "📦 Committing..."
    git commit -m "autosync: update on $DATE_FULL"
  fi

  echo "⬆️ Pushing to remote..."
  if ! git_push_output=$(git push origin "$CURRENT_BRANCH" 2>&1); then
    echo "❌ Push failed."
    notify-send -u normal "🕹️ mgba autosave sync failed at $TIME_SHORT" \
      "❌ Git push failed on '$CURRENT_BRANCH'. See log for details."
  else
    echo "✅ Push successful."
    notify-send -u low "✅ mgba autosave synced" \
      "Pushed to '$CURRENT_BRANCH' at $TIME_SHORT"
  fi

  echo "✅ Sync done."

} >> "$LOG_FILE" 2>&1
