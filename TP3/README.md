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
[gene@john ~]$ ip neigh
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
  ```
  [gene@router ~]$ ip a
  [...]
  2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 08:00:27:a8:c1:32 brd ff:ff:ff:ff:ff:ff
      inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
      valid_lft 83719sec preferred_lft 83719sec
      inet6 fe80::a00:27ff:fea8:c132/64 scope link noprefixroute
      valid_lft forever preferred_lft forever
  ```
- ajoutez une route par défaut à `john` et `marcel`

  - vérifiez que vous avez accès internet avec un `ping`
  - le `ping` doit être vers une IP, PAS un nom de domaine

    ```
    [gene@john ~]$ sudo ip route add default via 10.3.1.254 dev enp0s8
    [gene@john ~]$ ping -c 1 1.1.1.1
    PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
    64 bytes from 1.1.1.1: icmp_seq=1 ttl=54 time=16.2 ms

    --- 1.1.1.1 ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 16.218/16.218/16.218/0.000 ms
    ```

    ```
    [gene@marcel ~]$ sudo ip route add default via 10.3.2.254 dev enp0s8
    [gene@marcel ~]$ ping -c 1 1.1.1.1
    PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
    64 bytes from 1.1.1.1: icmp_seq=1 ttl=54 time=16.2 ms

    --- 1.1.1.1 ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 16.167/16.167/16.167/0.000 ms
    ```

- donnez leur aussi l'adresse d'un serveur DNS qu'ils peuvent utiliser

  - vérifiez que vous avez une résolution de noms qui fonctionne avec `dig`
  - puis avec un `ping` vers un nom de domaine

    ```
    [gene@john ~]$ cat /etc/resolv.conf # Generated by NetworkManager
    search lan
    nameserver 8.8.8.8
    nameserver 8.8.4.4
    [gene@john ~]$ dig gitlab.com

        ; <<>> DiG 9.16.23-RH <<>> gitlab.com
        ;; global options: +cmd
        ;; Got answer:
        ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51269
        ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

        ;; OPT PSEUDOSECTION:
        ; EDNS: version: 0, flags:; udp: 512
        ;; QUESTION SECTION:
        ;gitlab.com.                    IN      A

        ;; ANSWER SECTION:
        gitlab.com.             300     IN      A       172.65.251.78

        ;; Query time: 44 msec
        ;; SERVER: 8.8.8.8#53(8.8.8.8)
        ;; WHEN: Mon Oct 03 16:08:44 CEST 2022
        ;; MSG SIZE  rcvd: 55
        [gene@john ~]$ ping -c 1 github.com
        PING github.com (140.82.121.3) 56(84) bytes of data.
        64 bytes from lb-140-82-121-3-fra.github.com (140.82.121.3): icmp_seq=1 ttl=52 time=26.4 ms

        --- github.com ping statistics ---
        1 packets transmitted, 1 received, 0% packet loss, time 0ms
        rtt min/avg/max/mdev = 26.406/26.406/26.406/0.000 ms
    ```

  🌞**Analyse de trames**

- effectuez un `ping 8.8.8.8` depuis `john`
- capturez le ping depuis `john` avec `tcpdump`

  ```
  [gene@john ~]$ sudo tcpdump -i enp0s8 -c 2 -w tp2_routage_internet.pcapng not port 22 &
  [1] 1454
  [gene@john ~]$ dropped privs to tcpdump
  tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
  ping -c 1 8.8.8.8
  PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
  64 bytes from 8.8.8.8: icmp_seq=1 ttl=113 time=16.2 ms

  --- 8.8.8.8 ping statistics ---
  1 packets transmitted, 1 received, 0% packet loss, time 0ms
  rtt min/avg/max/mdev = 16.215/16.215/16.215/0.000 ms
  [gene@john ~]$ 2 packets captured
  2 packets received by filter
  0 packets dropped by kerne
  ```

- analysez un ping aller et le retour qui correspond et mettez dans un tableau :

  | ordre | type trame | IP source          | MAC source                   | IP destination     | MAC destination              |
  | ----- | ---------- | ------------------ | ---------------------------- | ------------------ | ---------------------------- |
  | 1     | ping       | `john` `10.3.1.11` | `john` `08:00:27:43:e4:69`   | `8.8.8.8`          | `router` `08:00:27:7c:49:7c` |
  | 2     | pong       | `8.8.8.8`          | `router` `08:00:27:7c:49:7c` | `john` `10.3.1.11` | `john` `08:00:27:43:e4:69`   |

> 🦈 **[Capture réseau `tp2_routage_internet.pcapng`](./pcap/tp2_routage_internet.pcapng)**

## III. DHCP

### 1. Mise en place du serveur DHCP

🌞**Sur la machine `john`, vous installerez et configurerez un serveur DHCP** (go Google "rocky linux dhcp server").

- installation du serveur sur `john`

  ```
  [gene@john ~]$ sudo dnf install -y dhcp-server
  [...]
  Complete!
  [gene@john ~]$ sudo cat /etc/dhcp/dhcpd.conf
  #
  # DHCP Server Configuration file.
  #   see /usr/share/doc/dhcp-server/dhcpd.conf.example
  #   see dhcpd.conf(5) man page
  #

  default-lease-time 900;
  max-lease-time 10800;
  ddns-update-style none;
  authoritative;
  subnet 10.3.1.0 netmask 255.255.255.0 {
  range 10.3.1.1 10.3.1.253;
  option routers 10.3.1.254;
  option subnet-mask 255.255.255.0;
  option domain-name-servers 8.8.8.8;

  }
  [gene@john ~]$ sudo systemctl enable dhcpd
  Created symlink /etc/systemd/system/multi-user.target.wants/dhcpd.service → /usr/lib/systemd/system/dhcpd.service.
  ```

- créer une machine `bob`
- faites lui récupérer une IP en DHCP à l'aide de votre serveur

```
    [gene@bob ~]$ sudo cat /etc/sysconfig/network-scripts/ifcfg-enp0s8
    NAME=enp0s8
    DEVICE=enp0s8
    BOOTPROTO=dhcp
    ONBOOT=yes
    [gene@bob ~]$ ip a
    [...]
    2: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 08:00:27:af:5d:de brd ff:ff:ff:ff:ff:ff
        inet 10.3.1.2/24 brd 10.3.1.255 scope global dynamic noprefixroute enp0s8
        valid_lft 685sec preferred_lft 685sec
        inet6 fe80::a00:27ff:feaf:5dde/64 scope link noprefixroute
        valid_lft forever preferred_lft forever
```

🌞**Améliorer la configuration du DHCP**

- ajoutez de la configuration à votre DHCP pour qu'il donne aux clients, en plus de leur IP :

  - une route par défaut
  - un serveur DNS à utiliser

    ```
    [gene@john ~]$ sudo cat /etc/dhcp/dhcpd.conf
        #
        # DHCP Server Configuration file.
        #   see /usr/share/doc/dhcp-server/dhcpd.conf.example
        #   see dhcpd.conf(5) man page
        #

        default-lease-time 900;
        max-lease-time 10800;
        ddns-update-style none;
        authoritative;
        subnet 10.3.1.0 netmask 255.255.255.0 {
        range 10.3.1.1 10.3.1.253;
        option routers 10.3.1.254;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 8.8.8.8;

        }
    ```

- récupérez de nouveau une IP en DHCP sur `marcel` pour tester :

  - `marcel` doit avoir une IP
    - vérifier avec une commande qu'il a récupéré son IP
    - vérifier qu'il peut `ping` sa passerelle
  - il doit avoir une route par défaut

    - vérifier la présence de la route avec une commande
    - vérifier que la route fonctionne avec un `ping` vers une IP

      ```
      [gene@bob ~]$ ip route
      default via 10.3.1.254 dev enp0s8
      default via 10.3.1.254 dev enp0s8 proto dhcp src 10.3.1.2 metric 100
      10.3.1.0/24 dev enp0s8 proto kernel scope link src 10.3.1.2 metric 100
      [gene@bob ~]$ ping -c 1 1.1.1.1
      PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
      64 bytes from 1.1.1.1: icmp_seq=1 ttl=54 time=17.1 ms

      --- 1.1.1.1 ping statistics ---
      1 packets transmitted, 1 received, 0% packet loss, time 0ms
      rtt min/avg/max/mdev = 17.144/17.144/17.144/0.000 ms
      ```

- il doit connaître l'adresse d'un serveur DNS pour avoir de la résolution de noms
- vérifier avec la commande `dig` que ça fonctionne
- vérifier un `ping` vers un nom de domaine

  ````
  [gene@bob ~]$ dig google.com

            ; <<>> DiG 9.16.23-RH <<>> google.com
            ;; global options: +cmd
            ;; Got answer:
            ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47033
            ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

            ;; OPT PSEUDOSECTION:
            ; EDNS: version: 0, flags:; udp: 512
            ;; QUESTION SECTION:
            ;google.com.                    IN      A

            ;; ANSWER SECTION:
            google.com.             300     IN      A       216.58.214.78

            ;; Query time: 22 msec
            ;; SERVER: 8.8.8.8#53(8.8.8.8)
            ;; WHEN: Mon Oct 03 17:28:05 CEST 2022
            ;; MSG SIZE  rcvd: 55

            [gene@bob ~]$ ping -c 1 ynov.com
            PING ynov.com (104.26.11.233) 56(84) bytes of data.
            64 bytes from 104.26.11.233 (104.26.11.233): icmp_seq=1 ttl=54 time=16.8 ms

            --- ynov.com ping statistics ---
            1 packets transmitted, 1 received, 0% packet loss, time 0ms
            rtt min/avg/max/mdev = 16.752/16.752/16.752/0.000 ms
            ```
  ````

### 2. Analyse de trames

🌞**Analyse de trames**

- lancer une capture à l'aide de `tcpdump` afin de capturer un échange DHCP
- demander une nouvelle IP afin de générer un échange DHCP

  ```
    [gene@bob ~]$ sudo dhclient -r
    Killed old client process
    [gene@bob ~]$ sudo tcpdump -i enp0s8 -c 6 -w tp2_dhcp.pcapng not port 22 &
    [1] 1794
    [gene@bob ~]$ dropped privs to tcpdump
    tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes

    [gene@bob ~]$ sudo dhclient
    6 packets captured
    6 packets received by filter
    0 packets dropped by kernel
    [1]+  Done                    sudo tcpdump -i enp0s8 -c 6 -w tp2_dhcp.pcapng not port 22
  ```

🦈 **[Capture réseau `tp2_dhcp.pcapng`](./pcap/tp2_dhcp.pcapng)**

![wewechatquidance](./pics/meow.gif)
