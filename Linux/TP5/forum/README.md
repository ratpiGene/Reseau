# Installation Forum

Basée sur du golang le service que nous installons a été réalisé dans le cadre d'un projet d'étude de 1er année.

> Les variables à modifier dans le Dockerfile pour se connecter à la DB sont :
> [Le DockerFile](./Dockerfile)

```
ENV USER_DB="forum"                   # Spécifier le nom du User accédant à la Database
ENV IP_DB="10.102.1.3"                # Spécifier l'Ip du serveur possèdant la Database
ENV PASSWORD_DB="safeenough"  # Spécifier le mot de passe de l'utilisateur
ENV NAME_DB="forum"                   # Spécifier le nom de la Database à utiliser
```

> Ports à autoriser :

Rocky Linux

```
sudo firewall-cmd --add-port 8080/tcp --permanent
sudo firewall-cmd --add-port 8081/tcp --permanent
sudo firewall-cmd --add-port 8082/tcp --permanent
sudo firewall-cmd --reload
```

> Construction de l'image et lancement du service :

```
sudo mkdir /srv/Avatar
cd forum/
docker build . -t forum
docker compose up -d
```
