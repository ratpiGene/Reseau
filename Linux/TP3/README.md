# TP3 : Amélioration de la solution NextCloud

Ce TP se présente sous forme modulaire : il est en plusieurs parties.  
Vous êtes libres d'attaquer les parties qui vous attirent le plus, et il n'est pas attendu de la part de tout le monde de poncer l'intégralité du contenu.

Les différents modules de ce TP s'organisent tous autour des mêmes objectifs : mieux maîtriser l'installation actuelle de NextCloud, augmenter son niveau de qualité et de sécurité, et aller vers des techniques modernes d'administration.

Pour y voir plus clair, j'ai découpé le TP en plusieurs fichiers Markdown, chacun s'attardant sur un sujet donné.

La suite du document est un index des différentes parties du TP.

Pour ce qui est du compte-rendu, j'attendrai que vous me remettez une suite d'instructions pour réaliser les modules que vous choisissez. Un peu comme un petit article/tuto qui explique comment monter le truc. Pas de blabla, les commandes suffisent comme d'habitude.

A chaque fois que vous mettez en place un truc, **vous devez tester que ça fonctionne**.

## Sommaire

- [TP3 : Amélioration de la solution NextCloud](#tp3--amélioration-de-la-solution-nextcloud)
  - [Sommaire](#sommaire)
  - [Stack Web](#stack-web)
    - [Module 1 Reverse Proxy](#module-1-reverse-proxy)
  - [Base de Données](#base-de-données)
    - [Module 2 Réplication de base de données](#module-2-réplication-de-base-de-données)
    - [Module 3 Sauvegarde de base de données](#module-3-sauvegarde-de-base-de-données)
  - [Pérennité de la solution](#pérennité-de-la-solution)
    - [Module 4 Sauvegarde du système de fichiers](#module-4-sauvegarde-du-système-de-fichiers)
    - [Module 5 Monitoring](#module-5-monitoring)
  - [Automatisation](#automatisation)
    - [Module 6 Automatiser le déploiement](#module-6-automatiser-le-déploiement)
    - [Module 7 Fail2ban](#module-7-fail2ban)

## Stack Web

### [Module 1 Reverse Proxy](./1/README.md)

Temps estimé : ⌛⌛

Le but de ce module sera de mettre en place un Reverse Proxy devant l'application NextCloud afin d'accueillir les clients.

Un reverse proxy est un serveur qui sert d'intermédiaire entre une application serveur et les clients, que l'administrateur met en place afin de bénéficier de certains avantages.

Dans notre cas : le reverse proxy se chargera de chiffrer les données lorsqu'un client accède au site (mise en place de HTTPS).

## Base de Données

### [Module 2 Réplication de base de données](./2/README.md)

Temps estimé : ⌛

Une base de données c'est bien, deux c'est mieux.

Un applicatif comme le serveur Web NextCloud qui tombe (panne, hack, etc.), ou un serveur de jeu, ou peu importe, la plupart du temps, on s'en "fout" un peu : on le remonte juste.

La base de données, c'est pas pareil. Les données qu'elle contient sont précieuses car uniques : ce sont les données que nous avons créé pour qu'une application vive dans un contexte donné.

C'est donc de façon assez récurrente un des premiers applicatifs où on va mettre en place de la haute-disponibilité car on peut rarement se permettre de perdre un tel service.

Le but de cette partie est donc de monter un deuxième serveur de base de données, qui sera une copie du premier en temps réel. Il n'accueillera pas les requêtes des clients, mais est en mesure de prendre le relais si le premier serveur tombe.

### [Module 3 Sauvegarde de base de données](./3/README.md)

Temps estimé : ⌛⌛

Pour ce module, quelque chose à base de scripting. Il faudra réaliser un script `bash` simple qui effectue un _dump_ de la base de données NextCloud.

Un _dump_ c'est le fait de transformer quelque chose de dynamique (comme une base de données) en un fichier statique, à un instant T. Ainsi, on parle ici de sauvegarder la base de données à un instant T, afin de conserver les données sur le long terme.

De toute évidence, grâce à une telle sauvegarde, il est possible ultérieurement de restaurer les données de la sauvegarde dans une base de données.

## Pérennité de la solution

### [Module 4 Sauvegarde du système de fichiers](./4/README.md)

Temps estimé : ⌛⌛⌛

Ici, il s'agit de sauvegarder les fichiers importants se trouvant sur le disque dur de la machine NextCloud.

On va donc mettre en place un _serveur de sauvegarde_ : un serveur qui n'a qu'un seul but qui est de stocker des fichiers archivés, les sauvegardes de nos autres machines.

Dans notre cas, il stockera les fichiers de conf qu'on a écrit, certains fichiers NextCloud, ainsi que les dumps de la base de données si vous avez réalisé le module 4.

### [Module 5 Monitoring]()

Temps estimé : ⌛

Une p'tite interface avec des graphes partout ça fait toujours plaisir. Surtout des alertes automatiques dans le cas où ça commence à chier dans la colle.

Dans ce module on met donc en place une solution de monitoring. Pas une plateforme complète à grande échelle, mais de quoi avoir une interface à consulter, des sondes customisées, et de quoi recevoir des alertes automatiques.

## Automatisation

### [Module 6 Automatiser le déploiement]()

Temps estimé : de ⌛ à ⌛⌛⌛

Un deuxième sujet de scripting dans lequel le but est d'automatiser le déploiement de NextCloud. L'idée est simple : un script `bash` qui met en place toute la conf que vous avec mis en place à la main au TP2.

Résultat : un script `bash` qu'on lance, on part prendre un café, et quand on revient y'a NextCloud installé et setup.

Il est évidemment possible de coupler ce module aux autres, et ainsi déployer d'autres trucs.

### [Module 7 Fail2ban]()

Temps estimé : ⌛

Fail2Ban est un utilitaire qui permet de limiter l'impact des tentatives de bruteforce.

Là c'est une VM donc on s'en fiche, mais dans un cas réel avec un serveur hébergé en ligne, c'est plutôt impératif. En effet les attaques de masse sont nombreuses sur internet.

Dès sa mise en ligne, un serveur se fait attaquer, et ce, de plus en plus souvent au fur et à mesure que l'adresse du serveur devient connue sur le réseau.

Fail2Ban est un outil qui va regarder les logs d'autres outils, en temps réel, et qui peut agir si certains patterns sont repérés.

Ainsi il est aisé de repérer un bruteforce du serveur SSH par exemple, en regardant les logs du serveur SSH à la recherche de tentatives de connexion répétées et échouées en un court lap de temps.

Fail2Ban, s'il repère un certain pattern répété X fois en moins d'un certain lap de temps va alors pouvoir déclencher une action automatique. Généralement un ban de l'IP qui effectue les requêtes, à l'aide du firewall de la machine.
