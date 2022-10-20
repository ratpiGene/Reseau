# Sujet Réseau et Infra

On va utiliser GNS3 dans ce TP pour se rapprocher d'un cas réel. On va focus sur l'aspect routing/switching, avec du matériel Cisco. On va aussi mettre en place des VLANs.

# I. Dumb switch

## 1. Topologie 1

## 2. Adressage topologie 1

| Node  | IP            |
| ----- | ------------- |
| `pc1` | `10.1.1.1/24` |
| `pc2` | `10.1.1.2/24` |

## 3. Setup topologie 1

🌞 **Commençons simple**

```
PC2> show ip all
NAME   IP/MASK              GATEWAY           MAC                DNS
PC2    10.1.1.2/24          255.255.255.0     00:50:79:66:68:01
PC2> ping  10.1.1.1
84 bytes from 10.1.1.1 icmp_seq=1 ttl=64 time=0.131 ms
```

```
PC1> show ip all
NAME   IP/MASK              GATEWAY           MAC                DNS
PC1    10.1.1.1/24          255.255.255.0     00:50:79:66:68:00
PC1> ping  10.1.1.2
84 bytes from 10.1.1.2 icmp_seq=1 ttl=64 time=0.131 ms
```

# II. VLAN

**Le but dans cette partie va être de tester un peu les _VLANs_.**

On va rajouter **un troisième client** qui, bien que dans le même réseau, sera **isolé des autres grâce aux _VLANs_**.

**Les _VLANs_ sont une configuration à effectuer sur les _switches_.** C'est les _switches_ qui effectuent le blocage.

Le principe est simple :

- déclaration du VLAN sur tous les switches
  - un VLAN a forcément un ID (un entier)
  - bonne pratique, on lui met un nom
- sur chaque switch, on définit le VLAN associé à chaque port
  - genre "sur le port 35, c'est un client du VLAN 20 qui est branché"

## 1. Topologie 2

## 2. Adressage topologie 2

| Node  | IP            | VLAN |
| ----- | ------------- | ---- |
| `pc1` | `10.1.1.1/24` | 10   |
| `pc2` | `10.1.1.2/24` | 10   |
| `pc3` | `10.1.1.3/24` | 20   |

### 3. Setup topologie 2

🌞 **Adressage**

```
 PC3> ping 10.1.1.1 -c 1
 84 bytes from 10.1.1.1 icmp_seq=1 ttl=64 time=0.311 ms
 PC3> ping 10.1.1.2 -c 1
 84 bytes from 10.1.1.2 icmp_seq=1 ttl=64 time=0.640 ms
```

🌞 **Configuration des VLANs**

```
  sw1#show vlan br
  40   clients                           active    Et0/0, Et0/1
  50   admins                          active    Et0/2
```

🌞 **Vérif**

- `pc1` et `pc2` doivent toujours pouvoir se ping
- `pc3` ne ping plus personne

# III. Routing

Dans cette partie, on va donner un peu de sens aux VLANs :

- un pour les serveurs du réseau
  - on simulera ça avec un p'tit serveur web
- un pour les admins du réseau
- un pour les autres random clients du réseau

Cela dit, il faut que tout ce beau monde puisse se ping, au moins joindre le réseau des serveurs, pour accéder au super site-web.

**Bien que bloqué au niveau du switch à cause des VLANs, le trafic pourra passer d'un VLAN à l'autre grâce à un routeur.**

Il assurera son job de routeur traditionnel : router entre deux réseaux. Sauf qu'en plus, il gérera le changement de VLAN à la volée.

## 1. Topologie 3

## 2. Adressage topologie 3

Les réseaux et leurs VLANs associés :

| Réseau    | Adresse       | VLAN associé |
| --------- | ------------- | ------------ |
| `clients` | `10.1.1.0/24` | 11           |
| `admins`  | `10.2.2.0/24` | 12           |
| `servers` | `10.3.3.0/24` | 13           |

L'adresse des machines au sein de ces réseaux :

| Node               | `clients`       | `admins`        | `servers`       |
| ------------------ | --------------- | --------------- | --------------- |
| `pc1.clients.tp4`  | `10.1.1.1/24`   | x               | x               |
| `pc2.clients.tp4`  | `10.1.1.2/24`   | x               | x               |
| `adm1.admins.tp4`  | x               | `10.2.2.1/24`   | x               |
| `web1.servers.tp4` | x               | x               | `10.3.3.1/24`   |
| `r1`               | `10.1.1.254/24` | `10.2.2.254/24` | `10.3.3.254/24` |

## 3. Setup topologie 3

🖥️ VM `web1.servers.tp4`, déroulez la [Checklist VM Linux](#checklist-vm-linux) dessus

🌞 **Adressage**

- définissez les IPs statiques sur toutes les machines **sauf le _routeur_**

🌞 **Configuration des VLANs**

- référez-vous au [mémo Cisco](../../cours/memo/memo_cisco.md#8-vlan)
- déclaration des VLANs sur le switch `sw1`
- ajout des ports du switches dans le bon VLAN (voir [le tableau d'adressage de la topo 2 juste au dessus](#2-adressage-topologie-2))
- il faudra ajouter le port qui pointe vers le _routeur_ comme un _trunk_ : c'est un port entre deux équipements réseau (un _switch_ et un _routeur_)

---

➜ **Pour le _routeur_**

- référez-vous au [mémo Cisco](../../cours/memo/memo_cisco.md)
- ici, on va avoir besoin d'un truc très courant pour un _routeur_ : qu'il porte plusieurs IP sur une unique interface
  - avec Cisco, on crée des "sous-interfaces" sur une interface
  - et on attribue une IP à chacune de ces sous-interfaces
- en plus de ça, il faudra l'informer que, pour chaque interface, elle doit être dans un VLAN spécifique

Pour ce faire, un exemple. On attribue deux IPs `192.168.1.254/24` VLAN 10 et `192.168.2.254` VLAN 20 à un _routeur_. L'interface concernée sur le _routeur_ est `fastEthernet 0/0` :

```cisco
# conf t

(config)# interface fastEthernet 0/0.10
R1(config-subif)# encapsulation dot1Q 10
R1(config-subif)# ip addr 192.168.1.254 255.255.255.0
R1(config-subif)# exit

(config)# interface fastEthernet 0/0.20
R1(config-subif)# encapsulation dot1Q 20
R1(config-subif)# ip addr 192.168.2.254 255.255.255.0
R1(config-subif)# exit
```

🌞 **Config du _routeur_**

- attribuez ses IPs au _routeur_
  - 3 sous-interfaces, chacune avec son IP et un VLAN associé

🌞 **Vérif**

- tout le monde doit pouvoir ping le routeur sur l'IP qui est dans son réseau
- en ajoutant une route vers les réseaux, ils peuvent se ping entre eux
  - ajoutez une route par défaut sur les VPCS
  - ajoutez une route par défaut sur la machine virtuelle
  - testez des `ping` entre les réseaux

# IV. NAT

On va ajouter une fonctionnalité au routeur : le NAT.

On va le connecter à internet (simulation du fait d'avoir une IP publique) et il va faire du NAT pour permettre à toutes les machines du réseau d'avoir un accès internet.

## 1. Topologie 4

## 2. Adressage topologie 4

Les réseaux et leurs VLANs associés :

| Réseau    | Adresse       | VLAN associé |
| --------- | ------------- | ------------ |
| `clients` | `10.1.1.0/24` | 11           |
| `admins`  | `10.2.2.0/24` | 12           |
| `servers` | `10.3.3.0/24` | 13           |

L'adresse des machines au sein de ces réseaux :

| Node               | `clients`       | `admins`        | `servers`       |
| ------------------ | --------------- | --------------- | --------------- |
| `pc1.clients.tp4`  | `10.1.1.1/24`   | x               | x               |
| `pc2.clients.tp4`  | `10.1.1.2/24`   | x               | x               |
| `adm1.admins.tp4`  | x               | `10.2.2.1/24`   | x               |
| `web1.servers.tp4` | x               | x               | `10.3.3.1/24`   |
| `r1`               | `10.1.1.254/24` | `10.2.2.254/24` | `10.3.3.254/24` |

## 3. Setup topologie 4

🌞 **Ajoutez le noeud Cloud à la topo**

- branchez à `eth1` côté Cloud
- côté routeur, il faudra récupérer un IP en DHCP (voir [le mémo Cisco](../../cours/memo/memo_cisco.md))
- vous devriez pouvoir `ping 1.1.1.1`

🌞 **Configurez le NAT**

- référez-vous [à la section NAT du mémo Cisco](../../cours/memo/memo_cisco.md#7-configuration-dun-nat-simple)

🌞 **Test**

- ajoutez une route par défaut (si c'est pas déjà fait)
  - sur les VPCS
  - sur la machine Linux
- configurez l'utilisation d'un DNS
  - sur les VPCS
  - sur la machine Linux
- vérifiez un `ping` vers un nom de domaine

# V. Add a building

On a acheté un nouveau bâtiment, faut tirer et configurer un nouveau switch jusque là-bas.

On va en profiter pour setup un serveur DHCP pour les clients qui s'y trouvent.

## 1. Topologie 5

## 2. Adressage topologie 5

Les réseaux et leurs VLANs associés :

| Réseau    | Adresse       | VLAN associé |
| --------- | ------------- | ------------ |
| `clients` | `10.1.1.0/24` | 11           |
| `admins`  | `10.2.2.0/24` | 12           |
| `servers` | `10.3.3.0/24` | 13           |

L'adresse des machines au sein de ces réseaux :

| Node                | `clients`       | `admins`        | `servers`       |
| ------------------- | --------------- | --------------- | --------------- |
| `pc1.clients.tp4`   | `10.1.1.1/24`   | x               | x               |
| `pc2.clients.tp4`   | `10.1.1.2/24`   | x               | x               |
| `pc3.clients.tp4`   | DHCP            | x               | x               |
| `pc4.clients.tp4`   | DHCP            | x               | x               |
| `pc5.clients.tp4`   | DHCP            | x               | x               |
| `dhcp1.clients.tp4` | `10.1.1.253/24` | x               | x               |
| `adm1.admins.tp4`   | x               | `10.2.2.1/24`   | x               |
| `web1.servers.tp4`  | x               | x               | `10.3.3.1/24`   |
| `r1`                | `10.1.1.254/24` | `10.2.2.254/24` | `10.3.3.254/24` |

## 3. Setup topologie 5

Vous pouvez partir de la topologie 4.

🌞 **Vous devez me rendre le `show running-config` de tous les équipements**

- de tous les équipements réseau
  - le routeur
  - les 3 switches

> N'oubliez pas les VLANs sur tous les switches.

🖥️ **VM `dhcp1.client1.tp4`**, déroulez la [Checklist VM Linux](#checklist-vm-linux) dessus

🌞 **Mettre en place un serveur DHCP dans le nouveau bâtiment**

- il doit distribuer des IPs aux clients dans le réseau `clients` qui sont branchés au même switch que lui
- sans aucune action manuelle, les clients doivent...
  - avoir une IP dans le réseau `clients`
  - avoir un accès au réseau `servers`
  - avoir un accès WAN
  - avoir de la résolution DNS

> Réutiliser les serveurs DHCP qu'on a monté dans les autres TPs.

🌞 **Vérification**

- un client récupère une IP en DHCP
- il peut ping le serveur Web
- il peut ping `8.8.8.8`
- il peut ping `google.com`

> Faites ça sur n'importe quel VPCS que vous venez d'ajouter : `pc3` ou `pc4` ou `pc5`.
