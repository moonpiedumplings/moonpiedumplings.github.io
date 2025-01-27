---
title: "Eaglercraft via docker-compose"
date: "2024-11-20"
categories: [guides]
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

Eaglercraft is an open source Minecraft 1.8.8 client. It works by using TeaVM, a precompiler for Java that outputs Javascript and Webassembly. 



# Deploying Eaglercraft server

<https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8#making-a-server>


Here is a docker-compose you can use to put eaglercraft up:

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

After you put this server up, you first need to connect via a vanilla account and link the account, or you can disable authentication according to the steps in the [eaglercraft documentation](https://git.eaglercraft.rip/eaglercraft/eaglercraft-1.8/src/branch/main/README_EAGLERXBUNGEE.md#authserviceyml).