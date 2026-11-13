#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    echo "🔑 GitHub authentication required. Starting login..."
    gh auth login
fi

echo "🚀 Creating and pushing repository to https://github.com/avenix/CalendarBar..."
if gh repo view avenix/CalendarBar &>/dev/null; then
    echo "Repository already exists on GitHub. Pushing..."
    git push -u origin main
else
    echo "Creating new repository avenix/CalendarBar..."
    gh repo create avenix/CalendarBar --public --source=. --remote=origin --push
fi

echo "✅ Successfully pushed to https://github.com/avenix/CalendarBar"
