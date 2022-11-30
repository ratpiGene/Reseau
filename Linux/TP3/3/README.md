# Module 3 : Sauvegarde de base de données

Dans cette partie le but va être d'écrire un script `bash` qui récupère le contenu de la base de données utilisée par NextCloud, afin d'être en mesure de restaurer les données plus tard si besoin.

Le script utilisera la commande `mysqldump` qui permet de récupérer le contenu de la base de données sous la forme d'un fichier `.sql`.

Ce fichier `.sql` on pourra ensuite le compresser et le placer dans un dossier dédié afin de l'archiver.

Une fois le script fonctionnel, on créera alors un service qui permet de déclencher l'exécution de ce script dans de bonnes conditions.

Enfin, un _timer_ permettra de déclencher l'exécution du _service_ à intervalles réguliers.

## I. Script dump + II. Clean it

➜ **Créer un utilisateur DANS LA BASE DE DONNEES**

```
MariaDB [(none)]> CREATE USER 'dump'@'localhost' IDENTIFIED BY 'azerty';
Query OK, 0 rows affected (0.338 sec)
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'dump'@'localhost';
Query OK, 0 rows affected (0.001 sec)
```

➜ **Ecrire le script `bash`**

[Script](tp3_db_dump.sh)

➜ **Environnement d'exécution du script**

```
[gene@db ~]$ cat /etc/passwd | grep db_
db_dumps:x:1001:1001::/srv/db_dumps/:/usr/bin/nologin
[gene@db ~]$ sudo ls -al /srv/db_dumps/
total 144
drwx------. 2 db_dumps db_dumps  4096 Nov 23 20:45 .
drwxr-xr-x. 3 root     root        59 Nov 23 19:17 ..
```

- pour tester l'exécution du script en tant que l'utilisateur `db_dumps`, utilisez la commande suivante :

```bash
[gene@db srv]$ sudo -u db_dumps bash tp3_db_dump.sh
```

## III. Service et timer

➜ **Créez un _service_** système qui lance le script

[Service](db_dump.service)

➜ **Créez un _timer_** système qui lance le _service_ à intervalles réguliers

[Timer](db_dump.timer)

```
[gene@db ~]$ sudo systemctl start db-dump
[gene@db ~]$ sudo ls -l /srv/db_dumps/
total 140
-rw-r--r--. 1 db_dumps db_dumps 25431 Nov 23 21:11 db_nextcloud_20221121142537.tar.gz
[gene@db ~]$ sudo systemctl daemon-reload
```

```
[gene@db ~]$ sudo systemctl start db-dump.timer
[gene@db ~]$ sudo systemctl enable db-dump.timer
Created symlink /etc/systemd/system/timers.target.wants/db-dump.timer → /etc/systemd/system/db-dump.timer.
[gene@db ~]$ sudo systemctl status db-dump.timer
● db-dump.timer - Run service db_dump
     Loaded: loaded (/etc/systemd/system/db-dump.timer; enabled; vendor preset: disabled)
     Active: active (waiting) since Mon 2022-11-23 21:13:02 CET; 25s ago
      Until: Mon 2022-11-23 21:13:02 CET; 25s ago
    Trigger: Tue 2022-11-24 10:00:00 CET; 13h left
   Triggers: ● db-dump.service
Nov 21 14:27:02 db.tp2.linux systemd[1]: Started Run service db_dump.
[gene@db ~]$ sudo systemctl list-timers | grep db-dump
Tue 2022-11-24 10:00:00 CET 13h left      n/a                         n/a          db-dump.timer                db-dump.service
```

➜ **Tester la restauration des données** sinon ça sert à rien :)

- livrez-moi la suite de commande que vous utiliseriez pour restaurer les données dans une version antérieure

```bash
[gene@db srv]$ sudo systemctl start db-dump
[gene@db srv]$ sudo -u db_dumps ls /srv/db_dumps/
db_nextcloud_221122_181742.tar.gz
[gene@db srv]$ sudo mysql -u root
MariaDB [(none)]> USE nextcloud;
MariaDB [nextcloud]> SELECT FOUND_ROWS();
+--------------+
| FOUND_ROWS() |
+--------------+
|           95 |
+--------------+
1 row in set (0.000 sec)
MariaDB [nextcloud]> DROP TABLE oc_accounts;
Query OK, 0 rows affected (0.052 sec)
MariaDB [nextcloud]> SELECT FOUND_ROWS();
+--------------+
| FOUND_ROWS() |
+--------------+
|           94 |
+--------------+
1 row in set (0.000 sec)
[gene@db srv]$ sudo -u db_dumps tar -xzf db_dumps/db_nextcloud_221122_181742.tar.gz
[gene@db srv]$ sudo -u db_dumps ls /srv/db_dumps/
db_nextcloud_221122_181742.sql  db_nextcloud_221122_181742.tar.gz
[gene@db srv]$ sudo -u db_dumps mysql -u db_dumps -p nextcloud < db_dumps/db_nextcloud_221122_181742.sql
Enter password:
[gene@db srv]$ sudo mysql -u root
MariaDB [(none)]> USE nextcloud;
MariaDB [nextcloud]>  SELECT FOUND_ROWS();
+--------------+
| FOUND_ROWS() |
+--------------+
|           95 |
+--------------+
1 row in set (0.000 sec)
```

Footer
© 2022 GitHub, Inc.
Footer navigation

    Terms
    Privacy
    Security
    Status
    Docs
    Contact GitHub
    Pricing
    API
    Training
    Blog
    About
