#!/bin/bash

# SERVEURS
SRV_FW="172.16.3.240"
SRV_DB="172.16.3.239"
SRV_WEB="192.168.100.2"

# PC de management
PC_MGMT="172.16.3.19"

# GATEWAY
GW_LAN=eth0
GW_WAN=eth1
GW_DMZ=eth2

# ROUTEUR INTERFACES
eth0="172.16.3.240"
eth1="192.168.3.237"
eth2="192.168.100.1"

# RESEAUX
NET_LAN="172.16.3.0/24"
NET_DMZ="192.168.100.0/24"

# Suppression des règles
iptables -F
iptables -X
iptables -t nat -F

# Activation IP FORWARDING et MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o $GW_WAN -j MASQUERADE

# Autoriser les paquets bi-directionnels
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT

# Ajout des règles DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Autoriser SSH sur le FW
iptables -A INPUT -p tcp --dport 22 -d $SRV_FW -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -d $PC_MGMT -j ACCEPT

# Autoriser les accès internet depuis le LAN en passant par le FW
iptables -A FORWARD -i $GW_LAN -o $GW_WAN -p icmp -j ACCEPT
iptables -A FORWARD -i $GW_LAN -o $GW_WAN -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i $GW_LAN -o $GW_WAN -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i $GW_LAN -o $GW_WAN -p udp --dport 53 -j ACCEPT

# Autoriser les accès internet depuis la DMZ en passant par le FW
iptables -A FORWARD -i $GW_DMZ -o $GW_WAN -p icmp -j ACCEPT
iptables -A FORWARD -i $GW_DMZ -o $GW_WAN -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i $GW_DMZ -o $GW_WAN -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i $GW_DMZ -o $GW_WAN -p udp --dport 53 -j ACCEPT

# Autoriser le LAN vers SRV_WEB en HTTP et HTTPS
iptables -A FORWARD -s $NET_LAN -d $SRV_WEB -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s $NET_LAN -d $SRV_WEB -p tcp --dport 443 -j ACCEPT

# Autoriser le WAN vers SRV_WEB en HTTP et HTTPS
iptables -A FORWARD -i $GW_WAN -o $GW_DMZ -d $SRV_WEB -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i $GW_WAN -o $GW_DMZ -d $SRV_WEB -p tcp --dport 443 -j ACCEPT

# Autoriser le LAN vers SRV_WEB en FTP
iptables -A FORWARD -s $NET_LAN -d $SRV_WEB -p tcp --dport 20 -j ACCEPT
iptables -A FORWARD -s $NET_LAN -d $SRV_WEB -p tcp --dport 21 -j ACCEPT

# Autoriser SRV_WEB vers SRV_DB sur le port 3306
iptables -A FORWARD -s $SRV_WEB -d $SRV_DB -p tcp --dport 3306 -j ACCEPT
