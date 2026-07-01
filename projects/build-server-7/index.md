---
title: "Build server 7 — Out of the dorms"
description: "Technically this is a homelab now"
date: "2026-6-15"
categories: [projects]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: false
---


# The current (previous) setup

* Plugging the server into the wall at the dorms to get a public ipv4 addres
* Debian Base
    * Incus installed from Zabbly repos
* Kubernetes (K3s) on top, with all other services running inside K8s.

# Summer Revamp

This won't work over the summer, since the ports in my house are not public. So I was evaluating solutions for safely exposing the server. 

* <https://github.com/rathole-org/rathole> (what I previously used)
    * Is currently unmaintained
    * Many of the rust libraries have accrued CVE's
* Reverse proxy + wireguard
    * The problem is that I want to reverse proxy SSL all the way through, but I also want to send packets to different locations
* <https://erwanleboucher.dev/blog/towonel/>
    * New solution
    * Is nice, but also multi tenant, and a bit more than my liking
* <https://github.com/fyralabs/chisel-operator>
    * This is what I will be using. Since kubernetes is already reverse proxy, this makes things simple.

I still will have to wireguard the server/router to the VPS though. By forcing all traffic to be wireguarded to the VPS, this is a simple way to "firewall" off my home network from my public server, that also has other benefits. 

Also, I will probably use iptables + wireguard to expose the management services, like ssh or the kubernetes api.

# Router

I upgraded the version of freshtomato on my router. The updated version of freshtomato now gives options for configuring wireguard via the GUI:




Current iptables rules:

```{.default}
root@unknown:/tmp/home/root# iptables -L -v -n
Chain INPUT (policy DROP 188 packets, 33611 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    1    84 ACCEPT     all  --  wg0    *       0.0.0.0/0            0.0.0.0/0            state NEW
    6   240 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
 6776  943K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    1    60 shlimit    tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22 state NEW
    0     0 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0           
  791 62247 ACCEPT     all  --  br0    *       0.0.0.0/0            0.0.0.0/0           

Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 ACCEPT     all  --  *      wg0     0.0.0.0/0            0.0.0.0/0           
    0     0 ACCEPT     all  --  wg0    *       0.0.0.0/0            0.0.0.0/0            state NEW
    0     0 ACCEPT     all  --  br0    br0     0.0.0.0/0            0.0.0.0/0           
   32  1280 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
91590   90M ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
    0     0 ACCEPT     esp  --  vlan2  *       0.0.0.0/0            0.0.0.0/0           
    0     0 ACCEPT     ah   --  vlan2  *       0.0.0.0/0            0.0.0.0/0           
    0     0 ACCEPT     udp  --  vlan2  *       0.0.0.0/0            0.0.0.0/0            udp dpt:500
    0     0 ACCEPT     udp  --  vlan2  *       0.0.0.0/0            0.0.0.0/0            udp dpt:4500
    0     0 wanin      all  --  vlan2  *       0.0.0.0/0            0.0.0.0/0           
  368  171K wanout     all  --  *      vlan2   0.0.0.0/0            0.0.0.0/0           
  368  171K ACCEPT     all  --  br0    *       0.0.0.0/0            0.0.0.0/0           

Chain OUTPUT (policy ACCEPT 8865 packets, 23M bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain shlimit (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    1    60            all  --  *      *       0.0.0.0/0            0.0.0.0/0            recent: SET name: shlimit side: source mask: 255.255.255.255
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            recent: UPDATE seconds: 60 hit_count: 4 name: shlimit side: source mask: 255.255.255.255

Chain wanin (1 references)
 pkts bytes target     prot opt in     out     source               destination         

Chain wanout (1 references)
 pkts bytes target     prot opt in     out     source               destination         
```

Current interfaces: 

```{.default}
root@unknown:/tmp/home/root# ip a
1: lo: <LOOPBACK,MULTICAST,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 brd 127.255.255.255 scope host lo
2: ifb0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN qlen 32
    link/ether 26:97:bb:c9:3d:82 brd ff:ff:ff:ff:ff:ff
3: ifb1: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN qlen 32
    link/ether e2:7a:2a:9a:3e:d4 brd ff:ff:ff:ff:ff:ff
4: ifb2: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN qlen 32
    link/ether c6:a0:20:dd:c8:e3 brd ff:ff:ff:ff:ff:ff
5: ifb3: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN qlen 32
    link/ether 42:a5:30:79:e6:cd brd ff:ff:ff:ff:ff:ff
6: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000
    link/ether cc:40:d0:17:e7:65 brd ff:ff:ff:ff:ff:ff
9: dpsta: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN 
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
10: eth1: <BROADCAST,MULTICAST,ALLMULTI,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000
    link/ether cc:40:d0:17:e7:67 brd ff:ff:ff:ff:ff:ff
11: eth2: <BROADCAST,MULTICAST,ALLMULTI,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000
    link/ether cc:40:d0:17:e7:6b brd ff:ff:ff:ff:ff:ff
13: vlan1@eth0: <BROADCAST,MULTICAST,ALLMULTI,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether cc:40:d0:17:e7:65 brd ff:ff:ff:ff:ff:ff
14: vlan2@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether cc:40:d0:17:e7:75 brd ff:ff:ff:ff:ff:ff
    inet 192.168.4.56/22 brd 192.168.7.255 scope global vlan2
15: br0: <BROADCAST,MULTICAST,ALLMULTI,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN 
    link/ether cc:40:d0:17:e7:65 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.1/24 brd 192.168.1.255 scope global br0
27: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN 
    link/none 
    inet 10.0.0.2/24 scope global wg0
```

It looks like, by disabling the "firewall" option in the wireguard options, traffic is allowed to be forwarded. In addition to this, I can make pre and post routing scripts on both sides.

With this, I have the VPN setup I want. All traffic from the router goes through the VPN, and the VPS is also able to access the routers internal subnet.

```{.ini filename='/etc/wireguard/wg0.conf'}
[Interface]
PreUp = sysctl net.ipv4.ip_forward=1
PreUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PreUp = iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
Postup = iptables -A FORWARD -i %i -o eth0 -j ACCEPT
ListenPort = 51871
PrivateKey = lmao
Address = 10.0.0.1/24, fdc9:281f:04d7:9ee9::1/64
MTU = 1340

[Peer]
PublicKey = eDvHJOeB8RoP+4VnJGCdFJFJ+naRzG2z0N9pnFop/zY=
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24, fdc9:281f:4d7:9ee9::2/128
```

And then the router has something similar, but these configs are set via the GUI:




However, I am having connections be dropped for TLS traffic. After further testing, to confirm that it is an MTU related issue, I begin lowering it to experiment with what works. Unfornately, the common values of 1420, and 1380 don't work, although 1280 does. I test, raising numbers up and down and land on 1340.

After further investigation, it looks like [T Mobile recommends an MTU of 1340 for their VPN solution](https://www.t-mobile.com/community/discussions/gateways-devices/way-to-change-mtu-on-router/66287/replies/66293).

I also make sure to change the MTU of the router networking itself to 1420, in order to preemptively avoid issues.

The next thing I try to do is to prevent the web interface from being accessed remotely. In routers or similar types of devices (network appliances, etc), the web ui is a lot of attack surface, and a common cause of vulnerabilities. By making it only accessible over the much more secure and well tested ssh, I don't have to worry about that attack surface.

Unfortunately, there does not appear to be an option in the UI to make it only accessible over localhost.


## Finding another VPS Provider:

Even though I got everything connected:

```{.default}
[nix-shell:~]# speedtest
Retrieving speedtest.net configuration...
Testing from Unknown (193.181.213.37)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by wilhelm.tel (Norderstedt) [795.04 km]: 241.714 ms
Testing download speed................................................................................
Download: 25.54 Mbit/s
Testing upload speed......................................................................................................
Upload: 13.55 Mbit/s
```

Okay, I get a little better after tinkering with the MTU and increasing it from 1340 to 1360:

```{.default}
[nix-shell:~/.ssh]$ speedtest
Retrieving speedtest.net configuration...
Testing from Unknown (193.181.213.37)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by wilhelm.tel (Norderstedt) [795.04 km]: 238.535 ms
Testing download speed................................................................................
Download: 53.36 Mbit/s
Testing upload speed......................................................................................................
Upload: 14.06 Mbit/s
```

Unfortunately. I suspect this is because I am VPNing to Denmark and back. I am going to hunt for a closer VPS provider.

Or, this could also be because the VPS is very small, with only 1 vCPU. Wireguard isn't usually CPU limited, but it is worth running a additional tests in order to verify that this is the case.

```{.default}
root@ingress:/etc/wireguard# speedtest
Retrieving speedtest.net configuration...
Testing from Unknown (193.181.213.37)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by wilhelm.tel (Norderstedt) [795.04 km]: 18.767 ms
Testing download speed................................................................................
Download: 753.10 Mbit/s
Testing upload speed......................................................................................................
Upload: 780.29 Mbit/s
root@ingress:/etc/wireguard#
```

So it's not the VPS either. It has gigabit speeds, and this confirms it. 

Next up is to test the home lab server without the VPN:

```{.default}
[nix-shell:~]# speedtest
Retrieving speedtest.net configuration...
Testing from T-Mobile USA (172.56.241.36)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by KamaTera, Inc. (Los Angeles, CA) [8.67 km]: 45.191 ms
Testing download speed................................................................................
Download: 143.94 Mbit/s
Testing upload speed......................................................................................................
Upload: 26.44 Mbit/s
```

Looks plenty fast, no issues here as well.

```{.default}
[nix-shell:~]# iperf3 -c 193.181.213.37
Connecting to host 193.181.213.37, port 5201
[  7] local 192.168.1.33 port 49012 connected to 193.181.213.37 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  7]   0.00-1.00   sec  1.12 MBytes  9.43 Mbits/sec    0    384 KBytes
[  7]   1.00-2.00   sec  2.25 MBytes  18.9 Mbits/sec    1    523 KBytes
[  7]   2.00-3.00   sec  2.38 MBytes  19.9 Mbits/sec    1    405 KBytes
[  7]   3.00-4.00   sec   768 KBytes  6.29 Mbits/sec    0    317 KBytes
[  7]   4.00-5.00   sec  1.88 MBytes  15.7 Mbits/sec    0    350 KBytes
[  7]   5.00-6.00   sec  1.88 MBytes  15.7 Mbits/sec    0    364 KBytes
[  7]   6.00-7.00   sec  1.88 MBytes  15.7 Mbits/sec    0    368 KBytes
[  7]   7.00-8.00   sec  1.88 MBytes  15.7 Mbits/sec    1    258 KBytes
[  7]   8.00-9.00   sec   640 KBytes  5.24 Mbits/sec    0    302 KBytes
[  7]   9.00-10.00  sec   640 KBytes  5.24 Mbits/sec    0    329 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  7]   0.00-10.00  sec  15.2 MBytes  12.8 Mbits/sec    3            sender
[  7]   0.00-10.37  sec  14.5 MBytes  11.7 Mbits/sec                  receiver

iperf Done.
```

Yup. Looks like crossing the world is hard. Oh well.

So. Now, I'm going to select another provider. Ideally, it should be a cheap VPS provider, from a site that is well reputed. There is [lowendbox](https://lowendbox.com/), and the related forums [lowendtalk](https://lowendtalk.com/) which cover this. Unfortunately, when I click on some of them, they 404. The business model many of these low end providers start with, struggles to be sustainable, and they often die, which sucks.

So, I have a simple idea: I am going to look at the older posts for discounts, and see if they are still active. Interestingly, some of the best "one time discounts" are still active, despite the links being two years old. By cross referencing this with forum posts about those providers, I can confirm their reliability.

I'm not naming them this time, unlike my previous blog post where I just picked a popular provider.

Also, I am going to see if I can create a virtual credit card.

Okay. It was a hassle. It took me a while to get "verified", on <privacy.com>, the virtual credit card provider I am using. And then even after that, it took a few days for the VPS to go from "pending" to created. I did bug both providers with tickets a few times, so maybe that sped things along?

Regardless, I have US west coast VPS now. 

# Kubernetes

I have decided to keep k3s, for simplicity. For the record, I did investigate other solutions, to avoid the distasteful `curl | bash` in order to install k3s on debian.

* [k3's sysext](https://flatcar.github.io/sysext-bakery/k3s/) and then using [sysext manager](https://github.com/travier/sysexts-manager)
    * Very cool, and promising, but unfortunately too alpha for this case
    * Doesn't really give me the snap like experience I would want
    * Not clear how I would configure k3s after installation, like where files go and if they are mutable
* NixOS based k3s... maybe installed not on NixOS:
    * [arion](https://docs.hercules-ci.com/arion/), or [extra-container](https://github.com/erikarvstedt/extra-container) or [flake-containers](https://github.com/adfaure/flake-containers) offer solutions to run NixOS services/modules on non Nix systems.
    * Unfortunately, Nix is a pain to use, and doesn't offer enough benefits that k8s don't give me.

So yeah. `curl | bash` it is. 

I am mostly keeping everything from the previous installation. There are some things I want to change and expand on, 


## Monitoring

Prometheus, Loki, Grafana.


## Wazuh

Wazuh is an Endpoint Detection and Response system, which is essentially
