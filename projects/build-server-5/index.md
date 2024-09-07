---
title: "Server Part 5 — Ovirt is still maintained?!"
date: "2024-9-1"
categories: [linux, _projects]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

# Background & Goals

Since I got literally no work done on my server, I think it would be prudent to scale down. Rather than opting for a larger option.

In the order I want, here are concrete goals:

-   Syncthing: (I need this in order to sync files between my two laptops)
-   Oauth2/Openid/Ldap (Kanidm or Authentik)
    -   I might switch to [Kanidm](https://kanidm.com/) from authentik as my authentication server, as it seems a lot simpler... but it doesn't seem to support invites
-   Virtual Machine host with a web UI that I can give out to others. I'm currently looking at Incus or Ovirt.

I recently learned that [Ovirt](https://www.ovirt.org/) was still maintained, and it seems to be feature complete. It contains every feature I want, like oauth2 authentication, port security, and a web UI. Although, due to Red Hat abandoning the project, it likely wont' get beyond feature updates, and instead just get bug and security updates, the software does what I want it to do.

# Software Selection

## Virtual Machine Manager

Incus:
* [Authentication]()
  - Openid connection
* [Authorization](https://linuxcontainers.org/incus/docs/main/authorization/)
  - Openfga authorization
  - Do I have to create a project for each user? (seems to be no... [Incus can be configured to dynamically create projects for all users in a specific user group](https://linuxcontainers.org/incus/docs/main/howto/projects_confine/#confine-projects-to-specific-incus-users))
  - What is the difference between the varios levels of authority
* [Port security](https://linuxcontainers.org/incus/docs/main/explanation/security/#network-security)
  - Can be overrided on a per instance basis... but how can I make this an unchangable default? 


## Authentication

