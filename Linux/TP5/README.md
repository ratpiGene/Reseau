# TP5 : Mise en place de ~~Nextcloud~~ service :)

# Service :

Le bon YForum étant donné qu'il est fait maison ça reste plus simple à adapter qu'un projet open source.
Cela comprend :

- Un app Web en golang (un peu de java aussi)
- Une base de données MySQL
- Un double reverse proxy nginx (en vue d'équilibrer le trafic mais j'ai pas fini de setup l'ip virtuelle par dessus)

Tout a été Dockerisé, il est donc possible de le déployer facilement néanmoins il faut donc installer Docker.

**Install Docker & Docker compose :**

```
sudo dnf update -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $(whoami)

```

# Installation :

> **1 :** YForum
> [Installation du YForum](./forum/README.md)

> **2 :** Base de données
> [Installation de la db](./db/README.md)

> **3 :** Reverse Proxy
> [Installation du reverse proxy](./proxy/README.md)
