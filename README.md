# Bash Backup Rotation Script

Simple script which can be easily modified if needed for backup rotation. This script use ssh and rsync for syncing 
This script is completely rewriten , old script can be found here : https://github.com/todiadiyatmo/bash-backup-rotation-script/tree/legacy-1.0.0 .

## Feature 

- Daily, Weekly, Monthly backup script with number of retention (backup to keep) option
- backup to local only, local + remote and remote only mode
- 4 different backup script  : 
	- file backup with zip compression script
	- rsync script 
	- mysql script
	- mysql with extrabackup script 
- Secure backup with SSH connection


## Todo

This release is still missing this feature from the old relesae 

- [ ] email notification 

# Usage 

## MySQL / MySQL Extrabackup / Zip File Backup 

- Copy script to desired location
- Edit the parameter of the script, configure the `BACKUP_RETENTION_` to set the rotation / number of backup needed

```
### User Pass Mysql ###
USER=backup
PASS=backup
DBNAME=project_sql
BACKUP_DIR="/root/backup"
DST_HOST="user@host"
REMOTE_DST_DIR="/root/backup"
BACKUP_DAILY=true # if set to false backup will not work
BACKUP_WEEKLY=true # if set to false backup will not work
BACKUP_MONTHLY=true # if set to false backup will not work
BACKUP_RETENTION_DAILY=3
BACKUP_RETENTION_WEEKLY=3
BACKUP_RETENTION_MONTHLY=3
```
- test the script to make sure everything correct , ex : `mysql-backup-script.sh`
- put script on cron to make sure it is running everyday at your desired time : `00 03 * * * backup.sh`
- check your backup result
- profit :) 

## Pull request and issue
feel free to open pull request and submit bug ticket 