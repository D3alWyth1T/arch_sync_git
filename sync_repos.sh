#!/bin/bash
#
# Git repository sync script
# Stages all changes, commits with "daily sync", pulls, then pushes
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/repos.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

had_errors=0

while IFS= read -r repo || [[ -n "$repo" ]]; do
    # Skip empty lines and comments
    [[ -z "$repo" || "$repo" =~ ^[[:space:]]*# ]] && continue

    # Expand ~ to home directory
    repo="${repo/#\~/$HOME}"

    if [[ ! -d "$repo" ]]; then
        echo "ERROR: Repository path does not exist: $repo" >&2
        had_errors=1
        continue
    fi

    if [[ ! -d "$repo/.git" ]]; then
        echo "ERROR: Not a git repository: $repo" >&2
        had_errors=1
        continue
    fi

    # Stage and commit any local changes
    git -C "$repo" add -A
    if ! git -C "$repo" diff --cached --quiet; then
        if ! git -C "$repo" commit -m "daily sync" >/dev/null 2>&1; then
            echo "ERROR: Failed to commit $repo" >&2
            had_errors=1
            continue
        fi
    fi

    # Pull changes
    if ! git -C "$repo" pull --rebase 2>&1 | grep -v "Already up to date"; then
        if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
            echo "ERROR: Failed to pull $repo" >&2
            had_errors=1
            continue
        fi
    fi

    # Push changes
    if ! git -C "$repo" push 2>&1 | grep -v "Everything up-to-date"; then
        if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
            echo "ERROR: Failed to push $repo" >&2
            had_errors=1
            continue
        fi
    fi

done < "$CONFIG_FILE"

exit $had_errors
