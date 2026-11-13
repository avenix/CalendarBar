#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    echo "🔑 GitHub authentication required. Starting login..."
    gh auth login
fi

echo "🚀 Pushing changes to https://github.com/avenix/CalendarBar..."
git push -u origin main

echo "✅ Successfully synced with https://github.com/avenix/CalendarBar"
