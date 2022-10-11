# TP3 : On va router des trucs

Au menu de ce TP, on va revoir un peu ARP et IP histoire de **se mettre en jambes dans un environnement avec des VMs**.

Puis on mettra en place **un routage simple, pour permettre à deux LANs de communiquer**.

## 0. Prérequis

## I. ARP

Première partie simple, on va avoir besoin de 2 VMs.

| Machine  | `10.3.1.0/24` |
| -------- | ------------- |
| `john`   | `10.3.1.11`   |
| `marcel` | `10.3.1.12`   |

```schema
   john               marcel
  ┌─────┐             ┌─────┐
  │     │    ┌───┐    │     │
  │     ├────┤ho1├────┤     │
  └─────┘    └───┘    └─────┘
```

> Référez-vous au [mémo Réseau Rocky](../../cours/memo/rocky_network.md) pour connaître les commandes nécessaire à la réalisation de cette partie.

### 1. Echange ARP

🌞**Générer des requêtes ARP**

```
[gene@john ~]$ ping -c 1 10.3.1.12
PING 10.3.1.12 (10.3.1.12) 56(84) bytes of data.
64 bytes from 10.3.1.12: icmp_seq=1 ttl=64 time=0.623 ms

--- 10.3.1.12 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.623/0.623/0.623/0.000 ms
[leo@john ~]$ ip neigh
10.0.2.2 dev enp0s3 lladdr 52:54:00:12:35:02 STALE
10.3.1.1 dev enp0s8 lladdr 0a:00:27:00:00:0b REACHABLE
10.3.1.12 dev enp0s8 lladdr 08:00:27:24:c8:63 DELAY
```

```
[gene@marcel ~]$ ip neigh
10.3.1.11 dev enp0s8 lladdr 08:00:27:43:e4:69 STALE
10.3.1.1 dev enp0s8 lladdr 0a:00:27:00:00:0b REACHABLE
10.0.2.2 dev enp0s3 lladdr 52:54:00:12:35:02 STALE
```

MAC John: `08:00:27:43:e4:69`

Mac Marcel: `08:00:27:24:c8:63`

- prouvez que l'info est correcte (que l'adresse MAC que vous voyez dans la table est bien celle de la machine correspondante)
  - une commande pour voir la MAC de `marcel` dans la table ARP de `john`
    ```
    [gene@john ~]$ ip neigh | grep 10.3.1.12
    10.3.1.12 dev enp0s8 lladdr 08:00:27:24:c8:63 STALE
    ```
  - et une commande pour afficher la MAC de `marcel`, depuis `marcel`
    ```
    [gene@marcel ~]$ ip add show enp0s8
    3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 08:00:27:24:c8:63 brd ff:ff:ff:ff:ff:ff
        inet 10.3.1.12/24 brd 10.3.1.255 scope global noprefixroute enp0s8
        valid_lft forever preferred_lft forever
        inet6 fe80::a00:27ff:fe24:c863/64 scope link
        valid_lft forever preferred_lft forever
    ```

### 2. Analyse de trames

🌞**Analyse de trames**

- utilisez la commande `tcpdump` pour réaliser une capture de trame
- videz vos tables ARP, sur les deux machines, puis effectuez un `ping`

  ```
  [gene@john ~]$ sudo ip neigh flush all
  [gene@john ~]$ sudo tcpdump -c 4 -i enp0s8 -w tp2_arp.pcapng arp
  dropped privs to tcpdump
  tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
  4 packets captured
  5 packets received by filter
  0 packets dropped by kernel
  ```

  ```
  [gene@marcel ~]$ sudo ip neigh flush all
  [gene@marcel ~]$ ping -c 1 10.3.1.11
  PING 10.3.1.11 (10.3.1.11) 56(84) bytes of data.
  64 bytes from 10.3.1.11: icmp_seq=1 ttl=64 time=0.538 ms

  --- 10.3.1.11 ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 0.538/0.538/0.538/0.000 ms
  ```

> 🦈 **[Capture réseau `tp2_arp.pcapng` qui contient un ARP request et un ARP reply](./pcap/tp2_arp.pcapng)**

## II. Routage

Vous aurez besoin de 3 VMs pour cette partie. **Réutilisez les deux VMs précédentes.**

| Machine  | `10.3.1.0/24` | `10.3.2.0/24` |
| -------- | ------------- | ------------- |
| `router` | `10.3.1.254`  | `10.3.2.254`  |
| `john`   | `10.3.1.11`   | no            |
| `marcel` | no            | `10.3.2.12`   |

> Je les appelés `marcel` et `john` PASKON EN A MAR des noms nuls en réseau 🌻

```schema
   john                router              marcel
  ┌─────┐             ┌─────┐             ┌─────┐
  │     │    ┌───┐    │     │    ┌───┐    │     │
  │     ├────┤ho1├────┤     ├────┤ho2├────┤     │
  └─────┘    └───┘    └─────┘    └───┘    └─────┘
```

### 1. Mise en place du routage

🌞**Activer le routage sur le noeud `router`**

```
[gene@router ~]$ sudo firewall-cmd --get-active-zone
public
  interfaces: enp0s3 enp0s8 enp0s9
[gene@router ~]$ sudo firewall-cmd --add-masquerade --zone=public --permanent
success
```

🌞**Ajouter les routes statiques nécessaires pour que `john` et `marcel` puissent se `ping`**

```
[gene@john ~]$ sudo ip route add 10.3.2.0/24 via 10.3.1.254 dev enp0s8
```

```
[gene@marcel ~]$ sudo ip route add 10.3.1.0/24 via 10.3.2.254 dev enp0s8
```

- une fois les routes en place, vérifiez avec un `ping` que les deux machines peuvent se joindre

  ```
  [gene@john ~]$ ping -c 1 10.3.2.12
  PING 10.3.2.12 (10.3.2.12) 56(84) bytes of data.
  64 bytes from 10.3.2.12: icmp_seq=1 ttl=63 time=0.699 ms

  --- 10.3.2.12 ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 0.699/0.699/0.699/0.000 ms
  ```

### 2. Analyse de trames

🌞**Analyse des échanges ARP**

- videz les tables ARP des trois noeuds
- effectuez un `ping` de `john` vers `marcel`
- regardez les tables ARP des trois noeuds
  ```
  [gene@john ~]$ sudo ip neigh flush all
  [gene@john ~]$ ping -c 1 10.3.2.12
  PING 10.3.2.12 (10.3.2.12) 56(84) bytes of data.
  64 bytes from 10.3.2.12: icmp_seq=1 ttl=63 time=1.23 ms
  [...]
  [gene@john ~]$ ip neigh show
  10.3.1.254 dev enp0s8 lladdr 08:00:27:7c:49:7c REACHABLE
  10.3.1.1 dev enp0s8 lladdr 0a:00:27:00:00:0b REACHABLE
  ```
  ```
  [gene@router ~]$ sudo ip neigh flush all
  [gene@router ~]$ ip neigh show
  10.3.2.12 dev enp0s9 lladdr 08:00:27:24:c8:63 REACHABLE
  10.3.1.11 dev enp0s8 lladdr 08:00:27:43:e4:69 REACHABLE
  10.3.1.1 dev enp0s8 lladdr 0a:00:27:00:00:0b REACHABLE
  ```
  ```
  [gene@marcel ~]$ sudo ip neigh flush all
  [gene@marcel ~]$ ip neigh show
  10.3.2.254 dev enp0s8 lladdr 08:00:27:2c:d8:5b REACHABLE
  10.3.2.1 dev enp0s8 lladdr 0a:00:27:00:00:3b REACHABLE
  ```
- essayez de déduire un peu les échanges ARP qui ont eu lieu
  - Tout d'abord, un échange ARP entre `John` et `Router` puis un échange ARP entre `Router` et `Marcel`.
- répétez l'opération précédente (vider les tables, puis `ping`), en lançant `tcpdump` sur `marcel`
- **écrivez, dans l'ordre, les échanges ARP qui ont eu lieu, puis le ping et le pong, je veux TOUTES les trames** utiles pour l'échange

  | ordre | type trame  | IP source  | MAC source                   | IP destination | MAC destination              |
  | ----- | ----------- | ---------- | ---------------------------- | -------------- | ---------------------------- |
  | 1     | Requête ARP | x          | `router` `08:00:27:2c:d8:5b` | x              | Broadcast `FF:FF:FF:FF:FF`   |
  | 2     | Réponse ARP | x          | `marcel` `08:00:27:24:c8:63` | x              | `router` `08:00:27:2c:d8:5b` |
  | 3     | Ping        | 10.3.2.254 | `router` `08:00:27:2c:d8:5b` | 10.3.2.12      | `marcel` `08:00:27:24:c8:63` |
  | 4     | Pong        | 10.3.2.12  | `marcel` `08:00:27:24:c8:63` | 10.3.2.254     | `router` `08:00:27:2c:d8:5b` |
  | 5     | Requête ARP | x          | `marcel` `08:00:27:24:c8:63` | x              | Broadcast `FF:FF:FF:FF:FF`   |
  | 6     | Réponse ARP | x          | `router` `08:00:27:2c:d8:5b` | x              | `router` `08:00:27:24:c8:63` |

> 🦈 **[Capture réseau `tp2_routage_marcel.pcapng`](./pcap/tp2_arp.pcapng)**

### 3. Accès internet

🌞**Donnez un accès internet à vos machines**

- ajoutez une carte NAT en 3ème inteface sur le `router` pour qu'il ait un accès internet
- ajoutez une route par défaut à `john` et `marcel`
  - vérifiez que vous avez accès internet avec un `ping`
  - le `ping` doit être vers une IP, PAS un nom de domaine
- donnez leur aussi l'adresse d'un serveur DNS qu'ils peuvent utiliser
  - vérifiez que vous avez une résolution de noms qui fonctionne avec `dig`
  - puis avec un `ping` vers un nom de domaine

🌞**Analyse de trames**

- effectuez un `ping 8.8.8.8` depuis `john`
- capturez le ping depuis `john` avec `tcpdump`
- analysez un ping aller et le retour qui correspond et mettez dans un tableau :

| ordre | type trame | IP source          | MAC source              | IP destination | MAC destination |     |
| ----- | ---------- | ------------------ | ----------------------- | -------------- | --------------- | --- |
| 1     | ping       | `john` `10.3.1.12` | `john` `AA:BB:CC:DD:EE` | `8.8.8.8`      | ?               |     |
| 2     | pong       | ...                | ...                     | ...            | ...             | ... |

🦈 **Capture réseau `tp2_routage_internet.pcapng`**

## III. DHCP

On reprend la config précédente, et on ajoutera à la fin de cette partie une 4ème machine pour effectuer des tests.

| Machine  | `10.3.1.0/24`              | `10.3.2.0/24` |
| -------- | -------------------------- | ------------- |
| `router` | `10.3.1.254`               | `10.3.2.254`  |
| `john`   | `10.3.1.11`                | no            |
| `bob`    | oui mais pas d'IP statique | no            |
| `marcel` | no                         | `10.3.2.12`   |

```schema
   john               router              marcel
  ┌─────┐             ┌─────┐             ┌─────┐
  │     │    ┌───┐    │     │    ┌───┐    │     │
  │     ├────┤ho1├────┤     ├────┤ho2├────┤     │
  └─────┘    └─┬─┘    └─────┘    └───┘    └─────┘
   john        │
  ┌─────┐      │
  │     │      │
  │     ├──────┘
  └─────┘
```

### 1. Mise en place du serveur DHCP

🌞**Sur la machine `john`, vous installerez et configurerez un serveur DHCP** (go Google "rocky linux dhcp server").

- installation du serveur sur `john`
- créer une machine `bob`
- faites lui récupérer une IP en DHCP à l'aide de votre serveur

> Il est possible d'utilise la commande `dhclient` pour forcer à la main, depuis la ligne de commande, la demande d'une IP en DHCP, ou renouveler complètement l'échange DHCP (voir `dhclient -h` puis call me et/ou Google si besoin d'aide).

🌞**Améliorer la configuration du DHCP**

- ajoutez de la configuration à votre DHCP pour qu'il donne aux clients, en plus de leur IP :
  - une route par défaut
  - un serveur DNS à utiliser
- récupérez de nouveau une IP en DHCP sur `marcel` pour tester :
  - `marcel` doit avoir une IP
    - vérifier avec une commande qu'il a récupéré son IP
    - vérifier qu'il peut `ping` sa passerelle
  - il doit avoir une route par défaut
    - vérifier la présence de la route avec une commande
    - vérifier que la route fonctionne avec un `ping` vers une IP
  - il doit connaître l'adresse d'un serveur DNS pour avoir de la résolution de noms
    - vérifier avec la commande `dig` que ça fonctionne
    - vérifier un `ping` vers un nom de domaine

### 2. Analyse de trames

🌞**Analyse de trames**

- lancer une capture à l'aide de `tcpdump` afin de capturer un échange DHCP
- demander une nouvelle IP afin de générer un échange DHCP
- exportez le fichier `.pcapng`

🦈 **Capture réseau `tp2_dhcp.pcapng`**

![wewechatquidance](./pics/meow.gif)
