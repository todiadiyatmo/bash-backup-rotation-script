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
BACKUP_DIR=/copy_target_to_backup_directory

# Admin email
MAIL="your_email@email.com"

# Number of day the daily backup keep
RETENTION_DAY=2

# Number of day the weekly backup keep
RETENTION_WEEK=14

# Number of day the monthly backup keep
RETENTION_MONTH=60

#Monthly date backup option (day of month)
MONTHLY_BACKUP_DATE=1

#Weekly day to backup option (day of week - 1 is monday )
WEEKLY_BACKUP_DAY=6

# -----------------
# FTP Configuration
# Enter all data within the ' ' single quote !
# -----------------

#This is the FTP servers host or IP address. 
FTP_HOST='ftp.yourhost.com' 

#FTP PORT
FTP_PORT=21

#This is the FTP user that has access to the server. 
FTP_USER='user'           

#This is the password for the FTP user. 
FTP_PASSWORD='password'          

#The backup directory on remote machine, DO NOT END THE DIRECTORY WITH BACKSLASH ! 
FTP_TARGET_DIR='ftp_target_dir'

# --------------------------------------------------
# MYSQL Configuration
# Enter all data within the ' ' single quote !
# --------------------------------------------------

DB_USER='db_user'
DB_PASSWORD='db_pass'
DB_DATABASE='db_database'
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
    BACKUP_TYPE='-monthly'
    RETENTION_DAY_LOOKUP=$RETENTION_MONTH
    
    COMPARATOR=4
  else
  # On saturdays do
    if [ "$week_day" -eq $WEEKLY_BACKUP_DAY ] ; then
    # weekly - keep for RETENTION_WEEK
    BACKUP_TYPE='-weekly'
    RETENTION_DAY_LOOKUP=$RETENTION_WEEK

    COMPARATOR=2
  else
    # On any regular day do
      BACKUP_TYPE='-daily'
      RETENTION_DAY_LOOKUP=$RETENTION_DAY

      COMPARATOR=1
    fi
  fi

CURRENT_DIR=${PWD}

#create cache to delete
cd $BACKUP_DIR/.ftp_cache/ 
find -maxdepth 1 -name '*$BACKUP_TYPE*' -mtime +$RETENTION_DAY_LOOKUP >>  $BACKUP_DIR/.ftp_cache/search_file.tmp
cd $CURRENT_DIR

#delete old files
find $BACKUP_DIR/ -maxdepth 1 -mtime +$RETENTION_DAY_LOOKUP -name '*$BACKUP_TYPE*' -exec rm -rv {} \;
find $BACKUP_DIR/.ftp_cache/ -maxdepth 1 -mtime +$RETENTION_DAY_LOOKUP -name '*$BACKUP_TYPE*' -exec rm -rv {} \;



PERFORM_LOCAL_BACKUP=0
PERFORM_FTP_BACKUP=0

# Check wheter to do backup
if [[ $(( $COMPARATOR & $LOCAL_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_LOCAL_BACKUP=1 
fi

if [[ $(( $COMPARATOR & $FTP_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_FTP_BACKUP=1 
fi

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

  #create cache copy to detect the remote file
  mkdir $BACKUP_DIR/.ftp_cache
  touch $BACKUP_DIR/.ftp_cache/$backup_filename 

  echo "user $FTP_USER $FTP_PASSWORD" >> $BACKUP_DIR/backup.incoming/ftp_command.tmp
  echo "mkdir $FTP_TARGET_DIR" >> $BACKUP_DIR/backup.incoming/ftp_command.tmp
  echo "cd $FTP_TARGET_DIR" >> $BACKUP_DIR/backup.incoming/ftp_command.tmp
  echo "binary" >> $BACKUP_DIR/backup.incoming/ftp_command.tmp
  echo "put $BACKUP_DIR/backup.incoming/$backup_filename ." >> $BACKUP_DIR/backup.incoming/ftp_command.tmp
  for f in $(<$BACKUP_DIR/.ftp_cache/search_file.tmp)
  do
   echo "delete ${f/.\//}" >>  $BACKUP_DIR/backup.incoming/ftp_command.tmp
  done
  echo "bye" >>  $BACKUP_DIR/backup.incoming/ftp_command.tmp 

  ftp -n -v $FTP_HOST $FTP_PORT < $BACKUP_DIR/backup.incoming/ftp_command.tmp

  #remove ftp_command
  rm $BACKUP_DIR/backup.incoming/ftp_command.tmp 
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

# Remove cache tmp file
rm $BACKUP_DIR/.ftp_cache/search_file.tmp