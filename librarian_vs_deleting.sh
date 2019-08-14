#!/bin/bash

# site_name site_loc back_loc db_name db_user db_pass

curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$(date +%Y%m%d-%H%M%S) Starting backup process on $HOSTNAME!" > /dev/null 2>&1

NOW=$(date +%Y%m%d-%H%M%S)
LOG=/root/backup.log

FILES=1
DB=1

BACKUP_PSW_FILE=/root/.database
# parsing ALL variables from .database

OLD_IFS="$IFS"
IFS=$'\n'

BACKUP_USER_SSH_KEY='/root/backupuser_rsa'
BACKUP_USERNAME='backupuser'
TG_CHAT_ID='-1234567890'
TG_BOT_TOKEN='641268113:AAGq1odlUPyootjusvKO7xHum8k9wZTaL2Y'

for LINE in `cat $BACKUP_PSW_FILE`; do
    IFS=' '
    ARRAY=($LINE)
    site_name=${ARRAY[0]}
    site_loc=${ARRAY[1]}
    back_loc=${ARRAY[2]}
    db_name=${ARRAY[3]}
    db_user=${ARRAY[4]}
    db_pass=${ARRAY[5]}
    backup_server=${ARRAY[6]}

echo "$(date)=====================START $site_name backup======================" >> $LOG

# ARCHIVING WEB SITES INTO TAR.GZ

    if tar -zcpf $back_loc/$NOW-$site_name.tar.gz $site_loc; then
      echo "$(date) $NOW-$site_name.tar.gz creation PASS" >> $LOG
  if gunzip -c $back_loc/$NOW-$site_name.tar.gz | tar t > /dev/null; then
          echo "$(date) $NOW-$site_name.tar.gz check PASS" >> $LOG
    FILES=0
        else
    echo "$(date) $NOW-$site_name.tar.gz check FAIL" >> $LOG
        fi
    else
        echo "$(date) $NOW-$site_name.tar.gz creation FAIL" >> $LOG
    curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Archiving TAR.GZ failed!" > /dev/null 2>&1
  fi

# CREATING SQL DATABASES DUMPS
    if mysqldump -u $db_user -p$db_pass --single-transaction --quick --lock-tables=false $db_name | gzip > $back_loc/$NOW-$site_name.sql.gz; then
      echo "$(date) $NOW-$site_name.sql.gz creation PASS" >> $LOG
        if gunzip -t $back_loc/$NOW-$site_name.sql.gz; then
          echo "$(date) $NOW-$site_name.sql.gz check PASS" >> $LOG
      DB=0
        else
          echo "$(date) $NOW-$site_name.sql.gz check FAIL" >> $LOG
      curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name checking sql.gz failed!" > /dev/null 2>&1
        fi
    else
      echo "$(date) $NOW-$site_name.sql.gz creation FAIL" >> $LOG
      curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Making sql.gz failed!" > /dev/null 2>&1
    fi
#===================================


# COPY SITES IN TAR.GZ FORMAT TO BACKUP

    if [ $FILES -eq 0 ]; then
      echo "$(date) $NOW-$site_name.tar.gz upload START" >> $LOG
        if scp -i $BACKUP_USER_SSH_KEY $back_loc/$NOW-$site_name.tar.gz $BACKUP_USERNAME@$backup_server:/var/backup/$site_name/; then
    echo "$(date) $NOW-$site_name.tar.gz upload FINISH" >> $LOG
        else
    echo "$(date) $NOW-$site_name.tar.gz upload FAIL" >> $LOG
    curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Copying TAR.GZ to Backup Server failed!" > /dev/null 2>&1
        fi
    else
          echo "$(date) $NOW-$site_name.tar.gz upload FAIL" >> $LOG
          curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Copying TAR.GZ to Backup Server failed!" > /dev/null 2>&1
    fi
#===================================


#  COPY SQL IN .GZ FORMAT TO BACKUP
    if [ $DB -eq 0 ]; then
      echo "$(date) $NOW-$site_name.sql.gz upload START" >> $LOG
  if scp -i $BACKUP_USER_SSH_KEY $back_loc/$NOW-$site_name.sql.gz $BACKUP_USERNAME@$backup_server:/var/backup/$site_name/; then
    echo "$(date) $NOW-$site_name.sql.gz upload FINISH" >> $LOG
        else
      echo "$(date) $NOW-$site_name.sql.gz upload FAIL" >> $LOG
      curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Copying SQL.GZ to Hdrive failed!" > /dev/null 2>&1
        fi
    else
      echo "$(date) $NOW-$site_name.sql.gz upload FAIL" >> $LOG
      curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$site_name Copying SQL.GZ to Hdrive failed!" > /dev/null 2>&1
    fi
#===================================


# REMOVING FILES FROM DISK =========

echo "$(date) $NOW-$site_name removing has started" >> $LOG
    if `rm -rf /var/backup/$site_name/*`; then
      echo "$(date) $NOW-$site_name were removed" >> $LOG
    else
      echo "$(date) $NOW-$site_name are not removed" >> $LOG
      curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=Removing files for $site_name failed!" > /dev/null 2>&1
    fi

#===================================

echo "$(date)=====================FINISH $site_name backup=====================" >> $LOG

done

IFS="$OLD_IFS"

curl "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage?chat_id=$TG_CHAT_ID&text=$(date +%Y%m%d-%H%M%S) Backuping on $HOSTNAME was done!"  > /dev/null 2>&1
