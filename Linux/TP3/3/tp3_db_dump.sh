#!/bin/bash
#Ecrit le 23/11/22 par gene.
#En gros le script permet la création de backups versionnées d'une base de données en utilisant mysqldump.

#All variables
user="dump"
source /srv/db_pass
date=$(date +%y%m%d%H%M%S)
basename="nextcloud"
name=("db_${basename}_${date}")
filepath=db_dumps/"$name"

#Backup creation
/usr/bin/mysqldumpmysqldump -u ${user} -p${password} ${basename} > ${filepath}.sql
/usr/bin/tar zcf  "${filepath}.tar.gz" --remove-files "${filepath}.sql"