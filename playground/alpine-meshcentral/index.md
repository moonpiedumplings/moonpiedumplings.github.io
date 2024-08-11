---
title: "Work on Alpine Linux"
date: "2024-8-3"
categories: [linux]
draft: true
author: Jeffrey Fonseca
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---


# Inject 001 (7/20/2024) — Meshcentral Installation

Alpine does not have Meshcentral in it's package repositories, and although I can use docker, I am choosing not to for the purposes of this exercise. 

According to the [official install instructions](https://ylianst.github.io/MeshCentral/install/install2/#installing-nodejs_1) for MeshCentral on the Rasperry Pi, a more unorthodox setup, it works by using nodejs and npom to install Meshcentral from there, and then runs it directly using node. It then creates a custom systemd service. I will need to do a similar setup on Alpine. 

Getting npm, the node package manager, was not an instant process because node is not packaged in the official main repo for Alpine Linux, but it's rather only in the community repos for Alpine Linux. Following the [Alpine Wiki's insturctions](https://wiki.alpinelinux.org/wiki/Repositories)

```{.default filename='/etc/apk/repositories'}
#/media/cdrom/apks
http://dl-cdn.alpinelinux.org/alpine/v3.2/main
http://dl-cdn.alpinelinux.org/alpine/v3.2/community
```

After this, I can run `apk add npm`. I can then continue the steps from the rasperry pi installation of Meshcentral... mostly.

```{.default}

mkdir meshcentral

cd meshcentral

node node_modules/meshcentral --lanonly --fastcert
```

This starts a simple, lan only meshcentral server. However, I neeed to set it up to automatically start on boot. Unlike Raspian, the default OS of the Rasperry Pi, Alpine Linux does not come with systemd, meaning those steps don't work for setup. 

Alpine Linux uses OpenRC instead, meaning I need to have to create a service file for that instead. 

```{filename='/etc/init.d/meshcentral}
#!/sbin/openrc-run

command="/usr/bin/node"
command_background=true
pidfile="/run/meshcentral.pid"
command_args="/root/meshcentral/node_modules/meshcentral --lanonly --fastcert"
```

This file is symlinked to `/etc/runlevels/default/meshcentral`, which causes openrc to start it on boot, and in the background. 

Further configuration can be done, but this is a basic deployment. 


# Inject 002 (8/3/2024) — Wazuh deployment

The [wazuh deployment guide](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-linux.html) also offers an alpine repo and packages. However, these instructions are broken if an older version of wazuh is used. 

```{.default}
curl -o wazuh-agent.apk https://packages.wazuh.com/4.x/alpine/v3.12/main/x86_64/wazuh-agent-4.7.3-r1.apk

apk add ./wazuh-agent.apk --allow-untrusted
```

Then, `/var/ossec/etc/ossec.conf` must be edited with the proper settings. 

```{.xml filename='/var/ossec/etc/ossec.conf'}
<ossec_config>
  <client>
    <server>
      <address>10.20.5.70</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <enrollment>
        <agent_name>meshcentral-alpine</agent_name>
        <groups>Development</groups>
    </enrollment>
    <config-profile>alpine, alpine3, alpine3.20</config-profile>
    <notify_time>10</notify_time>
    <time-reconnect>60</time-reconnect>
    <auto_restart>yes</auto_restart>
    <crypto_method>aes</crypto_method>
  </client>
```

After this, wazuh can be started as root with two commands:


```{.default}
 /var/ossec/bin/wazuh-control start

/var/ossec/bin/wazuh-agentd -u root -g root
```

The second is because wazuh does not properly run under the `wazuh` user and group. 