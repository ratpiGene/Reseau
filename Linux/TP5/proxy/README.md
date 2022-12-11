# Installation Reverse Proxy nginx / HTTPS

[DockerFile](./Dockerfile) contient l'IP des 3 WebApp lancées.

Celui-ci va créer un certificat SSL ainsi que sa clé via Openssl, qui seront stockés respectivement dans `/etc/ssl/certs` et `/etc/ssl/private`

> Variables à modifier :

```
ENV WEB_IP1="10.102.1.2:8080"  # Spéficiez l'Ip de la docker 1
ENV WEB_IP2="10.102.1.2:8081"  # Spéficiez l'Ip de la docker 2
ENV WEB_IP3="10.102.1.2:8082"  # Spéficiez l'Ip de la docker 3
ENV SERVER_NAME="webapp.TP5"   # Spéficiez le nom de votre serveur
```

> Ports à autoriser :

Rocky Linux

```
sudo firewall-cmd --add-port 443/tcp --permanent
sudo firewall-cmd --add-port 80/tcp --permanent
sudo firewall-cmd --reload
```

> Construction de l'image et lancement du service :

```
cd /proxy
docker build . -t proxy
docker compose up -d
```
