---
title: "Eaglercraft with some special stuff"
date: "2024-9-12"
categories: [linux, _playground]
draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---


# What is Eaglercraft?

<https://eaglercraft.com/>

Source code: <https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8>

Eaglercraft is an open source Minecraft 1.8.8 client —


# Deploying Eaglercraft server

<https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8#making-a-server>

https://github.com/itzg/docker-mc-proxy


To make the process of setting this up easier, I've decided to use [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) with a docker compose.

```{.yaml filename='docker-compose.yml'}
services:
  mc:
    image: docker.io/itzg/minecraft-server
    ports:
      - 25565:25565
    environment:
      EULA: "TRUE"
      TYPE: "PAPER"
      VERSION: "1.8.8"
    tty: true
    stdin_open: true
    restart: unless-stopped
    volumes:
      # attach a directory relative to the directory containing this compose file
      - ./minecraft-data:/data
      - ./plugins:/plugins
  proxy:
    image: itzg/mc-proxy
    environment:
      BUNGEE_JAR_REVISION: "1"
      CFG_MOTD: Powered by Docker
      REPLACE_ENV_VARIABLES: "true"
    ports:
      - "25565:25577"
    volumes:
      - ./config.yml:/config/config.yml
      - proxy-data:/server
```

Then, download these files to `./plugins`

<https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8/src/branch/main/gateway/EaglercraftXBungee/EaglerXBungee-Latest.jar>


https://github.com/Electroid/SportPaper/issues/58   

<https://www.spigotmc.org/threads/unable-to-access-address-of-buffer.311602/>

<https://docs.papermc.io/paper/reference/server-properties>


```{.yaml}
version: "3"
services:
  mc:
    image: docker.io/itzg/minecraft-server
    # ports:
    #   - 25565:25565
    environment:
      EULA: "TRUE"
      TYPE: "PAPER"
      VERSION: "1.8.8"
      ONLINE_MODE: "FALSE"
      USE_NATIVE_TRANSPORT: "FALSE"
    network_mode: host
    tty: true
    stdin_open: true
    restart: unless-stopped
    volumes:
      # attach a directory relative to the directory containing this compose file
      - ./minecraft-data:/data
      - ./plugins:/plugins
  proxy:
    image: docker.io/itzg/mc-proxy
    environment:
      TYPE: "BUNGEECORD"
      BUNGEE_BUILD_ID: "1878"
      # BUNGEE_JAR_REVISION: "1"
      CFG_MOTD: Powered by Docker
      REPLACE_ENV_VARIABLES: "true"
      # PLUGINS: "https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8/raw/branch/main/gateway/EaglercraftXBungee/EaglerXBungee-Latest.jar"
      PLUGINS: "https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8/raw/commit/6a0a90f4ac7ff617e139de85aa928333845cb5d7/gateway/EaglercraftXBungee/EaglerXBungee-Latest.jar"
    network_mode: host
    # ports:
    #   # - "25565:25577"
    #   - "25577:25577"
    volumes:
      #- ./config.yml:/config/config.yml
      - ./proxy-data:/server

```


https://artifacthub.io/packages/helm/minecraft-server-charts/minecraft

https://github.com/itzg/minecraft-server-charts/tree/master/charts/minecraft

https://github.com/itzg/minecraft-server-charts/blob/master/charts/minecraft-proxy/


# Deploying Eaglercraft Client

Now, this part isn't necessary since you can use the main website.