# TP1 : (re)Familiaration avec un système GNU/Linux

Dans ce TP, on va passer en revue des éléments de configurations élémentaires du système.

Vous pouvez effectuer ces actions dans la première VM. On la clonera ensuite avec toutes les configurations pré-effectuées.

Au menu :

- gestion d'utilisateurs
  - sudo
  - SSH et clés
- configuration réseau
- gestion de partitions
- gestion de services

## 0. Préparation de la machine

> **POUR RAPPEL** pour chacune des opérations, vous devez fournir dans le compte-rendu : comment réaliser l'opération ET la preuve que l'opération a été bien réalisée

🌞 **Setup de deux machines Rocky Linux configurées de façon basique.**

- **un accès internet (via la carte NAT)**

```
[gene@node1 ~]$ ip r s
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100

[gene@node1 ~]$ ip a
[...]
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:92:b4:52 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 85716sec preferred_lft 85716sec
    inet6 fe80::a00:27ff:fe92:b452/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:25:74:5e brd ff:ff:ff:ff:ff:ff
    inet 10.101.1.11/24 brd 10.101.1.255 scope global noprefixroute enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe25:745e/64 scope link
       valid_lft forever preferred_lft forever
```

- **un accès à un réseau local** (les deux machines peuvent se `ping`) (via la carte Host-Only)

```
[gene@node1 ~]$ ping -c 1 10.101.1.12
PING 10.101.1.12 (10.101.1.12) 56(84) bytes of data.
64 bytes from 10.101.1.12: icmp_seq=1 ttl=64 time=11.45 ms
[...]
```

- **vous n'utilisez QUE `ssh` pour administrer les machines**

- **les machines doivent avoir un nom**

```
[gene@node1 ~]$ cat /etc/hostname
node1.tp1.b2
```

- **utiliser `1.1.1.1` comme serveur DNS**

```
[gene@node1 ~]$ ping -c 1 10.101.1.12
PING 10.101.1.12 (10.101.1.12) 56(84) bytes of data.
64 bytes from 10.101.1.12: icmp_seq=1 ttl=64 time=11.45 ms
[...]
```

dig ynov :

```
[gene@node1 ~]$ dig ynov.com

  ; <<>> DiG 9.16.23-RH <<>> ynov.com
  [...]

  ;; ANSWER SECTION:
  ynov.com.               300     IN      A       172.67.74.226
  ynov.com.               300     IN      A       104.26.11.233
  ynov.com.               300     IN      A       104.26.10.233

  ;; Query time: 30 msec
  ;; SERVER: 1.1.1.1#53(1.1.1.1)
  ;; WHEN: Mon Nov 14 21:53:11 CET 2022
  ;; MSG SIZE  rcvd: 85
```

- **les machines doivent pouvoir se joindre par leurs noms respectifs**

  - fichier `/etc/hosts`

  ```
  [gene@node1 ~]$ cat /etc/hosts
  127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
  10.101.1.12 node2.tp1.b2

  [gene@node2 ~]$ cat /etc/hosts
  127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
  10.101.1.11 node1.tp1.b2
  ```

- assurez-vous du bon fonctionnement avec des `ping <NOM>`

  ```
  [gene@node1 ~]$ ping node2.tp1.b2
  PING node2.tp1.b2 (10.101.1.12) 56(84) bytes of data.
  64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=1 ttl=64 time=10.37 ms
  [...]
  ```

- **le pare-feu est configuré pour bloquer toutes les connexions exceptées celles qui sont nécessaires**
- commande `firewall-cmd`
  ```
  [gene@node1 ~]$ sudo firewall-cmd --list-all
  public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
  ```

Pour le réseau des différentes machines (ce sont les IP qui doivent figurer sur les interfaces host-only):

| Name              | IP            |
| ----------------- | ------------- |
| 🖥️ `node1.tp1.b2` | `10.101.1.11` |
| 🖥️ `node2.tp1.b2` | `10.101.1.12` |
| Votre hôte        | `10.101.1.1`  |

## I. Utilisateurs

### 1. Création et configuration

🌞 **Ajouter un utilisateur à la machine**, qui sera dédié à son administration

```
[gene@node1 ~]$ sudo useradd superu -m -s /bin/bash -u 2000
```

🌞 **Créer un nouveau groupe `admins`** qui contiendra les utilisateurs de la machine ayant accès aux droits de `root` _via_ la commande `sudo`.

```
[gene@node2 ~]$ sudo groupadd admin
```

- il faut modifier le fichier `/etc/sudoers`

```
[gene@node1 ~]$ sudo cat /etc/sudoers | grep admin
%admin ALL=(ALL)        ALL
```

🌞 **Ajouter votre utilisateur à ce groupe `admins`**

```
[superu@node1 ~]$ sudo cat /etc/sudoers | grep admin

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for superu:
%admin ALL=(ALL)        ALL
```

### 2. SSH

Afin de se connecter à la machine de façon plus sécurisée, on va configurer un échange de clés SSH lorsque l'on se connecte à la machine.

🌞 **Pour cela...**

- il faut générer une clé sur le poste client de l'administrateur qui se connectera à distance (vous :) )\*

```
PS C:\Users\gene\.ssh> ssh-keygen -t rsa -b 4096
```

- déposer la clé dans le fichier `/home/<USER>/.ssh/authorized_keys` de la machine que l'on souhaite administrer

```
$ ssh-copy-id superu@10.101.1.11
```

🌞 **Assurez vous que la connexion SSH est fonctionnelle**,

```
PS C:\Users\gene> ssh superu@10.101.1.11
Last login: Mon Nov 14 21:55:56 2022
[superu@node1 ~]$
```

## II. Partitionnement

### 1. Préparation de la VM

⚠️ **Uniquement sur `node1.tp1.b2`.**

Ajout de deux disques durs à la machine virtuelle, de 3Go chacun.

### 2. Partitionnement

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Utilisez LVM** pour...

![tonton bernard](/Reseau/Linux/pics/bernard-arnault-lvmh.gif)

```
[superu@node1 ~]$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda           8:0    0    8G  0 disk
├─sda1        8:1    0    1G  0 part /boot
└─sda2        8:2    0    7G  0 part
  ├─rl-root 253:0    0  6.2G  0 lvm  /
  └─rl-swap 253:1    0  820M  0 lvm  [SWAP]
sdb           8:16   0    3G  0 disk
sdc           8:32   0    3G  0 disk
sr0          11:0    1 1024M  0 rom
sr1          11:1    1 1024M  0 rom
[superu@node1 ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[superu@node1 ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
[superu@node1 ~]$ sudo vgcreate data /dev/sdb
  Volume group "data" successfully created
[superu@node1 ~]$ sudo vgextend data /dev/sdc
  Volume group "data" successfully extended
[superu@node1 ~]$ sudo lvcreate -L 1G ma_data_frer
  Volume group "ma_data_frer" not found
  Cannot process volume group ma_data_frer
[superu@node1 ~]$ sudo lvcreate -L 1G data -n ma_data_frer
  Logical volume "ma_data_frer" created.
[superu@node1 ~]$ sudo lvcreate -L 1G data -n ta_data_frer
  Logical volume "ta_data_frer" created.
[superu@node1 ~]$ sudo lvcreate -L 1G data -n notre_data_frer
  Logical volume "notre_data_frer" created.
[superu@node1 ~]$ sudo lvs
  Devices file sys_wwid t10.ATA_____VBOX_HARDDISK___________________________VB71c14673-0b93689a_ PVID uw2adegCrXtIZZ3n5lqU9WlQZC3CMgHs last seen on /dev/sda2 not found.
  LV              VG   Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ma_data_frer    data -wi-a----- 1.00g
  notre_data_frer data -wi-a----- 1.00g
  ta_data_frer    data -wi-a----- 1.00g
```

```
[superu@node1 ~]$ sudo mkfs -t ext4 /dev/data/ma_data_frer
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: b8e1fae5-c73c-4f62-b1e0-54e3a9980b9f
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376
Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
[superu@node1 ~]$ sudo mkfs -t ext4 /dev/data/ta_data_frer
[...]
[superu@node1 ~]$ sudo mkfs -t ext4 /dev/data notre_data_frer
[...]
```

```
[superu@node1 ~]$ sudo mount /dev/data/ma_data_frer /mnt/part1
[superu@node1 ~]$ sudo mount /dev/data/ta_data_frer /mnt/part2
[superu@node1 ~]$ sudo mount /dev/data/notre_data_frer /mnt/part2
[superu@node1 ~]$ df -h
Filesystem                        Size  Used Avail Use% Mounted on
devtmpfs                          869M     0  869M   0% /dev
tmpfs                             888M     0  888M   0% /dev/shm
tmpfs                             356M  5.0M  351M   2% /run
/dev/mapper/rl-root               6.2G  1.1G  5.2G  17% /
/dev/sda1                        1014M  271M  744M  27% /boot
tmpfs                             178M     0  178M   0% /run/user/2000
/dev/mapper/data-ma_data_frer     974M   24K  907M   1% /mnt/part1
/dev/mapper/data-ta_data_frer     974M   24K  907M   1% /mnt/part2
/dev/mapper/data-notre_data_frer  974M   24K  907M   1% /mnt/part3
```

🌞 **Grâce au fichier `/etc/fstab`**, faites en sorte que cette partition soit montée automatiquement au démarrage du système.

```
[superu@node1 ~]$ cat /etc/fstab
#
# /etc/fstab
# Created by anaconda on Fri Sep 30 13:06:13 2022
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
/dev/mapper/rl-root     /                       xfs     defaults        0 0
UUID=24676b28-2ebd-46cd-a002-43a7e7316046 /boot                   xfs     defaults        0 0
/dev/mapper/rl-swap     none                    swap    defaults        0 0
/dev/mapper/data-ma_data_frer /mnt/part1 ext4 defaults 0 0
/dev/mapper/data-ta_data_frer /mnt/part2 ext4 defaults 0 0
/dev/mapper/data-notre_data_frer /mnt/part3 ext4 defaults 0 0
```

✨**Bonus** : amusez vous avez les options de montage. Quelques options intéressantes :

```
[superu@node1 ~]$ cat /etc/fstab
[...]
/dev/mapper/data-ma_data_frer /mnt/part1 ext4 noexec 0 0
/dev/mapper/data-ta_data_frer /mnt/part2 ext4 nodev 0 0
[...]
```

## III. Gestion de services

Au sein des systèmes GNU/Linux les plus utilisés, c'est _systemd_ qui est utilisé comme gestionnaire de services (entre autres).

Pour manipuler les services entretenus par _systemd_, on utilise la commande `systemctl`.

On peut lister les unités `systemd` actives de la machine `systemctl list-units -t service`.

**Référez-vous au mémo pour voir les autres commandes `systemctl` usuelles.**

## 1. Interaction avec un service existant

⚠️ **Uniquement sur `node1.tp1.b2`.**

Parmi les services système déjà installés sur Rocky, il existe `firewalld`. Cet utilitaire est l'outil de firewalling de Rocky.

🌞 **Assurez-vous que...**

```
[superu@node1 ~]$ systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2022-11-14 21:11:50 CET; 55min ago
       Docs: man:firewalld(1)
   Main PID: 670 (firewalld)
      Tasks: 2 (limit: 11120)
     Memory: 42.3M
        CPU: 1.923s
     CGroup: /system.slice/firewalld.service
             └─670 /usr/bin/python3 -s /usr/sbin/firewalld --nofork --nopid
```

## 2. Création de service

### A. Unité simpliste

⚠️ **Uniquement sur `node1.tp1.b2`.**

🌞 **Créer un fichier qui définit une unité de service**

- le fichier `web.service`
- dans le répertoire `/etc/systemd/system`

Déposer le contenu suivant :

```
[superu@node1 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Very simple web service
[Service]
ExecStart=/usr/bin/python3 -m http.server 8888
[Install]
WantedBy=multi-user.target
```

Le but de cette unité est de lancer un serveur web sur le port 8888 de la machine. **N'oubliez pas d'ouvrir ce port dans le firewall.**

```
[superu@node1 ~]$ sudo  systemctl daemon-reload
[superu@node1 ~]$ sudo systemctl status web
○ web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; disabled; vendor preset: disabled)
     Active: inactive (dead)
[superu@node1 ~]$ sudo systemctl start web
[superu@node1 ~]$ sudo systemctl enable web
Created symlink /etc/systemd/system/multi-user.target.wants/web.service → /etc/systemd/system/web.service.
```

🌞 **Une fois le service démarré, assurez-vous que pouvez accéder au serveur web**

```
[superu@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="afs/">afs/</a></li>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

### B. Modification de l'unité

🌞 **Préparez l'environnement pour exécuter le mini serveur web Python**

```
[superu@node1 ~]$ sudo useradd web -m -s /bin/bash -u 2001
[superu@node1 ~]$ sudo passwd web
Changing password for user web.
[...]
[web@node1 ~]$ sudo mkdir /var/www/
[web@node1 ~]$ sudo mkdir /var/www/meow/
[web@node1 ~]$ sudo chown web:admin /var/www/
```

```
[web@node1 ~]$ nano /var/www/meow/woof
[web@node1 ~]$ ls -al /var/www/
total 4
drwxr-xr-x.  3 web  admin   18 Nov 14 21:53 .
drwxr-xr-x. 20 root root  4096 Nov 14 21:53 ..
drwxr-xr-x.  2 web  admin   18 Nov 14 22:11 meow
[web@node1 ~]$ ls -al /var/www/meow | grep woof
-rw-r--r--. 1 web web    7 Nov 14 22:11 woof
```

> Pour que tout fonctionne correctement, il faudra veiller à ce que le dossier et le fichier appartiennent à l'utilisateur `web` et qu'il ait des droits suffisants dessus.
> 🌞 **Modifiez l'unité de service `web.service` créée précédemment en ajoutant les clauses**

```
[web@node1 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Very simple web service
[Service]
ExecStart=/usr/bin/python3 -m http.server 8888
User=web
WorkingDirectory=/var/www/meow/
[Install]
WantedBy=multi-user.target
```

🌞 **Vérifiez le bon fonctionnement avec une commande `curl`**

```
[superu@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="woof">woof</a></li>
</ul>
<hr>
</body>
<html>
```
