---
title: "Server Part 5 — Ovirt is still maintained?!"
description: "But wait... LXC now supports OIDC?"
date: "2024-9-12"
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

I'm currently deciding between kanidm and authentik.


[Here is an authentik on kubernetes with fluxcd guide I foudn](https://www.reddit.com/r/selfhosted/comments/wre8ua/authentiktraefikk8sfluxcd_because_documentation/).

# Testing Incus

So, Incus is only packaged in [Debian backports](https://backports.debian.org/Instructions/). The first step is to add those. After that, `apt update`, `apt upgrade` and `apt install incus-tools incus incus-agent incus-client`.

Then, to initialize incus, [first steps documentation](https://linuxcontainers.org/incus/docs/main/tutorial/first_steps/). 


# RKE2 Try 2

I uninstalled RKE2, but I want to redeploy my services on it again.  

[Quick start guide](https://docs.rke2.io/install/quickstart)

`curl -sfL https://get.rke2.io | sudo sh -` (for some reason it crashed and didn't start when I ran it in a root machinectl session)

I then copied over `/etc/rancher/rke2/rke2.yaml` to `~/.kube/config` on my local machine, in order to configure kubernetes from my local machine.

## Fluxcd

Now, I also realized that git can work over ssh. So I have a git repo, called `fleet-charts`, located on my server, which I will access from my laptop via ssh.

```{.default}
[moonpie@lizard vscode]$ flux bootstrap git --url ssh://moonpie@moonpiedumpl.ing/fleet-charts --branch=main --private-key-file=/home/moonpie/.ssh/moonstack
► cloning branch "main" from Git repository "ssh://moonpie@moonpiedumpl.ing/fleet-charts"
⚠️  clone failure: unable to clone: repository not found: git repository: 'ssh://moonpie@moonpiedumpl.ing/fleet-charts'
⚠️  clone failure: unable to clone: repository not found: git repository: 'ssh://moonpie@moonpiedumpl.ing/fleet-charts'
✗ failed to clone repository: unable to clone: repository not found: git repository: 'ssh://moonpie@moonpiedumpl.ing/fleet-charts
```

I find this odd, because ssh works normally:

```{.default}
[moonpie@lizard vscode]$ ssh moonpie@moonpiedumpl.ing -i /home/moonpie/.ssh/moonstack

moonpie@thoth:~$
```


```{.default}
[moonpie@lizard vscode]$ flux bootstrap git --url ssh://moonpie@moonpiedumpl.ing:22/home/moonpie/fleet-charts --branch=main --private-key-file=/home/moonpie/.ssh/moonstack --verbose
► cloning branch "main" from Git repository "ssh://moonpie@moonpiedumpl.ing:22/home/moonpie/fleet-charts"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed component manifests to "main" ("a69831db70bea88e9ebc9810b78a33831929793c")
► pushing component manifests to "ssh://moonpie@moonpiedumpl.ing:22/home/moonpie/fleet-charts"
► installing components in "flux-system" namespace
```

So it looks like I must use an absolute path, and cannot use "~" for relative patths. Or maybe I can use the `$HOME` environment variable.

But I actually don't like this setup. I [uninstalled flux](), and I want to redeploy it, but wish ssh on a different port instead. I want port 22 on this server to be availble for the forgejo ssh service, rather than to be a the administrative ssh service. I'm going to change ssh to port `22022` in order to avoid conflicts with other services.

<details><summary>Show install command</summary>

```{.default}
[moonpie@lizard vscode]$ flux bootstrap git --url ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/fleet-charts --branch=main --private-key-file=/home/moonpie/.ssh/moonstack --verbose
► cloning branch "main" from Git repository "ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/fleet-charts"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ component manifests are up to date
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCelSERwSNpguy4f2oqrpkPgtq3MT7iKY7fVnofpp72hqdfLH4Z0i34HFy8vXKPL1aKd07HNiMFPujG8E/lE/pb3W5sSNkJPh//YZRz2SlZo7Mh2tkBDLe3Ap8GQgJk/jJHMoCS7YQudT4rAi/vNBuHvMBaFCjXBLqwbaoRBxm5t7hiNFi1I9cSdrIP8v6fubv2VbWV72kiwq/IQeJkURFN9UZJFQ6/Dd6os4ZZg3IEY+EVCpkOyi8d8KnS8fnd8vMk/96jl8mBqRk8ZCsBu6qRbs3HfT6FqCuIgIblxixhrpVmJRJ8cJzMGT5I8deuTPZQ4gPNYYNdxkHW8oztISx0Jql15LtgeJi1iQMwj3ZqIEXPxbgWYZc57jodGvdo7PQTAa3PXOopIJrbmQNi6T2OLwgjidWDgYs7gDJdmAFv52g8zeRh7HyO83yCC7IC1MXodLd9zJinvyBRg5DAdKQnW7zTbcEDsUSGgEI+LQdShRcShmnBzDtJMs2oQujLOaM=
Please give the key access to your repository: y
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("e3f5512df167ca2bc974428cff0dc17787d713f1")
► pushing sync manifests to "ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/fleet-charts"
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for GitRepository "flux-system/flux-system" to be reconciled
✔ GitRepository reconciled successfully
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
✔ Kustomization reconciled successfully
► confirming components are healthy
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```

</details>

And just like that, fluxcd is installed. 

### Fluxcd Deployment





