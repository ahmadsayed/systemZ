#!/bin/bash
sudo iptables -F INPUT
sudo iptables -F OUTPUT
sudo iptables -F FORWARD
sudo iptables -t nat -A POSTROUTING -o ens160 -s 10.1.1.0/24 -j MASQUERADE
sudo iptables -A FORWARD -s 10.1.1.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 10.1.1.0/24 -j ACCEPT
sudo echo 1  /proc/sys/net/ipv4/ip_forward
sudo echo 1  /proc/sys/net/ipv4/conf/all/proxy_arp
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl net.ipv4.conf.eth0.forwarding=1
