# Module 4 : Sauvegarde du système de fichiers

Dans cette partie, **on va monter un _serveur de sauvegarde_ qui sera chargé d'accueillir les sauvegardes des autres machines**, en particulier du serveur Web qui porte NextCloud.

On fait les mêmes étapes que le module 3 en changeant le script et le nom d'utilisateur:
[Reference au module3]

[Script nextcloud backup](tp3_backup.sh)
[Timer](backup.timer)
[Service](backup.service)

## II. NFS

### 1. Serveur NFS

🖥️ **VM `storage.tp3.linux`**

**N'oubliez pas de dérouler la [📝**checklist**📝](../../2/README.md#checklist).**

➜ **Préparer un dossier à partager** sur le réseaucsur la machine `storage.tp3.linux`

```
[gene@storage ~]$ sudo mkdir /srv/nfs_shares
[gene@storage ~]$ sudo mkdir /srv/nfs_shares/web.tp2.linux
[gene@storage ~]$ sudo dnf install nfs-utils
```

➜ **Installer le serveur NFS**

```
[gene@storage ~]$ cat /etc/exports
/srv/nfs_shares    client_ip(rw,sync,no_root_squash,no_subtree_check)

[gene@storage ~]$ sudo firewall-cmd --permanent --add-service=nfs
success
[gene@storage ~]$ sudo firewall-cmd --permanent --add-service=mountd
success
[gene@storage ~]$ sudo firewall-cmd --permanent --add-service=rpc-bind
success
[gene@storage ~]$ sudo firewall-cmd --reload
success
```

### 2. Client NFS

➜ **Installer un client NFS sur `web.tp2.linux`**

```
[gene@web ~]$ sudo dnf install nfs-utils
[...]
[gene@db srv]$ sudo mount -t nfs 10.102.1.15:/srv/nfs_shares/web.tp2.linux/ /srv/backup/
[gene@web ~]$ df -h | grep nfs
10.102.1.15:/srv/nfs_shares/web.tp2.linux  6.2G  1.2G  5.1G  20% /srv/backup
[gene@web ~]$ cat /etc/fstab | grep nfs
10.102.1.15:/srv/nfs_shares/web.tp2.linux/ /srv/backup nfs defaults 0 0
```

➜ **Tester la restauration des données** sinon ça sert à rien :

```
[gene@web srv]$ sudo ls /srv/backup/
[gene@web srv]$ sudo -u backup bash tp3_backup.sh
[gene@web srv]$ sudo ls /srv/backup/
nextcloud_221122_183521.tar.gz
[gene@storage ~]$ sudo tree /srv/nfs_shares/
/srv/nfs_shares/
└── web.tp2.linux
    └── nextcloud_221122_183521.tar.gz

2 directories, 2 files
```
