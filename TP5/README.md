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
  sw1#show vlan
  10   clients                           active    Et0/0, Et0/1
  29   admins                          active    Et0/2
```

🌞 **Vérif**

```
PC1> ping 10.5.10.2

84 bytes from 10.5.10.2 icmp_seq=1 ttl=64 time=0.221 ms
```

```
PC3> ping 10.5.10.1

host (10.5.10.1) not reachable
```

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

```
  PC1> show ip all
  NAME   IP/MASK              GATEWAY           MAC                DNS
  PC1    10.5.40.1/24         255.255.255.0     00:50:79:66:68:00
```

```
PC2> show ip all
NAME   IP/MASK              GATEWAY           MAC                DNS
PC2    10.5.40.2/24         255.255.255.0     00:50:79:66:68:01
```

```
adm1> show ip all
NAME   IP/MASK              GATEWAY           MAC                DNS
adm1   10.5.50.1/24         255.255.255.0     00:50:79:66:68:02
```

```
[gene@web1 ~]$ ip a
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:a6:b1:98 brd ff:ff:ff:ff:ff:ff
    inet 10.5.30.1/24 brd 10.5.30.255 scope global noprefixroute enp0s3
      valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fea6:b198/64 scope link
      valid_lft forever preferred_lft forever
```

🌞 **Configuration des VLANs**

```
sw1#show vlan
  VLAN Name                             Status    Ports
  ---- -------------------------------- --------- -------------------------------
  1    default                          active    Et1/0, Et1/1, Et1/2, Et1/3
                                                  Et2/0, Et2/1, Et2/2, Et2/3
                                                  Et3/0, Et3/1, Et3/2

  10   clients                          active    Et0/3
  20   admins                           active    Et0/0, Et0/1
  30   servers                          active    Et0/2
  sw1#show interface trunk
  Port        Mode             Encapsulation  Status        Native vlan
  Et3/3       on               802.1q         trunking      1
  Port        Vlans allowed on trunk
  Et3/3       1-4094
  Port        Vlans allowed and active in management domain
  Et3/3       1,30,40,50
  Port        Vlans in spanning tree forwarding state and not pruned
  Et3/3       1,30,40,50
```

🌞 **Config du _routeur_**

```
   R1#show ip int br
   Interface                  IP-Address      OK? Method Status                Protocol
   FastEthernet0/0            unassigned      YES unset  administratively down down
   FastEthernet0/0.30         10.5.10.254     YES manual administratively down down
   FastEthernet0/0.40         10.5.20.254     YES manual administratively down down
   FastEthernet0/0.50         10.5.30.254     YES manual administratively down down
```

🌞 **Vérif**

- tout le monde doit pouvoir ping le routeur sur l'IP qui est dans son réseau
  ```
  PC1> ping 10.5.10.254
  84 bytes from 10.5.10.254 icmp_seq=1 ttl=255 time=4.473 ms
  PC2> ping 10.5.10.254
  84 bytes from 10.5.10.254 icmp_seq=2 ttl=255 time=4.510 ms
  ```
  ```
  adm1> ping 10.5.20.254
  84 bytes from 10.5.20.254 icmp_seq=2 ttl=255 time=10.536 ms
  ```
  ```
  [gene@web1 ~]$ ping 10.5.30.254
  PING 10.5.30.254 (10.5.30.254) 56(84) bytes of data.
  64 bytes from 10.5.30.254: icmp_seq=1 ttl=255 time=9.02 ms
  ```
- en ajoutant une route vers les réseaux, ils peuvent se ping entre eux

  - ajoutez une route par défaut sur les VPCS
    ```
    PC1> ip 10.5.40.1 255.255.255.0 10.5.40.254
    PC2> ip 10.5.40.2 255.255.255.0 10.5.40.254
    adm1> 10.5.50.1 255.255.255.0 gateway 10.5.50.254
    ```
  - ajoutez une route par défaut sur la machine virtuelle
    ```
    [gene@web1 ~]$ ip route | grep default
    default via 10.5.30.254 dev enp0s3 proto static metric 102
    ```
  - testez des `ping` entre les réseaux

    ```
    PC1> ping 10.5.20.1
    84 bytes from 10.5.20.1 icmp_seq=1 ttl=63 time=23.065 ms
    PC1> ping 10.5.30.1
    84 bytes from 10.5.30.1 icmp_seq=1 ttl=63 time=19.975 ms
    ```

    ```
    adm1> ping 10.5.30.1
    84 bytes from 10.5.30.1 icmp_seq=1 ttl=63 time=20.062 ms
    adm1> ping 10.5.10.1
    84 bytes from 10.5.10.1 icmp_seq=1 ttl=63 time=14.471 ms
    ```

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
- côté routeur, il faudra récupérer un IP en DHCP :

```
R1(config)#interface FastEthernet0/1
R1(config-if)#ip address dhcp
R1(config-if)#no shut
R1(config-if)#exit
R1(config)#exit

R1#show ip int br
Interface                  IP-Address      OK? Method Status                Protocol
[...]
FastEthernet0/1            10.0.3.16       YES DHCP   up                    up
[...]
```

- vous devriez pouvoir ping 1.1.1.1

```
R1#ping 1.1.1.1

Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 1.1.1.1, timeout is 2 seconds:
.!!!!
Success rate is 80 percent (4/5), round-trip min/avg/max = 20/62/160 ms
```

🌞 **Configurez le NAT**

```
R1#conf t
R1(config)#interface fastEthernet0/1
R1(config-if)#ip address dhcp
R1(config-if)#no shut
R1(config-if)#ip nat outside
R1(config-if)#exit
R1(config)#interface fastEthernet0/0
R1(config-if)#ip nat inside
R1(config-if)#no shut
R1(config-if)#exit
R1(config)#access-list 1 permit any
R1(config)#ip nat inside source list 1 interface fastEthernet0/1 overload
R1(config)#exit
```

🌞 **Test**

- configurez l'utilisation d'un DNS

  - sur les VPCS :

  ```
  PC1> ip dns 1.1.1.1
  PC2> ip dns 1.1.1.1
  adm1> ip dns 1.1.1.1
  ```

  - sur la machine Linux :

  ```
  [gene@web1 ~]$ cat /etc/sysconfig/network-scripts/ifcfg-enp0s3 | grep DNS
  DNS1=1.1.1.1
  ```

- vérifiez un `ping` vers un nom de domaine :

```
PC1> ping gitlab.com
84 bytes from 172.65.251.78 icmp_seq=1 ttl=61 time=39.645 ms

PC2> ping google.com
google.com resolved to 142.250.179.110
84 bytes from 142.250.179.110 icmp_seq=1 ttl=112 time=29.360 ms

adm1> ping github.com
github.com resolved to 140.82.121.3
84 bytes from 140.82.121.3 icmp_seq=1 ttl=52 time=40.301 ms

[gene@web ~]$ ping gitlab.com
64 bytes from 172.65.251.78 (172.65.251.78): icmp_seq=1 ttl=61 time=49.5 ms
```

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

```

```
