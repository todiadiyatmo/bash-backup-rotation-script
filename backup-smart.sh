#!/bin/bash

BACKUP_FOLDER_SHARED_ROOT_WITH_TRAILING_SLASH=/mnt/helix_v4_backup/backups/www/
ABS_PATH_TO_FOLDER_TO_BACKUP=/var/www/

      ####################
    ########################
  ############################
################################
## DO NOT EDIT ANYTHING BELOW ##
################################
  ############################
    ########################
      ####################

cd $BACKUP_FOLDER_SHARED_ROOT_WITH_TRAILING_SLASH;

function monthly
{
	[ -d monthly.06 ] && rm -rf monthly.06
	[ -d monthly.05 ] && mv monthly.05 monthly.06
	[ -d monthly.04 ] && mv monthly.04 monthly.05
	[ -d monthly.03 ] && mv monthly.03 monthly.04
	[ -d monthly.02 ] && mv monthly.02 monthly.03
	[ -d monthly.01 ] && mv monthly.01 monthly.02
	cp -al daily.00 monthly.01
}

function weekly
{
	[ -d weekly.04 ] && rm -rf weekly.04
	[ -d weekly.03 ] && mv weekly.03 weekly.04
	[ -d weekly.02 ] && mv weekly.02 weekly.03
	[ -d weekly.01 ] && mv weekly.01 weekly.02
	cp -al daily.00 weekly.01
}

function backup
{
	[ -d daily.14 ] && rm -rf daily.14
	[ -d daily.13 ] && mv daily.13 daily.14
	[ -d daily.12 ] && mv daily.12 daily.13
	[ -d daily.11 ] && mv daily.11 daily.12
	[ -d daily.10 ] && mv daily.10 daily.11
	[ -d daily.09 ] && mv daily.09 daily.10
	[ -d daily.08 ] && mv daily.08 daily.09
	[ -d daily.07 ] && mv daily.07 daily.08
	[ -d daily.06 ] && mv daily.06 daily.07
	[ -d daily.05 ] && mv daily.05 daily.06
	[ -d daily.04 ] && mv daily.04 daily.05
	[ -d daily.03 ] && mv daily.03 daily.04
	[ -d daily.02 ] && mv daily.02 daily.03
	[ -d daily.01 ] && mv daily.01 daily.02
	[ -d daily.00 ] && cp -al daily.00 daily.01
	rsync -a --delete ${ABS_PATH_TO_FOLDER_TO_BACKUP} daily.00/

	#Get the month and day of weeks as numbers
	MONTH=`date +%d`
	DAYWEEK=`date +%u`

	#Fix problems with octal numbers by removing leading zero
	#See https://stackoverflow.com/a/12821845/231316
	MONTH=${MONTH#0}
	DAYWEEK=${DAYWEEK#0}

	if [[ ( $MONTH -eq 1 ) ]];
	        then
	        monthly
	fi

	if [[ ( $DAYWEEK -eq 7 ) ]];
	        then
	        weekly
	fi
}


backup
