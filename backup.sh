#!/bin/bash

# Configuration Filename
CONF="backup.conf"

# Script Filename
SCRIPT="backup_rotation.sh"

# Do not edit below this line
CONF=${PWD}/$CONF
SCRIPT=${PWD}/$SCRIPT

DATETIME=`date '+%Y%m%d'`
umask 066
exec < $CONF

while read line
do
        if [ -n "$line" ]
        then
                if  [ ${line:0:1} != '#' ]
                then
                        TYPE=`echo $line | awk '{print $1}'`
                        HOST=`echo $line | awk '{print $2}'`
                        SQLFR=`echo $line | awk '{print $3}'`
                        DATABASE=`echo $line | awk '{print $4}'`
                        USER=`echo $line | awk '{print $5}'`
                        PASSWORD=`echo $line | awk '{print $6}'`
                        FILES_FR=`echo $line | awk '{print $7}'`
                        DIRECTORY=`echo $line | awk '{print $8}'`
                        DEST_BASE_DIR=`echo $line | awk '{print $9}'`

                        echo "$HOST,$DATABASE,$USER,$PASSWORD,$DATABASE,$DEST_BASE_DIR"
                        DEST_DIR="$DEST_BASE_DIR/$HOST/$DATABASE"

                        if [ ! -e "$DIRECTORY" ]; then
                                mkdir "$DIRECTORY"
                        fi
                        if [ ! -e "$DEST_DIR" ]; then
                                mkdir "$DEST_DIR"
                        fi

                        if  [ "$TYPE" == 'local' ]; then
                          $SCRIPT --sql "$SQLFR" $HOST $USER $PASSWORD $DATABASE --backupdir "$FILES_FR" $DIRECTORY --targetdir "$DEST_DIR"
                        fi

                        if  [ "$TYPE" == 'ftp' ]; then
                          FTP_HOST=`echo $line | awk '{print $10}'`
                          FTP_PORT=`echo $line | awk '{print $11}'`
                          FTP_USER=`echo $line | awk '{print $12}'`
                          FTP_PASSWORD=`echo $line | awk '{print $13}'`
                          $SCRIPT --sql "$SQLFR" $HOST $USER $PASSWORD $DATABASE --backupdir "$FILES_FR" $DIRECTORY --ftp "$FTP_HOST" "$FTP_PORT" "$FTP_USER" "$FTP_PASSWORD" "$DEST_DIR"
                        fi

                fi
        fi
done