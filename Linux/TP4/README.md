# TP4 : Conteneurs

Dans ce TP on va aborder plusieurs points autour de la conteneurisation :

- Docker et son empreinte sur le système
- Manipulation d'images
- `docker-compose`

# Sommaire

- [TP4 : Conteneurs](#tp4--conteneurs)
- [Sommaire](#sommaire)
- [0. Prérequis](#0-prérequis)
  - [Checklist](#checklist)
- [I. Docker](#i-docker)
  - [1. Install](#1-install)
  - [2. Vérifier l'install](#2-vérifier-linstall)
  - [3. Lancement de conteneurs](#3-lancement-de-conteneurs)
- [II. Images](#ii-images)
- [III. `docker-compose`](#iii-docker-compose)
  - [1. Intro](#1-intro)
  - [2. Make your own meow](#2-make-your-own-meow)

# 0. Prérequis

➜ Machines Rocky Linux

➜ Un unique host-only côté VBox, ça suffira. **L'adresse du réseau host-only sera `10.104.1.0/24`.**

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

# I. Docker

🖥️ Machine **docker1.tp4.linux**

## 1. Install

🌞 **Installer Docker sur la machine**

```
[gene@docker1 ~]$ sudo dnf install -y dnf-utils
[...]
Installed:
  yum-utils-4.0.24-4.el9_0.noarch
Complete!
[gene@docker1 ~]$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
[gene@docker1 ~]$ sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
[...]
Installed:
  checkpolicy-3.3-1.el9.x86_64                                          [...]
  tar-2:1.34-3.el9.x86_64
Complete!
[gene@docker1 ~]$ sudo systemctl start docker
[sudo] password for leo:
[gene@docker1 ~]$ sudo systemctl is-active docker
active
[gene@docker1 ~]$ sudo usermod -aG docker $(whoami)
```

🌞 **Utiliser la commande `docker run`**

```
[gene@docker1 ~]$ docker run --name nginx -d -v /home/gene/html:/var/www/tp4 -v /home/gene/nginx/nginx.conf:/etc/nginx/conf.d/better.conf -p 6666:66 --cpus 0.5 -h nginx -m 7000000 nginx
05cdc9648d359054d7106e4d806d06d1de764031ee37cefc770da45da733637f
[gene@docker1 ~]$ curl 172.17.0.2:66
<!doctype html>
<html>
  <head>
    <title>TP4, from Gene hihi</title>
  </head>
  <body>
    <p>This is an example paragraph. Anything in the <strong>body</strong> tag will appear on the page, just like this <strong>p</strong> tag and its contents.</p>
  </body>
</html>
```

# II. Images

La construction d'image avec Docker est basée sur l'utilisation de fichiers `Dockerfile`.

L'idée est la suivante :

- vous créez un dossier de travail
- vous vous déplacez dans ce dossier de travail
- vous créez un fichier `Dockerfile`
  - il contient les instructions pour construire une image
  - `FROM` : indique l'image de base
  - `RUN` : indique des opérations à effectuer dans l'image de base
- vous exécutez une commande `docker build . -t <IMAGE_NAME>`
- une image est produite, visible avec la commande `docker images`

## Exemple de Dockerfile et utilisation

Exemple d'un Dockerfile qui :

- se base sur une image ubuntu
- la met à jour
- installe nginx

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx
```

Une fois ce fichier créé, on peut :

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx

$ docker images

$ docker run -p 8888:80 my_own_nginx nginx -g "daemon off;"

$ curl localhost:8888
$ curl <IP_VM>:8888
```

> La commande `nginx -g "daemon off;"` permet de lancer NGINX au premier-plan, et ainsi demande à notre conteneur d'exécuter le programme NGINX à son lancement.

Plutôt que de préciser à la main à chaque `docker run` quelle commande doit lancer le conteneur (notre `nginx -g "daemon off;"` en fin de ligne ici), on peut, au moment du `build` de l'image, choisir d'indiquer que chaque conteneur lancé à partir de cette image lancera une commande donneé.

Il faut, pour cela, modifier le Dockerfile :

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
```

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx

$ docker images

$ docker run -p 8888:80 my_own_nginx

$ curl localhost:8888
$ curl <IP_VM>:8888
```

![Waiting for Docker](./pics/waiting_for_docker.jpg)

## 2. Construisez votre propre Dockerfile

🌞 **Construire votre propre image**

```
[gene@docker1 work]$ docker build . -t my_own_nginx
[gene@docker1 work]$ docker run -d --name test -p 6666:80 my_own_nginx
```

📁 [Dockerfile](./docker/Dockerfile)

# III. `docker-compose`

🌞 **Conteneurisez votre application**

```
[gene@docker1 ~]$ mkdir app && cd app
[gene@docker1 app]$ git clone https://github.com/raptigene/goforum
[gene@docker1 app]$ ls
docker-compose.yml  Dockerfile  forum
[gene@docker1 app]$ docker build . -t forum
[gene@docker1 app]$ docker compose up
[+] Running 1/0
 ⠿ Container go-forum-1  Created                                                                                                0.1s
Attaching to go-forum-1
go-forum-1  | Listening at http://:8080
```

📁[app/Dockerfile](./app/Dockerfile)

📁[app/docker-compose.yml](./app/docker-compose.yml)
