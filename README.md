# Bash Backup Rotation Script

Simple script which can be easily modified if needed for backup rotation. This script use ssh and rsync for syncing.
This script is completely rewriten, old script can be found here : https://github.com/todiadiyatmo/bash-backup-rotation-script/tree/legacy-1.0.0 .

## Feature

- Daily, Weekly, Monthly backup script with number of retention (backup to keep) option
- backup to local only, local + remote and remote only mode
- 4 different backup script :
	- file backup with zip compression script
	- rsync script
	- mysql script
	- mysql with extrabackup script
- Secure backup with SSH connection
- All configuration overridable via environment variables

## Scripts

| Script | Purpose | Dependencies |
|--------|---------|--------------|
| `backup-mysql.sh` | MySQL database dump with gzip compression | mysqldump, gzip, rsync, ssh |
| `backup-file-zip.sh` | Directory backup with zip compression | zip, rsync, ssh |
| `backup-rsync.sh` | File sync with bucket-based rotation | rsync |
| `backup-extrabackup.sh` | MySQL extrabackup (stub) | - |

## Backup Modes

`backup-mysql.sh` and `backup-file-zip.sh` support three modes via `BACKUP_MODE`:

| Mode | Behavior |
|------|----------|
| `local-only` | Create backup locally, rotate old files locally |
| `local-remote` | Create backup locally, rotate locally, rsync to remote |
| `remote-only` | Create backup locally, rsync to remote (remove local), rotate on remote via ssh |

## Schedule Logic

| Condition | Backup Type |
|-----------|-------------|
| Day of month = 1 | Monthly |
| Day of week = 7 (Sunday) | Weekly |
| Day of week < 7 (Mon-Sat) | Daily |

Monthly takes priority over weekly when both conditions match (e.g. Sunday the 1st).

## Todo

This release is still missing this feature from the old release

- [ ] email notification

# Usage

## MySQL / MySQL Extrabackup / Zip File Backup

- Copy script to desired location
- Edit the parameter of the script, configure the `BACKUP_RETENTION_` to set the rotation / number of backup needed

### Configuration via script defaults

```bash
### User Pass Mysql ###
HOST="${BACKUP_MYSQL_HOST:-localhost}"
USER="${BACKUP_MYSQL_USER:-backup}"
PASS="${BACKUP_MYSQL_PASS:-backup}"
DBNAME="${BACKUP_MYSQL_DBNAME:-project_sql}"
BACKUP_DIR="${BACKUP_MYSQL_DIR:-/root/backup}"
DST_HOST="${BACKUP_MYSQL_DST_HOST:-user@host}"
REMOTE_DST_DIR="${BACKUP_MYSQL_REMOTE_DIR:-/root/backup}"
BACKUP_DAILY="${BACKUP_MYSQL_DAILY:-true}"
BACKUP_WEEKLY="${BACKUP_MYSQL_WEEKLY:-true}"
BACKUP_MONTHLY="${BACKUP_MYSQL_MONTHLY:-true}"
BACKUP_RETENTION_DAILY="${BACKUP_MYSQL_RETENTION_DAILY:-3}"
BACKUP_RETENTION_WEEKLY="${BACKUP_MYSQL_RETENTION_WEEKLY:-3}"
BACKUP_RETENTION_MONTHLY="${BACKUP_MYSQL_RETENTION_MONTHLY:-3}"
BACKUP_MODE="${BACKUP_MYSQL_MODE:-local-only}"
```

### Configuration via environment variables

You can override any default by setting environment variables:

```bash
export BACKUP_MYSQL_USER=myuser
export BACKUP_MYSQL_PASS=mypassword
export BACKUP_MYSQL_DBNAME=production_db
export BACKUP_MYSQL_DIR=/mnt/backups
export BACKUP_MYSQL_RETENTION_DAILY=7
./backup-mysql.sh
```

- Test the script to make sure everything correct, ex: `./backup-mysql.sh`
- Put script on cron to make sure it is running everyday at your desired time: `00 03 * * * /path/to/backup.sh`
- Check your backup result

## Rsync Backup

```bash
# Daily backup (default)
./backup-rsync.sh

# Weekly backup
./backup-rsync.sh --weekly
```

Configure via environment variables:

```bash
export BACKUP_RSYNC_SOURCE=/var/www/html/
export BACKUP_RSYNC_DEST=/mnt/backups
export BACKUP_RSYNC_DAILY_COUNT=3    # number of daily rotation buckets
export BACKUP_RSYNC_WEEKLY_COUNT=2   # number of weekly rotation buckets
./backup-rsync.sh
```

## Environment Variables Reference

### backup-mysql.sh

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_MYSQL_HOST` | localhost | MySQL server host |
| `BACKUP_MYSQL_USER` | backup | MySQL username |
| `BACKUP_MYSQL_PASS` | backup | MySQL password |
| `BACKUP_MYSQL_DBNAME` | project_sql | Database name |
| `BACKUP_MYSQL_DIR` | /root/backup | Local backup directory |
| `BACKUP_MYSQL_DST_HOST` | user@host | Remote host for rsync |
| `BACKUP_MYSQL_REMOTE_DIR` | /root/backup | Remote backup directory |
| `BACKUP_MYSQL_DAILY` | true | Enable daily backups |
| `BACKUP_MYSQL_WEEKLY` | true | Enable weekly backups |
| `BACKUP_MYSQL_MONTHLY` | true | Enable monthly backups |
| `BACKUP_MYSQL_RETENTION_DAILY` | 3 | Number of daily backups to keep |
| `BACKUP_MYSQL_RETENTION_WEEKLY` | 3 | Number of weekly backups to keep |
| `BACKUP_MYSQL_RETENTION_MONTHLY` | 3 | Number of monthly backups to keep |
| `BACKUP_MYSQL_MODE` | local-only | Backup mode (local-only / local-remote / remote-only) |

### backup-file-zip.sh

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_ZIP_SRC` | /var/www/html | Source directory to backup |
| `BACKUP_ZIP_DIR` | /home/user/backup | Local backup directory |
| `BACKUP_ZIP_PROJECT` | project | Project name for filename |
| `BACKUP_ZIP_DST_HOST` | user@host | Remote host for rsync |
| `BACKUP_ZIP_REMOTE_DIR` | /root/backup | Remote backup directory |
| `BACKUP_ZIP_DAILY` | true | Enable daily backups |
| `BACKUP_ZIP_WEEKLY` | true | Enable weekly backups |
| `BACKUP_ZIP_MONTHLY` | true | Enable monthly backups |
| `BACKUP_ZIP_RETENTION_DAILY` | 3 | Number of daily backups to keep |
| `BACKUP_ZIP_RETENTION_WEEKLY` | 3 | Number of weekly backups to keep |
| `BACKUP_ZIP_RETENTION_MONTHLY` | 3 | Number of monthly backups to keep |
| `BACKUP_ZIP_MODE` | local-only | Backup mode |

### backup-rsync.sh

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_RSYNC_SOURCE` | (empty) | Source directory |
| `BACKUP_RSYNC_DEST` | (empty) | Destination directory |
| `BACKUP_RSYNC_DAILY_COUNT` | 2 | Number of daily rotation buckets |
| `BACKUP_RSYNC_WEEKLY_COUNT` | 2 | Number of weekly rotation buckets |

## Testing

Tests use **pytest** running inside **Docker** with `faketime` for date simulation and a real **MySQL 8.0** instance.

```bash
make test          # Run all 29 integration tests in Docker
make test-down     # Tear down test containers
make lint          # Run shellcheck on all scripts
```

See [tests/README.md](tests/README.md) for full test documentation.

## Pull request and issue

Feel free to open pull request and submit bug ticket.
