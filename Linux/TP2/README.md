# TP2 : Gestion de service

Dans ce TP on va s'orienter sur l'**utilisation des systèmes GNU/Linux** comme un outil pour **faire tourner des services**. C'est le principal travail de l'administrateur système : fournir des services.

Ces services, on fait toujours la même chose avec :

- **installation** (opération ponctuelle)
- **configuration** (opération ponctuelle)
- **maintien en condition opérationnelle** (opération continue, tant que le service est actif)
- **renforcement niveau sécurité** (opération ponctuelle et continue : on conf robuste et on se tient à jour)

**Dans cette première partie, on va voir la partie installation et configuration.** Peu importe l'outil visé, de la base de données au serveur cache, en passant par le serveur web, le serveur mail, le serveur DNS, ou le serveur privé de ton meilleur jeu en ligne, c'est toujours pareil : install into conf.

On abordera la sécurité et le maintien en condition opérationelle dans une deuxième partie.

**On va apprendre à maîtriser un peu ces étapes, et pas simplement suivre la doc.**

On va maîtriser le service fourni :

- manipulation du service avec systemd
- quelle IP et quel port il utilise
- quels utilisateurs du système sont mobilisés
- quels processus sont actifs sur la machine pour que le service soit actif
- gestion des fichiers qui concernent le service et des permissions associées
- gestion avancée de la configuration du service

---

Bon le service qu'on va setup c'est NextCloud. **JE SAIS** ça fait redite avec l'an dernier, me tapez pas. ME TAPEZ PAS.

Mais vous inquiétez pas, on va pousser le truc, on va faire évoluer l'install, l'architecture de la solution. Cette première partie de TP, on réalise une install basique, simple, simple, basique, la version _vanilla_ un peu. Ce que vous êtes censés commencer à maîtriser (un peu, faites moi plais).

Refaire une install guidée, ça permet de s'exercer à faire ça proprement dans un cadre, bien comprendre, et ça me fait un pont pour les B1C aussi :)

On va faire évoluer la solution dans la suite de ce TP.

# Sommaire

- [TP2 : Gestion de service](#tp2--gestion-de-service)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Un premier serveur web](#i-un-premier-serveur-web)
  - [1. Installation](#1-installation)
  - [2. Avancer vers la maîtrise du service](#2-avancer-vers-la-maîtrise-du-service)
- [II. Une stack web plus avancée](#ii-une-stack-web-plus-avancée)
  - [1. Intro blabla](#1-intro-blabla)
  - [2. Setup](#2-setup)
    - [A. Base de données](#a-base-de-données)
    - [B. Serveur Web et NextCloud](#b-serveur-web-et-nextcloud)
    - [C. Finaliser l'installation de NextCloud](#c-finaliser-linstallation-de-nextcloud)

# 0. Prérequis

➜ Machines Rocky Linux

➜ Un unique host-only côté VBox, ça suffira. **L'adresse du réseau host-only sera `10.102.1.0/24`.**

➜ Chaque **création de machines** sera indiquée par **l'emoji 🖥️ suivi du nom de la machine**

➜ Si je veux **un fichier dans le rendu**, il y aura l'**emoji 📁 avec le nom du fichier voulu**. Le fichier devra être livré tel quel dans le dépôt git, ou dans le corps du rendu Markdown si c'est lisible et correctement formaté.

## Checklist

A chaque machine déployée, vous **DEVREZ** vérifier la 📝**checklist**📝 :

- [x] IP locale, statique ou dynamique
- [x] hostname défini
- [x] firewall actif, qui ne laisse passer que le strict nécessaire
- [x] SSH fonctionnel avec un échange de clé
- [x] accès Internet (une route par défaut, une carte NAT c'est très bien)
- [x] résolution de nom
- [x] SELinux désactivé (vérifiez avec `sestatus`, voir [mémo install VM tout en bas](https://gitlab.com/it4lik/b2-reseau-2022/-/blob/main/cours/memo/install_vm.md#4-pr%C3%A9parer-la-vm-au-clonage))

**Les éléments de la 📝checklist📝 sont STRICTEMENT OBLIGATOIRES à réaliser mais ne doivent PAS figurer dans le rendu.**

![Checklist](./pics/checklist_is_here.jpg)

# I. Un premier serveur web

## 1. Installation

🖥️ **VM web.tp2.linux**

| Machine         | IP            | Service     |
| --------------- | ------------- | ----------- |
| `web.tp2.linux` | `10.102.1.11` | Serveur Web |

🌞 **Installer le serveur Apache**

```
[gene@web ~]$ sudo dnf install httpd
[gene@web ~]$ vim /etc/httpd/conf/httpd.conf
```

🌞 **Démarrer le service Apache**

```
[gene@web ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
[gene@web ~]$ sudo systemctl start httpd
[gene@web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
[gene@web ~]$ sudo ss -alnpt
State       Recv-Q      Send-Q           Local Address:Port           Peer Address:Port      Process
LISTEN      0           128                    0.0.0.0:22                  0.0.0.0:*          users:(("sshd",pid=732,fd=3))
LISTEN      0           511                          *:80                        *:*          users:(("httpd",pid=5216,fd=4),("httpd",pid=5215,fd=4),("httpd",pid=5214,fd=4),("httpd",pid=497
```

🌞 **TEST**

```
[gene@web ~]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-11-16 19:22:04 CET; 11min ago
[...]
```

```
[gene@web ~]$ curl localhost
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      html {
[...]
```

## 2. Avancer vers la maîtrise du service

🌞 **Le service Apache...**

```
[gene@web ~]$ cat /usr/lib/systemd/system/httpd.service
[...]
[Service]
Type=notify
Environment=LANG=C
[...]
```

🌞 **Déterminer sous quel utilisateur tourne le processus Apache**

```
[gene@web ~]$ cat /etc/httpd/conf/httpd.conf
ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User apache
Group apache
```

```
[gene@web ~]$ ps -ef | grep http
root        4979       1  0 19:22 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      5213    4979  0 19:25 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      5214    4979  0 19:27 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      5215    4979  0 19:33 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      5216    4979  0 19:33 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
gene        5468    4317  0 19:51 pts/0    00:00:00 grep --color=auto http
```

```
[gene@web ~]$ ls -al /usr/share/testpage/
total 12
drwxr-xr-x.  2 root root   24 Nov 16 19:11 .
drwxr-xr-x. 81 root root 4096 Nov 16 19:13 ..
-rw-r--r--.  1 root root 7620 Jul  6 04:37 index.html
```

🌞 **Changer l'utilisateur utilisé par Apache**

```
[gene@web ~]$ sudo useradd weirdcat -m -s /sbin/nologin -u 2000
```

```
[gene@web ~]$ cat /etc/httpd/conf/httpd.conf
ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User weirdcat
Group weirdcat
[...]
```

```
[gene@web ~]$ systemctl restart httpd
[gene@web ~]$ ps -ef | grep httpd
root        5500       1  0 20:04 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
weirdca+    5501    5500  0 20:04 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
weirdca+    5502    5500  0 20:04 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
weirdca+    5503    5500  0 20:04 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
weirdca+    5504    5500  0 20:04 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
gene        5719    4317  0 20:04 pts/0    00:00:00 grep --color=auto httpd
```

🌞 **Faites en sorte que Apache tourne sur un autre port**

```
[gene@web ~]$ cat /etc/httpd/conf/httpd.conf | grep Listen
Listen 888
[gene@web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success
[gene@web ~]$ sudo firewall-cmd --add-port=888/tcp --permanent
success
[gene@web ~]$ sudo systemctl restart httpd
```

```
[gene@web ~]$ ss -alnpt
State                 Recv-Q                Send-Q                                Local Address:Port                                 Peer Address:Port                Process
LISTEN                0                     128                                         0.0.0.0:22                                        0.0.0.0:*
LISTEN                0                     128                                            [::]:22                                           [::]:*
LISTEN                0                     511                                               *:888                                             *:*
```

```
[gene@web ~]$ curl localhost:888
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      html {
        height: 100%;
        width: 100%;
[...]
```

📁 **Fichier `/etc/httpd/conf/httpd.conf`**

[conf](httpd.conf)

# II. Une stack web plus avancée

⚠⚠⚠ **Réinitialiser votre conf Apache avant de continuer** ⚠⚠⚠  
En particulier :

- reprendre le port par défaut
- reprendre l'utilisateur par défaut

## 1. Intro blabla

**Le serveur web `web.tp2.linux` sera le serveur qui accueillera les clients.** C'est sur son IP que les clients devront aller pour visiter le site web.

**Le service de base de données `db.tp2.linux` sera uniquement accessible depuis `web.tp2.linux`.** Les clients ne pourront pas y accéder. Le serveur de base de données stocke les infos nécessaires au serveur web, pour le bon fonctionnement du site web.

---

Bon le but de ce TP est juste de s'exercer à faire tourner des services, un serveur + sa base de données, c'est un peu le cas d'école. J'ai pas envie d'aller deep dans la conf de l'un ou de l'autre avec vous pour le moment, on va se contenter d'une conf minimale.

Je vais pas vous demander de coder une application, et cette fois on se contentera pas d'un simple `index.html` tout moche et on va se mettre dans la peau de l'admin qui se retrouve avec une application à faire tourner. **On va faire tourner un [NextCloud](https://nextcloud.com/).**

En plus c'est utile comme truc : c'est un p'tit serveur pour héberger ses fichiers via une WebUI, style Google Drive. Mais on l'héberge nous-mêmes :)

---

Le flow va être le suivant :

➜ **on prépare d'abord la base de données**, avant de setup NextCloud

- comme ça il aura plus qu'à s'y connecter
- ce sera sur une nouvelle machine `db.tp2.linux`
- il faudra installer le service de base de données, puis lancer le service
- on pourra alors créer, au sein du service de base de données, le nécessaire pour NextCloud

➜ **ensuite on met en place NextCloud**

- on réutilise la machine précédente avec Apache déjà installé, ce sera toujours Apache qui accueillera les requêtes des clients
- mais plutôt que de retourner une bête page HTML, NextCloud traitera la requête
- NextCloud, c'est codé en PHP, il faudra donc **installer une version de PHP précise** sur la machine
- on va donc : install PHP, configurer Apache, récupérer un `.zip` de NextCloud, et l'extraire au bon endroit !

![NextCloud install](./pics/nc_install.png)

## 2. Setup

🖥️ **VM db.tp2.linux**

**N'oubliez pas de dérouler la [📝**checklist**📝](#checklist).**

| Machines        | IP            | Service                 |
| --------------- | ------------- | ----------------------- |
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données |

### A. Base de données

🌞 **Install de MariaDB sur `db.tp2.linux`**

```
[gene@db ~]$ sudo dnf install mariadb-server
[...]
[gene@db ~]$ sudo systemctl enable mariadb
[...]
All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.
Thanks for using MariaDB!
```

```
[gene@db ~]$ ss -alntp
State                 Recv-Q                Send-Q                                Local Address:Port                                 Peer Address:Port                Process
LISTEN                0                     128                                         0.0.0.0:22                                        0.0.0.0:*
LISTEN                0                     80                                                *:3306                                            *:*
LISTEN                0                     128                                            [::]:22                                           [::]:*
[gene@db ~]$ sudo firewall-cmd --add-port=3306/tcp --permanent
success
[gene@db ~]$ sudo firewall-cmd --reload
success
```

🌞 **Préparation de la base pour NextCloud**

```
[gene@db ~]$ sudo mysql -u root -p
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 11
Server version: 10.5.16-MariaDB MariaDB Server
Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
MariaDB [(none)]> CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'azerty';
Query OK, 0 rows affected (0.019 sec)
MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.000 sec)
MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';
Query OK, 0 rows affected (0.015 sec)
MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

🌞 **Exploration de la base de données**

```
[gene@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 12
Server version: 5.5.5-10.5.16-MariaDB MariaDB Server
Copyright (c) 2000, 2022, Oracle and/or its affiliates.
Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
mysql>
```

🌞 **Trouver une commande SQL qui permet de lister tous les utilisateurs de la base de données**

```
[gene@db ~]$ sudo mysql -u root
[sudo] password for gene:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 13
Server version: 10.5.16-MariaDB MariaDB Server
Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
MariaDB [(none)]> SELECT user FROM mysql.user;
+-------------+
| User        |
+-------------+
| nextcloud   |
| mariadb.sys |
| mysql       |
| root        |
+-------------+
4 rows in set (0.001 sec)
```

### B. Serveur Web et NextCloud

⚠️⚠️⚠️ **N'OUBLIEZ PAS de réinitialiser votre conf Apache avant de continuer. En particulier, remettez le port et le user par défaut.**

🌞 **Install de PHP**

```bash
# On ajoute le dépôt CRB
$ sudo dnf config-manager --set-enabled crb
# On ajoute le dépôt REMI
$ sudo dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y

# On liste les versions de PHP dispos, au passage on va pouvoir accepter les clés du dépôt REMI
$ dnf module list php

# On active le dépôt REMI pour récupérer une version spécifique de PHP, celle recommandée par la doc de NextCloud
$ sudo dnf module enable php:remi-8.1 -y

# Eeeet enfin, on installe la bonne version de PHP : 8.1
$ sudo dnf install -y php81-php
```

🌞 **Install de tous les modules PHP nécessaires pour NextCloud**

```bash
# eeeeet euuuh boom. Là non plus j'ai pas pondu ça, c'est la doc :
$ sudo dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp
```

🌞 **Récupérer NextCloud**

- créez le dossier `/var/www/tp2_nextcloud/`
  - ce sera notre _racine web_ (ou _webroot_)
  - l'endroit où le site est stocké quoi, on y trouvera un `index.html` et un tas d'autres marde, tout ce qui constitue NextClo :D
- récupérer le fichier suivant avec une commande `curl` ou `wget` : https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip
- extrayez tout son contenu dans le dossier `/var/www/tp2_nextcloud/` en utilisant la commande `unzip`
  - installez la commande `unzip` si nécessaire
  - vous pouvez extraire puis déplacer ensuite, vous prenez pas la tête
  - contrôlez que le fichier `/var/www/tp2_nextcloud/index.html` existe pour vérifier que tout est en place
- assurez-vous que le dossier `/var/www/tp2_nextcloud/` et tout son contenu appartient à l'utilisateur qui exécute le service Apache

> A chaque fois que vous faites ce genre de trucs, assurez-vous que c'est bien ok. Par exemple, vérifiez avec un `ls -al` que tout appartient bien à l'utilisateur qui exécute Apache.

🌞 **Adapter la configuration d'Apache**

- regardez la dernière ligne du fichier de conf d'Apache pour constater qu'il existe une ligne qui inclut d'autres fichiers de conf
- créez en conséquence un fichier de configuration qui porte un nom clair et qui contient la configuration suivante :

```apache
<VirtualHost *:80>
  # on indique le chemin de notre webroot
  DocumentRoot /var/www/tp2_nextcloud/
  # on précise le nom que saisissent les clients pour accéder au service
  ServerName  web.tp2.linux

  # on définit des règles d'accès sur notre webroot
  <Directory /var/www/tp2_nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
```

🌞 **Redémarrer le service Apache** pour qu'il prenne en compte le nouveau fichier de conf

### C. Finaliser l'installation de NextCloud

➜ **Sur votre PC**

- modifiez votre fichier `hosts` (oui, celui de votre PC, de votre hôte)
  - pour pouvoir joindre l'IP de la VM en utilisant le nom `web.tp2.linux`
- avec un navigateur, visitez NextCloud à l'URL `http://web.tp2.linux`
  - c'est possible grâce à la modification de votre fichier `hosts`
- on va vous demander un utilisateur et un mot de passe pour créer un compte admin
  - ne saisissez rien pour le moment
- cliquez sur "Storage & Database" juste en dessous
  - choisissez "MySQL/MariaDB"
  - saisissez les informations pour que NextCloud puisse se connecter avec votre base
- saisissez l'identifiant et le mot de passe admin que vous voulez, et validez l'installation

🌴 **C'est chez vous ici**, baladez vous un peu sur l'interface de NextCloud, faites le tour du propriétaire :)

🌞 **Exploration de la base de données**

- connectez vous en ligne de commande à la base de données après l'installation terminée
- déterminer combien de tables ont été crées par NextCloud lors de la finalisation de l'installation
  - **_bonus points_** si la réponse à cette question est automatiquement donnée par une requête SQL
