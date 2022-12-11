# Installation de la DB Mysql

La DB accessible via l'ip de la machine sur le port 3306.
Même principe que pour le forum on peut modifier les variables concernées dans le Docker-compose au besoin.
[Le docker-compose](./docker-compose.yml)

```
MYSQL_ROOT_PASSWORD: safeenoughaswell     # Spécifiez le mot de passe pour se connecter en root
MYSQL_DATABASE: forum                 # Spécifiez le nom de la base de données
MYSQL_USER: forum                     # Spécifiez le nom du User qui sera crée
MYSQL_PASSWORD: chingchongbingbong    # Spécifiez le mot de passe de celui-ci
```

_Note : Si vous les modifiez elles seront également à modifier dans le [DockerFile](../forum/Dockerfile) de la WebApp._

> Ports autorisés :

Rocky Linux

```
sudo firewall-cmd --add-port 3306/tcp --permanent
sudo firewall-cmd --reload
```

> Lancement du Docker :

```
cd db
docker compose up -d
```
