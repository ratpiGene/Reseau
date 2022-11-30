#!/bin/bash
# Ecrit le 23/11/2022 par gene.
# Ce script permet de créer des backups versionnées de fichiers importants nextcloud.


#All variables
file="nextcloud_$(date +"%y%m%d_%H%m%S")"
filepath="backup/${file}"
conf="/var/www/tp2_nextcloud/"

#Backup creation
/usr/bin/tar -czf "${filepath}.tar.gz" -C "${conf}" config data themes