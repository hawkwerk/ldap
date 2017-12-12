#!/bin/bash

route add -net 10.69.0.0/24 dev enp0s8
iptables -t nat -A POSTROUTING ! -d 10.69.0.0/24 -o enp0s3 -j SNAT --to-source 192.168.28.163
/etc/init.d/networking restart

