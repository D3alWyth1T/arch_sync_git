# arch_sync_git

A utility for automagically syncing git repos on a routine basis.

**Prerequisites:** SSH keys configured for passwordless git authentication (e.g., via `ssh-agent`).

## Configuration

Edit `repos.conf` to list the repositories you want to sync (one path per line):

```
~/code/project1
/home/user/code/project2
```

## Installation

1. Install cronie (if not already installed):
   ```bash
   sudo pacman -S cronie
   sudo systemctl enable --now cronie
   ```

2. Copy files to your config directory:
   ```bash
   mkdir -p ~/.config/git_sync
   cp sync_repos.sh repos.conf ~/.config/git_sync/
   chmod +x ~/.config/git_sync/sync_repos.sh
   ```

3. Edit `~/.config/git_sync/repos.conf` and add your repository paths.

4. Add to your crontab:
   ```bash
   crontab -e
   ```

   Add this line to run daily at 6 AM:
   ```
   0 6 * * * ~/.config/git_sync/sync_repos.sh 2>&1 | logger -t git-sync
   ```

## Usage

To manually trigger a sync:

```bash
~/.config/git_sync/sync_repos.sh
```

View cron logs:

```bash
journalctl -t git-sync
```

## What It Does

For each configured repository:
1. `git add -A` to stage all changes
2. `git commit -m "daily sync"` (only if there are staged changes)
3. `git pull --rebase` to fetch and integrate remote changes
4. `git push` to push local commits
