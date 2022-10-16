# TP4 : TCP, UDP et services réseau

Dans ce TP on va explorer un peu les protocoles TCP et UDP. On va aussi mettre en place des services qui font appel à ces protocoles.

# I. First steps

Faites-vous un petit top 5 des applications que vous utilisez sur votre PC souvent, des applications qui utilisent le réseau : un site que vous visitez souvent, un jeu en ligne, Spotify, j'sais po moi, n'importe.

🌞 **Déterminez, pour ces 5 applications, si c'est du TCP ou de l'UDP**

**-Discord :**
`TCP 20.90.152.133:443 port local 59940`

**-Chrome :**
`TCP 52.54.178.155:443 port local 60176`

**-Riot Client :**
`TCP 92.122.218.144:443 port local 60285`

**-Minecraft Launcher :**
`TCP 13.107.246.43:443 port 60376`

**-Launcher Origin :**
`TCP 23.57.5.5:443 port local 60464`

🌞 **Demandez l'avis à votre OS**

```
netstat -abfnt
```

> 🦈![discord](./pcap/TCP_Discord.pcapng)

> 🦈![chrome](./pcap/TCP_chrome.pcapng)

> 🦈![riot](./pcap/TCP_Riot.pcapng)

> 🦈![minecraft](./pcap/TCP_Minecraft.pcapng)

> 🦈![origin](./pcap/TCP_Origin.pcapng)

# II. Mise en place

## 1. SSH

🌞 **Examinez le trafic dans Wireshark**

SSH utilise du TCP, on peut voir que le port local est 22 et le port distant est 50138.

🌞 **Demandez aux OS**

- repérez, avec un commande adaptée, la connexion SSH depuis votre machine
- ET repérez la connexion SSH depuis votre VM

Windows

```
netstat -abfnt
 Impossible d’obtenir les informations de propriétaire
    TCP    10.3.1.1:50138         10.3.1.11:22           ESTABLISHED
```

```
ss -ti
State         Recv-Q         Send-Q                  Local Address:Port                   Peer Address:Port          Process
ESTAB         0              0                           10.3.1.11:ssh                        10.3.1.1:50192
         cubic wscale:8,7 rto:230 rtt:29.868/16.836 ato:40 mss:1364 pmtu:1500 rcvmss:1364 advmss:1460 cwnd:10 bytes_sent:8105 bytes_acked:8105 bytes_received:3049 segs_out:75 segs_in:69 data_segs_out:64 data_segs_in:29 send 3.65Mbps lastsnd:293 lastrcv:2 lastack:2 pacing_rate 7.31Mbps delivery_rate 42.8Mbps delivered:65 busy:859ms rcv_space:14600 rcv_ssthresh:64076 minrtt:0.283
```

> 🦈 ![Capture SSH](./pcap/TCP_ssh.pcapng)

## 2. NFS

🌞 **Mettez en place un petit serveur NFS sur l'une des deux VMs**

```
[gene@localhost ~]$ sudo dnf -y install nfs-utils
[...]
Complete!
[gene@localhost ~]$ sudo nano /etc/idmapd.conf
[gene@localhost ~]$ sudo nano /etc/exports
[gene@localhost ~]$ cat /etc/exports
/srv/nfsshare 10.3.1.0/24(rw,no_root_squash)
[gene@localhost ~]$ sudo systemctl enable --now rpcbind nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[gene@localhost ~]$ sudo firewall-cmd --add-service=nfs
success
[gene@localhost ~]$ sudo firewall-cmd --runtime-to-permanent
success
[gene@localhost ~]$ sudo mkdir /srv/nfsshare
[gene@localhost ~]$ sudo nano /srv/nfsshare/helloworld.txt
[gene@localhost ~]$ cat /srv/nfsshare/helloworld.txt
helloworld!
```

```
[gene@localhost ~]$ sudo mount -t nfs 10.3.1.11:/srv/shared /mnt
[gene@client ~]$ df -hT /mnt
Filesystem            Type  Size  Used Avail Use% Mounted on
10.3.1.11:/srv/shared nfs4  6.2G  1.1G  5.2G  17% /mnt
[gene@client ~]$ cat /mnt/hi.txt
Salut à tous les amis c'est David Lafarge Pokemon j'espère que vous allez bien.
```

🌞 **Wireshark it !**

[gene@localhost srv]$ sudo tcpdump -i enp0s8 -c 10 -w nfs.pcapng not port 22
dropped privs to tcpdump
tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
20 packets received by filter
0 packets dropped by kernel

🌞 **Demandez aux OS**

- repérez, avec un commande adaptée, la connexion NFS sur le client et sur le serveur

```
[gene@localhost srv]$ sudo ss -ltpn | grep 2049
LISTEN 0      64           0.0.0.0:2049       0.0.0.0:*
LISTEN 0      64              [::]:2049          [::]:*
[gene@client ~]$ sudo ss -tp
State         Recv-Q         Send-Q                 Local Address:Port                    Peer Address:Port          Process
ESTAB         0              0                          10.3.1.12:pop3s                      10.3.1.11:nfs
```

> 🦈 [capture NFS](./pcap/TCP_nfs.pcapng)

## 3. DNS

🌞 Utilisez une commande pour effectuer une requête DNS depuis une des VMs

- capturez le trafic avec un `tcpdump`
- déterminez le port et l'IP du serveur DNS auquel vous vous connectez
  - port : 53
  - IP : 192.168.112.25

```
[gene@localhost shared]$ sudo tcpdump -i enp0s3 -c 10 -w dns.pcapng not port 22 &
[3] 2479
[gene@localhost shared]$ dropped privs to tcpdump
tcpdump: listening on enp0s3, link-type EN10MB (Ethernet), snapshot length 262144 bytes
dig millesima.fr | grep SERVER
;; SERVER: 192.168.112.251#53(192.168.112.251)
[gene@localhost shared]$ 10 packets captured
10 packets received by filter
0 packets dropped by kernel
```
