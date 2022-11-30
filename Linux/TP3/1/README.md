# Module 1 : Reverse Proxy

Un reverse proxy est donc une machine que l'on place devant un autre service afin d'accueillir les clients et servir d'intermédiaire entre le client et le service.

L'utilisation d'un reverse proxy peut apporter de nombreux bénéfices :

- décharger le service HTTP de devoir effectuer le chiffrement HTTPS (coûteux en performances)
- répartir la charge entre plusieurs services
- effectuer de la mise en cache
- fournir un rempart solide entre un hacker potentiel et le service et les données importantes
- servir de point d'entrée unique pour accéder à plusieurs services web

## Sommaire

- [Module 1 : Reverse Proxy](#module-1--reverse-proxy)
  - [Sommaire](#sommaire)
- [I. Intro](#i-intro)
- [II. Setup](#ii-setup)
- [III. HTTPS](#iii-https)

# I. Intro

# II. Setup

🖥️ **VM `proxy.tp3.linux`**

**N'oubliez pas de dérouler la [📝**checklist**📝](#checklist).**

➜ **On utilisera NGINX comme reverse proxy**

```
[gene@proxy ~]$ systemctl is-active nginx && systemctl is-enabled nginx
active
enabled
[gene@proxy ~]$ sudo ss -alntp
State    Recv-Q   Send-Q     Local Address:Port       Peer Address:Port   Process
LISTEN   0        511              0.0.0.0:80              0.0.0.0:*       users:(("nginx",pid=1779,fd=6),("nginx",pid=1778,fd=6))
[gene@proxy ~]$ ps -ef | grep nginx
nginx       1779    1778  0 16:22 ?        00:00:00 nginx: worker process
```

➜ **Configurer NGINX**

```
[gene@proxy ~]$ cat /etc/nginx/default.d/proxy.conf
server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;
    # Port d'écoute de NGINX
    listen 80;
    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        # On définit la cible du proxying
        proxy_pass http://10.102.1.11:80;
    }
    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }
    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}
```

```
[gene@web ~]$ sudo cat /var/www/tp2_nextcloud/config/config.php
<?php
$CONFIG = array (
  'instanceid' => 'ocx491prex4b',
  'passwordsalt' => '/nWR6YnkfJBp97X+E+Ckr2XSNI2dxG',
  'secret' => 'awTDjfZhZMsmCWC7cvPLS8dHGc9A0PBWSSV4+swIgn9ati8U',
  'trusted_domains' =>
  array (
    0 => 'web.tp2.linux',
    1 => '10.102.1.13',
  ),
  'datadirectory' => '/var/www/tp2_nextcloud/data',
  'dbtype' => 'mysql',
  'version' => '25.0.0.15',
  'overwrite.cli.url' => 'http://web.tp2.linux',
  'dbname' => 'nextcloud',
  'dbhost' => '10.102.1.12:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => 'azerty',
  'installed' => true,
);
```

➜ **Modifier votre fichier `hosts` de VOTRE PC**

```
PS C:\WINDOWS\system32\drivers\etc> cat .\hosts
# Copyright (c) 1993-2009 Microsoft Corp.
[...]
# localhost name resolution is handled within DNS itself.
#       127.0.0.1       localhost
#       ::1             localhost
10.102.1.13 web.tp2.linux
```

✨ **Bonus** : rendre le serveur `web.tp2.linux` injoignable sauf depuis l'IP du reverse proxy. En effet, les clients ne doivent pas joindre en direct le serveur web : notre reverse proxy est là pour servir de serveur frontal.

_Flemme_

# III. HTTPS

Le but de cette section est de permettre une connexion chiffrée lorsqu'un client se connecte. Avoir le ptit HTTPS :)

Le principe :

- on génère une paire de clés sur le serveur `proxy.tp3.linux`

  - une des deux clés sera la clé privée : elle restera sur le serveur et ne bougera jamais

  ```
  [gene@proxy ~] openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
  [gene@proxy ~]$ ls /etc/pki/tls/private/
  web.tp2.linux.key
  [gene@proxy ~]$ ls /etc/pki/tls/certs/
  ca-bundle.crt  ca-bundle.trust.crt  web.tp2.linux.crt
  ```

  ```
  [gene@proxy ~]$ sudo cat /etc/nginx/conf.d/proxy.conf
  server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;
    # Port d'écoute de NGINX
    listen 443 ssl;
    ssl_certificate "/etc/pki/tls/certs/web.tp2.linux.crt";
    ssl_certificate_key "/etc/pki/tls/private/web.tp2.linux.key";
    [...]
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
