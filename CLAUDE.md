# Bash Backup Rotation Script

## Overview

Lightweight bash backup rotation toolkit with daily/weekly/monthly scheduling and configurable retention. Designed for cron jobs.

## Scripts

| Script | Purpose | External deps |
|--------|---------|---------------|
| `backup-mysql.sh` | MySQL dump with gzip compression | mysqldump, gzip, rsync, ssh |
| `backup-file-zip.sh` | Directory backup with zip compression | zip, rsync, ssh |
| `backup-rsync.sh` | Rsync with bucket-based rotation | rsync |
| `backup-extrabackup.sh` | Stub (not implemented) | - |

## Backup Modes

`backup-mysql.sh` and `backup-file-zip.sh` support three modes via `BACKUP_MODE`:
- `local-only` -- backup + local retention cleanup
- `local-remote` -- backup + local cleanup + rsync to remote
- `remote-only` -- backup + rsync (remove source) + remote cleanup via ssh

## Configuration

All scripts accept configuration via environment variables (with defaults for backward compatibility). See each script header for available variables.

## Testing

Tests use **pytest** inside **Docker** with `faketime` for date manipulation and a real MySQL instance.

```bash
make test          # Run full integration test suite in Docker
make test-down     # Tear down test containers
make lint          # Run shellcheck
```

## Known Issues

1. **Sunday gap**: When `BACKUP_WEEKLY=false` on Sunday, daily backup also skips (checks `DAYWEEK -lt 7`)
2. **Filename mismatch in backup-mysql.sh**: `local_only()` uses `-sql-` in filename but retention greps for `mysql`, so those files are never cleaned up
3. **`MONTH` variable misnomer**: Actually holds day-of-month (`date +%d`), not month number
4. **`xargs -d` is GNU-only**: Fails on macOS BSD xargs
