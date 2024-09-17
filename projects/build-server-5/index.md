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

## Traefik

The first step of my cluster should be my reverse proxy, as an ingress. This exposes basically all of my services. 

The [flux example of helm page](https://fluxcd.io/flux/use-cases/helm/) actually has an example where they set up helm.

```{.default}
[moonpie@lizard home-manager]$ kubectl version
Client Version: v1.30.2
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
The connection to the server localhost:8080 was refused - did you specify the right host or port?
[moonpie@lizard home-manager]$ git remote -v^C
[moonpie@lizard home-manager]$ flux create source helm traefik --url https://helm.traefik.io/traefik --namespace traefik
✚ generating HelmRepository source
► applying HelmRepository source
✗ namespaces "traefik" not found
[moonpie@lizard home-manager]$ flux create source helm traefik --url https://helm.traefik.io/traefik
✚ generating HelmRepository source
► applying HelmRepository source
✔ source created
◎ waiting for HelmRepository source reconciliation
✔ HelmRepository source reconciliation completed
✔ fetched revision: sha256:48513aa497c9bf46e3053d2aef7e4d184d6df2165389a6024b03f8565fd501e8
[moonpie@lizard home-manager]$ flux create helmrelease my-traefik --chart traefik --source HelmRepository/traefik
✚ generating HelmRelease
► applying HelmRelease
✔ HelmRelease created
◎ waiting for HelmRelease reconciliation
✗ context deadline exceeded
```

Is this a failure? I can't tell?

```{.default}
[moonpie@lizard fleet-charts]$ flux get sources all
NAME                            REVISION                SUSPENDED       READY   MESSAGE
gitrepository/flux-system       main@sha1:e3f5512d      False           True    stored artifact for revision 'main@sha1:e3f5512d'

NAME                    REVISION        SUSPENDED       READY   MESSAGE
helmrepository/traefik  sha256:48513aa4 False           True    stored artifact: revision 'sha256:48513aa4'

NAME                                    REVISION        SUSPENDED       READY   MESSAGE
helmchart/flux-system-my-traefik        31.0.0          False           True    pulled 'traefik' chart with version '31.0.0'

[moonpie@lizard fleet-charts]$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                    READY   STATUS      RESTARTS   AGE
flux-system   helm-controller-76dff45854-pj876                        1/1     Running     0          3d1h
flux-system   kustomize-controller-6bc5d5b96-jzj24                    1/1     Running     0          3d1h
flux-system   my-traefik-5b4fbbd9c8-2rck9                             1/1     Running     0          7m24s
flux-system   notification-controller-7f5cd7fdb8-7db4q                1/1     Running     0          3d1h
flux-system   source-controller-54c89dcbf6-p2gd6                      1/1     Running     0          3d1h
kube-system   cloud-controller-manager-thoth                          1/1     Running     0          3d3h
kube-system   etcd-thoth                                              1/1     Running     0          3d3h
kube-system   helm-install-rke2-canal-hmjrm                           0/1     Completed   0          3d3h
kube-system   helm-install-rke2-coredns-m2jwz                         0/1     Completed   0          3d3h
kube-system   helm-install-rke2-ingress-nginx-cszxd                   0/1     Completed   0          3d3h
kube-system   helm-install-rke2-metrics-server-gkqfd                  0/1     Completed   0          3d3h
kube-system   helm-install-rke2-snapshot-controller-crd-ztz6n         0/1     Completed   0          3d3h
kube-system   helm-install-rke2-snapshot-controller-f2zfz             0/1     Completed   0          3d3h
kube-system   helm-install-rke2-snapshot-validation-webhook-52kj2     0/1     Completed   0          3d3h
kube-system   kube-apiserver-thoth                                    1/1     Running     0          3d3h
kube-system   kube-controller-manager-thoth                           1/1     Running     0          3d3h
kube-system   kube-proxy-thoth                                        1/1     Running     0          3d3h
kube-system   kube-scheduler-thoth                                    1/1     Running     0          3d3h
kube-system   rke2-canal-gb7bx                                        2/2     Running     0          3d3h
kube-system   rke2-coredns-rke2-coredns-6bb85f9dd8-zzqlv              1/1     Running     0          3d3h
kube-system   rke2-coredns-rke2-coredns-autoscaler-7b9c797d64-4bwcb   1/1     Running     0          3d3h
kube-system   rke2-ingress-nginx-controller-ct4mj                     1/1     Running     0          3d3h
kube-system   rke2-metrics-server-868fc8795f-5t6v6                    1/1     Running     0          3d3h
kube-system   rke2-snapshot-controller-7dcf5d5b46-5dtvt               1/1     Running     0          3d3h
kube-system   rke2-snapshot-validation-webhook-bf7bbd6fc-gqqgr        1/1     Running     0          3d3h
[moonpie@lizard fleet-charts]$ git pull
Already up to date.
[moonpie@lizard fleet-charts]$
```

Another weird thing is that no changes were made to the git repo where I was tracking flux... but changes were made to my cluster. I thought the point of flux was that all state was in the git repo, but that doesn't seem to be the case here. 

Oh. Oops. RKE2 comes with an nginx controller already. I may have to remove that if I want traefik as an ingress controller. 

[Thankfully, it doesn't appear to be too hard](https://docs.rke2.io/helm?_highlight=uninstall#disabling-addons). 

```{.yaml filename='/etc/rancher/rke2/config.yaml'}
disable:
  - rke2-coredns
  - rke2-ingress-nginx
```

And now, those services are disabled.

Oh, and I was wrong, there are files in the git repo now.

```{.default}
[moonpie@lizard fleet-charts]$ ls *
begin.md

flux-system:
gotk-components.yaml  gotk-sync.yaml  kustomization.yaml
```

```{.default}
[moonpie@lizard flux-system]$ wc -l *
 12385 gotk-components.yaml
    27 gotk-sync.yaml
     5 kustomization.yaml
 12417 total
```

Uuuh... That's a lot of lines. I think that `gotk-components.yaml` file has basically all of the fluxcd components stored and tracked in there. 

```{.default}
[moonpie@lizard flux-system]$ cat * | grep traefik
[moonpie@lizard flux-system]$
```

And... no mentions of traefik? It's obviously stored in the cluster, given something related shows up when I observe the kubernetes pods, but nothing appears in the git repo.

```{.default}
[moonpie@lizard flux-system]$ flux get sources all -A
NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE                                                                                       
flux-system     gitrepository/flux-system       main@sha1:e3f5512d      False           False   failed to checkout and determine revision: unable to list remote for 'ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/fleet-charts': dial tcp: lookup moonpiedumpl.ing on 10.43.0.10:53: read udp 10.42.0.22:38747->10.43.0.10:53: i/o timeout
```

Okay, it appears that flux is having trouble accessing my git repo. I found a [relevant github issue](https://github.com/fluxcd/flux2/issues/4673), and it looks like a DNS problem. It looks, since I disabled the Kubernetes CoreDNS service, DNS wasn't working inside my cluster, preventing it from accessing my domain name. 

So:

```{.yaml filename='/etc/rancher/rke2/config.yaml'}
disable:
  # Yeah so apparently this was kind of important. 
  # - rke2-coredns
  - rke2-ingress-nginx
```

And with this, flux bootstrap works properly:

```{.default}
[moonpie@lizard vscode]$ flux bootstrap git --url ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/flux-config --branch=main --private-key-file=/home/moonpie/.ssh/moonstack --verbose --insecure-skip-tls-verify
► cloning branch "main" from Git repository "ssh://moonpie@moonpiedumpl.ing:22022/home/moonpie/flux-config"
✔ cloned repository
...
...
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

I also changed the name of the git repo to `flux-config`.

I also realized that the `flux-system` repo is the configs of the flux-system namespace. Meaning, each directory *should* be a namespace? However, I don't think I'm going to use many namespaces, they seem like extra complexity designed for multi-project or multi-user kubernetes clusters. 

```{.default}
[moonpie@lizard vscode]$ flux create source helm traefik --url https://helm.traefik.io/traefik
✚ generating HelmRepository source
► applying HelmRepository source
✔ source created
◎ waiting for HelmRepository source reconciliation
✔ HelmRepository source reconciliation completed
✔ fetched revision: sha256:48513aa497c9bf46e3053d2aef7e4d184d6df2165389a6024b03f8565fd501e8


Events:                       <none>
[moonpie@lizard flux-config]$ flux create helmrelease traefik --chart traefik --source HelmRepository/traefik --chart-version 31.0.0 --verbose
✚ generating HelmRelease
► applying HelmRelease
✔ HelmRelease updated
◎ waiting for HelmRelease reconciliation
^C
```

Despite my impatience, it did render, and Traefik did deploy. 

```{.default}
[moonpie@lizard flux-system]$ kubectl get pods -n flux-system
NAME                                       READY   STATUS    RESTARTS   AGE
helm-controller-76dff45854-g8tff           1/1     Running   0          3h4m
kustomize-controller-6bc5d5b96-sdzql       1/1     Running   0          3h4m
notification-controller-7f5cd7fdb8-v9672   1/1     Running   0          3h4m
source-controller-54c89dcbf6-kjjsb         1/1     Running   0          3h4m
traefik-6f6c897d6-j7g8z                    1/1     Running   0          9m34s
```

But... no changes were made to the git repo? I'm confused, as I thought the point of flux was that all changes would be version controlled.  
