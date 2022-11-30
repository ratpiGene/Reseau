# Module 2 : Réplication de base de données

Il y a plein de façons de mettre en place de la réplication de base données de type MySQL (comme MariaDB).

MariaDB possède un mécanisme de réplication natif qui peut très bien faire l'affaire pour faire des tests comme les nôtres.

Une réplication simple est une configuration de type "master-slave". Un des deux serveurs est le _master_ l'autre est un _slave_.

Le _master_ est celui qui reçoit les requêtes SQL (des applications comme NextCloud) et qui les traite.

Le _slave_ ne fait que répliquer les donneés que le _master_ possède.

La [doc officielle de MariaDB](https://mariadb.com/kb/en/setting-up-replication/) ou encore [cet article cool](https://cloudinfrastructureservices.co.uk/setup-mariadb-replication/) expose de façon simple comment mettre en place une telle config.

Pour ce module, vous aurez besoin d'un deuxième serveur de base de données.

```
CREATE USER 'replication_user'@'10.102.1.14' IDENTIFIED BY *****;
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'10.102.1.14';
```

```
[gene@db ~]$ sudo mariabackup --backup    --target-dir=/backup/    --user=root --password=*****
[gene@db2 ~]$ scp -r root@10.102.1.12:/backup/* /backup/
[gene@db2 ~]$ mariabackup --prepare --target-dir=/backup/
[gene@db2 ~]$ mariabackup --copy-back --target-dir=/backup/
```

```
MariaDB [(none)]> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 10.102.1.12
                   Master_User: replication_user
                   Master_Port: 3306
                 Connect_Retry: 10
               Master_Log_File: master1-bin.000004
           Read_Master_Log_Pos: 389
                Relay_Log_File: mariadb-relay-bin.000002
                 Relay_Log_Pos: 557
         Relay_Master_Log_File: master1-bin.000004
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
```

**Première DB :**

```
MariaDB [(none)]> CREATE DATABASE test2;
Query OK, 1 row affected (0.000 sec)
```

**Backup :**

```
MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| nextcloud          |
| performance_schema |
| test2              |
+--------------------+
```

✨ **Bonus** : Faire en sorte que l'utilisateur créé en base de données ne soit utilisable que depuis l'autre serveur de base de données

```
CREATE USER 'replication_user'@'10.102.1.14' IDENTIFIED BY *****;
```

✨ **Bonus** : Mettre en place un setup _master-master_ où les deux serveurs sont répliqués en temps réel, mais les deux sont capables de traiter les requêtes.

_Flemme_
