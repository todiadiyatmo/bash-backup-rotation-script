#!/bin/bash
#@author @Todi Adiyatmo Wijoyo based on 
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description Backup script for your website


# Edit this configuration !! 

# The backup directory , do not end the directory with backslash ! 
BACKUP_DIR=/your_backup_directory_target

# The directory to be backup , do not end the directory with backslash ! 
TARGET_DIR=/folder_to_backup

# Admin email
MAIL="your_email@email.com"

# Number of day the daily backup keep
RETENTION_DAY=7

# Number of day the weekly backup keep
RETENTION_WEEK=30

# Number of day the monthly backup keep
RETENTION_MONTH=90


# MYSQL Configuration
# Enter all credential within the ' ' single quote !

USER='db_user'
PASSWORD='db_password'
DATABASE='db_database'
HOST='127.0.0.1'

# End configuration

# STARTING BACKUP SCRIPT


CURRENT_DIR=${PWD}

mkdir $BACKUP_DIR/backup.incoming

cd $BACKUP_DIR/backup.incoming

# Destination file names
date_daily=`date +"%d-%m-%Y"`

# Dump MySQL tables
mysqldump -h $HOST -u $USER -p$PASSWORD $DATABASE > $BACKUP_DIR/backup.incoming/mysql_dump.sql

# Compress tables and files
tar -czf $BACKUP_DIR/backup.incoming/$date_daily.tgz mysql_dump.sql $TARGET_DIR

# Cleanup
rm $BACKUP_DIR/backup.incoming/mysql_dump.sql

cd $CURRENT_DIR

# Rotation script
# Storage folder where to move backup files
# Must contain backup.monthly backup.weekly backup.daily folders
# storage=/root/backup/kraton
# storage = $BACKUP_DIR
# Source folder where files are backed

#date_weekly=`date +"%V sav. %m-%Y"`
#date_monthly=`date +"%m-%Y"`

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# Optional check if source files exist. Email if failed.
if [ ! -f $BACKUP_DIR/backup.incoming/$date_daily.tgz ]; then
	mail $MAIL -s "[backup script] Daily backup failed! Please check for missing files."
fi

# It is logical to run this script daily. We take files from source folder and move them to
# appropriate destination folder

# On first month day do
if [ "$month_day" -eq 1 ] ; then
  	destination=backup.monthly/
  	# daily - keep for RETENTION_DAY
	find $BACKUP_DIR/backup.monthly/ -maxdepth 1 -mtime +$RETENTION_DAY -type d -exec rm -rv {} \;
else
  # On saturdays do
  if [ "$week_day" -eq 6 ] ; then
    destination=backup.weekly/
	# weekly - keep for RETENTION_WEEK
	find $BACKUP_DIR/backup.weekly/ -maxdepth 1 -mtime +$RETENTION_WEEK -type d -exec rm -rv {} \;
  else
    # On any regular day do
    destination=backup.daily/
  	# monthly - keep for RETENTION_MONTH
	find $BACKUP_DIR/backup.daily/ -maxdepth 1 -mtime +$RETENTION_MONTH -type d -exec rm -rv {} \;
  fi
fi

# Move the files
mkdir $destination
mv -v $BACKUP_DIR/backup.incoming/* $destination



