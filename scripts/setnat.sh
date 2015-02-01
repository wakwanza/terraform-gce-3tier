#!/bin/bash
#
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables --A FORWARD --in-interface eth0 -j ACCEPT
sudo service iptables save
sudo sed -i 's/.*net.ipv4.ip_forward = 0*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
sudo sysctl -e -p /etc/sysctl.conf
