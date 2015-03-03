#!/bin/bash
#@author @Todi Adiyatmo Wijoyo based on 
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description Backup script for your website

# --------------------------
# Edit this configuration !! 
# THESE WILL BE THE SETTINGS
# IF YOU DO NOT SPECIFY THEM
# WITH SWITCHES.
# --------------------------

# -------------------
# Backup Destination option, please read the README to find the possible value
# --------------------

# A Temporary Location to work with files , DO NOT END THE DIRECTORY WITH BACKSLASH ! 

TMP_LOCATION=/tmp

# The directory to be backed up , DO NOT END THE DIRECTORY WITH BACKSLASH ! 

BACKUP_DIR=/target_directory

# The directory where the backups are sent , DO NOT END THE DIRECTORY WITH BACKSLASH ! 
TARGET_DIR=/copy_target_to_backup_directory

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

# --------------------------------------------------
# Default Backup Options
# Here you can set what you want to be backed up by
# Default. 0 = no ; 1 = yes
# If you use the switches and not this config file
# Thes settings will be toggled automatically.
# --------------------------------------------------

# 0 or 1
LOCAL_BACKUP_OPTION=0
FTP_BACKUP_OPTION=0

#--------------------------------------
# You may set when you want to schedule
# a backup of the SQL databases or the 
# physical files by setting the number 
# between 1-7. The chart below will 
# help you know which to pick.
#----------------------------------#
# Daily | Weekly | Monthly | Value #
#-------|--------|---------|-------#
#  Yes  |   No   |    No   |   1   #
#  No   |   Yes  |    No   |   2   #
#  Yes  |   Yes  |    No   |   3   #
#  No   |   No   |   Yes   |   4   #
#  Yes  |   No   |   Yes   |   5   #
#  No   |   Yes  |   Yes   |   6   #
#  Yes  |   Yes  |   Yes   |   7   #
#----------------------------------#

#Between 1-7
SQL_BACKUP_OPTION=0
FILES_BACKUP_OPTION=0

# -----------------
# End configuration
# -----------------

RUN_NOW=0
#------------------
#Begin Switches
#------------------

while [ "$#" -gt 0 ];
do
  case "$1" in
    -h|--help)
      echo "-h|--help was triggered"
      exit 1
      ;;

    --both)
      LOCAL_BACKUP_OPTION=1
      FTP_BACKUP_OPTION=1
      ;;

    --ftp)
      FTP_BACKUP_OPTION=1
      if [ "$#" -gt 1 ]; then
        if [ ! "$2" = \-* ]; then
          if [[ ! "$3" = \-* && ! "$4" = \-* && ! "$5" = \-* && ! "$6" = \-* && ! "$3" == "" && ! "$4" == "" && ! "$5" = "" && ! "$6" = "" ]]; then
            FTP_HOST=$2
            FTP_PORT=$3
            FTP_USER=$4
            FTP_PASSWORD=$5
            FTP_TARGET_DIR=$6
            shift 5
          else
            echo "Error in --ftp syntax. Script failed."
            exit 1
          fi
        fi
      fi
      ;;

    --sql)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        SQL_BACKUP_OPTION=$2
        if [[ ! "$3" = \-* && ! "$4" = \-* && ! "$5" = \-* && ! "$6" = \-* && ! "$3" == "" && ! "$4" == "" && ! "$5" = "" && ! "$6" = "" ]]; then
            DB_HOST=$3
            DB_USER=$4
            DB_PASSWORD=$5
            DB_DATABASE=$6
            shift 4
        else
            echo "Error in --sql syntax. Script failed."
            exit 1
        fi
        shift
      fi
      ;;

    --now)
      RUN_NOW=1      
      ;;

    -bd|--backupdir)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
        FILES_BACKUP_OPTION=$2
        if [[ ! "$3" = \-* && ! "$3" == "" ]]; then
          BACKUP_DIR=${3%/}
          shift 2
        else
          echo "Error in -bd|--backupdir syntax. Script failed."
          exit 1
        fi  
      fi
      ;;


    -td|--targetdir)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
       TARGET_DIR=${2%/}
       LOCAL_BACKUP_OPTION=1
       shift 
      else
        echo "Error in -td|--targetdir syntax. Script failed."
        exit 1
      fi
      ;;

    -e|--email)
      if [[ "$#" -gt 1 && ! "$2" = \-* ]]; then
      MAIL=$2
      shift
      else
        echo "Error in -e|--email syntax. Script failed."
        exit 1
      fi  
      ;;

    -r|--retention)
      if [[ "$#" -gt 1 && ! "$2" = \-* && ! "$3" = \-* && ! "$4" = \-* && ! "$3" == "" && ! "$4" == "" ]]; then
        RETENTION_DAY=$2
        RETENTION_WEEK=$3
        RETENTION_MONTH=$4
        shift 3
      else
        echo "Error in -r|--retention syntax. Script failed."
        exit 1
      fi  
      ;;

    -d|--dates)
      if [[ "$#" -gt 1 && ! "$2" = \-* && ! "$3" = \-* && ! "$3" == "" ]]; then
        MONTHLY_BACKUP_DATE=$2
        WEEKLY_BACKUP_DAY=$3
        shift 2
      else
        echo "Error in -d|--dates syntax. Script failed."
        exit 1
      fi  
      ;;

    --)              # End of all options.
        shift
        break
        ;;

    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;

    '') # Empty case: If no more options then break out of the loop.
        break
        ;;

    *)  # Anything unrecognized     
        echo "The value "$1" was not expected. Script failed."
        exit 1
        ;;
  esac

  shift
done

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
mkdir $TMP_DIR/.ftp_cache/ 
cd $TMP_DIR/.ftp_cache/ 
find -maxdepth 1 -name "*$BACKUP_TYPE*" -mtime +$RETENTION_DAY_LOOKUP >>  $TMP_DIR/.ftp_cache/search_file.tmp
cd $CURRENT_DIR

#delete old files
find $TMP_DIR/ -maxdepth 1 -mtime +$RETENTION_DAY_LOOKUP -name "*$BACKUP_TYPE*" -exec rm -rv {} \;
find $TMP_DIR/.ftp_cache/ -maxdepth 1 -mtime +$RETENTION_DAY_LOOKUP -name "*$BACKUP_TYPE*" -exec rm -rv {} \;

PERFORM_SQL_BACKUP=0
PERFORM_FILES_BACKUP=0

# Check wheter to do backup
# This no longer is FTP or LOCAL
# but rather if the backup of the
# files should be SQL or FILES.
if [[ $(( $COMPARATOR & $SQL_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_SQL_BACKUP=1 
fi

if [[ $(( $COMPARATOR & $FILES_BACKUP_OPTION )) == $COMPARATOR ]]; then
  PERFORM_FILES_BACKUP=1 
fi

#This will force the backup to run immediately.
if [ $RUN_NOW -eq 1 ]; then
PERFORM_LOCAL_BACKUP=$LOCAL_BACKUP_OPTION
PERFORM_FTP_BACKUP=$FTP_BACKUP_OPTION
PERFORM_SQL_BACKUP=$SQL_BACKUP_OPTION
PERFORM_FILES_BACKUP=$FILES_BACKUP_OPTION
fi

mkdir $TMP_DIR
mkdir $TMP_DIR/backup.incoming

cd $TMP_DIR/backup.incoming
# Destination file names
base_backup_filename=`date +"%d-%m-%Y"`$BACKUP_TYPE
backup_filename=$base_backup_filename'.tar.gz'

if [ ! $PERFORM_SQL_BACKUP -eq 0 ]; then

  # Destination file names
  backup_filename=$base_backup_filename'.sql.tar.bz2'

  # Dump MySQL tables
  mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_DATABASE > $TMP_DIR/backup.incoming/mysql_dump.sql

  # Compress tables and files
  cd $TARGET_DIR
  tar -cjf $TMP_DIR/backup.incoming/$backup_filename $TMP_DIR/backup.incoming/mysql_dump.sql

  #clean sql file
  rm $TMP_DIR/backup.incoming/mysql_dump.sql
fi

cd $CURRENT_DIR

# Optional check if source files exist. Email if failed.
if [ ! -f $TMP_DIR/backup.incoming/$backup_filename ]; then
  mail $MAIL -s "[backup script] Daily backup failed! Please check for missing files."
fi

#Preform Files Backup
if [ ! $PERFORM_FILES_BACKUP -eq 0 ]; then
  backup_filename=$base_backup_filename'.data.tar.bz2'

  # Compress files
  cd $TARGET_DIR
  tar -cjf $TMP_DIR/backup.incoming/$backup_filename $BACKUP_DIR
fi

# FTP
if [ ! $FTP_BACKUP_OPTION -eq 0 ]; then

  #create cache copy to detect the remote file
  mkdir $TMP_DIR/.ftp_cache
  touch $TMP_DIR/.ftp_cache/$backup_filename 

  echo "user $FTP_USER $FTP_PASSWORD" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "mkdir $FTP_TARGET_DIR" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "cd $FTP_TARGET_DIR" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "binary" >> $TMP_DIR/backup.incoming/ftp_command.tmp
  echo "put $TMP_DIR/backup.incoming/$backup_filename ." >> $TMP_DIR/backup.incoming/ftp_command.tmp
  for f in $(<$TMP_DIR/.ftp_cache/search_file.tmp)
  do
   echo "delete ${f/.\//}" >>  $TMP_DIR/backup.incoming/ftp_command.tmp
  done
  echo "bye" >>  $TMP_DIR/backup.incoming/ftp_command.tmp 

  ftp -n -v $FTP_HOST $FTP_PORT < $TMP_DIR/backup.incoming/ftp_command.tmp

  #remove ftp_command
  rm $TMP_DIR/backup.incoming/ftp_command.tmp 
fi


#Perform local backup
if [ ! $LOCAL_BACKUP_OPTION -eq 0 ]; then

  # Move the files
  mkdir $BACKUP_DIR
  mv -v $TMP_DIR/backup.incoming/* $TARGET_DIR
fi

# Cleanup
rm -rf $TMP_DIR/backup.incoming/

# Remove cache tmp file
rm -rf $TMP_DIR/.ftp_cache/
