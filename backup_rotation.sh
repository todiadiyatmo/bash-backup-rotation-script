#!/bin/bash
#@author @Todi Adiyatmo Wijoyo based on 
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description Backup script for your website

# --------------------------
# Edit this configuration !! 
# --------------------------

# -------------------
# Backup Destination option, please read the README to find the possible value
# --------------------

LOCAL_BACKUP_OPTION=7

FTP_BACKUP_OPTION=7

# The directory to be backup , DO NOT END THE DIRECTORY WITH BACKSLASH ! 
TARGET_DIR=/target_directory

# The backup directory , DO NOT END THE DIRECTORY WITH BACKSLASH ! 
BACKUP_DIR=/your_backup_direcory

# Admin email
MAIL="your_email@email.com"

# Number of day the daily backup keep
RETENTION_DAY=3

# Number of day the weekly backup keep
RETENTION_WEEK=14

# Number of day the monthly backup keep
RETENTION_MONTH=30

#Monthly date backup option (day of month)
MONTHLY_BACKUP_DATE=1

#Weekly day to backup option (day of week - 1 is monday )
WEEKLY_BACKUP_DAY=6

# -----------------
# FTP Configuration
# Enter all data within the ' ' single quote !
# -----------------

#This is the FTP servers host or IP address. 
FTP_HOST='FTP HOST' 

#FTP PORT
FTP_PORT=21

#This is the FTP user that has access to the server. 
FTP_USER='FTP USER'           

#This is the password for the FTP user. 
FTP_PASSWORD='FTP_PASSWORD'          

#The backup directory on remote machine, DO NOT END THE DIRECTORY WITH BACKSLASH ! 
FTP_TARGET_DIR='/remote_path'

# --------------------------------------------------
# MYSQL Configuration
# Enter all data within the ' ' single quote !
# --------------------------------------------------

DB_USER='DB USER'
DB_PASSWORD='DB PASSWORD'
DB_DATABASE='DB DATABASE'
DB_HOST='127.0.0.1'

# -----------------
# End configuration
# -----------------

# STARTING BACKUP SCRIPT

#Check date

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# On first month day do
if [ "$month_day" -eq $MONTHLY_BACKUP_DATE ] ; then
    BACKUP_TYPE='_monthly'
    # daily - keep for RETENTION_DAY
    find $BACKUP_DIR/ -maxdepth 1 -mtime +$RETENTION_DAY -type d -exec rm -rv {} \;
    COMPARATOR=4
else
  # On saturdays do
  BACKUP_TYPE='_weekly'
  if [ "$week_day" -eq $WEEKLY_BACKUP_DAY ] ; then
    # weekly - keep for RETENTION_WEEK
    find $BACKUP_DIR/ -maxdepth 1 -mtime +$RETENTION_WEEK -type d -exec rm -rv {} \;
  
    COMPARATOR=2
  else
    # On any regular day do
    BACKUP_TYPE='_daily'
    # monthly - keep for RETENTION_MONTH
    find $BACKUP_DIR/ -maxdepth 1 -mtime +$RETENTION_MONTH -type d -exec rm -rv {} \;
   
    COMPARATOR=1
  fi
fi

PERFORM_LOCAL_BACKUP=0
PERFORM_FTP_BACKUP=0

# Check wheter to do backup
if [[ $(( $COMPARATOR & $LOCAL_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_LOCAL_BACKUP=1 
fi

if [[ $(( $COMPARATOR & $FTP_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_FTP_BACKUP=1 
fi


CURRENT_DIR=${PWD}

mkdir $BACKUP_DIR
mkdir $BACKUP_DIR/backup.incoming

cd $BACKUP_DIR/backup.incoming
# Destination file names
backup_filename=`date +"%d-%m-%Y"`$BACKUP_TYPE
backup_filename=$backup_filename'.tgz'

# Dump MySQL tables
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_DATABASE > $BACKUP_DIR/backup.incoming/mysql_dump.sql

# Compress tables and files
cd $TARGET_DIR
tar -czf $BACKUP_DIR/backup.incoming/$backup_filename -C $BACKUP_DIR/backup.incoming/ mysql_dump.sql $TARGET_DIR

#clean sql file
rm $BACKUP_DIR/backup.incoming/mysql_dump.sql

cd $CURRENT_DIR

# Optional check if source files exist. Email if failed.
if [ ! -f $BACKUP_DIR/backup.incoming/$backup_filename ]; then
	mail $MAIL -s "[backup script] Daily backup failed! Please check for missing files."
fi

# FTP
if [ $PERFORM_FTP_BACKUP -eq 1 ]; then
ftp -n -v $FTP_HOST $FTP_PORT << END_OF_SESSION
user $FTP_USER $FTP_PASSWORD
mkdir $FTP_TARGET_DIR
cd $FTP_TARGET_DIR
binary
put $BACKUP_DIR/backup.incoming/$backup_filename $FTP_TARGET_DIR/$backup_filename
bye
END_OF_SESSION
fi

#Perform local backup
if [ $PERFORM_LOCAL_BACKUP -eq 1 ]; then
 
  rm -rf $FTP_TARGET_DIR 

  # Move the files
  mkdir $BACKUP_DIR
  mv -v $BACKUP_DIR/backup.incoming/* $BACKUP_DIR
fi

# Cleanup
rm -rf $BACKUP_DIR/backup.incoming/