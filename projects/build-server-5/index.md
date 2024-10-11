---
title: "Server Part 5 — Ovirt is still maintained?!"
description: "But wait... LXC now supports OIDC? But this post is mostly kubernetes"
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

## Reverse Proxy (Traefik, then Nginx)

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

I started to follow the [flux troubleshooting guide](). 


```{.default}
[moonpie@lizard moonpiedumplings.github.io]$ kubectl describe helmrelease traefik -n flux-system
Name:         traefik
Namespace:    flux-system
...
...
Status:
  Conditions:
    Last Transition Time:  2024-09-17T20:16:28Z
    Message:               Failed to install after 1 attempt(s)
    Observed Generation:   1
    Reason:                RetriesExceeded
    Status:                True
    Type:                  Stalled
    Last Transition Time:  2024-09-17T20:16:28Z
    Message:               Helm install failed for release flux-system/traefik with chart traefik@31.0.0: client rate limiter Wait returned an error: context deadline
...
...
2024-09-17T20:11:27.315654788Z: CustomResourceDefinition serverstransporttcps.traefik.io is already present. Skipping.
2024-09-17T20:11:27.315658603Z: creating 1 resource(s)
2024-09-17T20:11:27.324448937Z: CustomResourceDefinition tlsoptions.traefik.io is already present. Skipping.
2024-09-17T20:11:27.324452859Z: creating 1 resource(s)
2024-09-17T20:11:27.332385521Z: CustomResourceDefinition tlsstores.traefik.io is already present. Skipping.
2024-09-17T20:11:27.332389484Z: creating 1 resource(s)
2024-09-17T20:11:27.348449663Z: CustomResourceDefinition traefikservices.traefik.io is already present. Skipping.
2024-09-17T20:11:27.85810682Z: creating 6 resource(s)
2024-09-17T20:11:27.904853344Z: beginning wait for 6 resources with timeout of 5m0s
2024-09-17T20:11:27.909519301Z: Service does not have load balancer ingress IP address: flux-system/traefik
2024-09-17T20:16:25.90942954Z:  : flux-system/traefik (148 duplicate lines omitted)
```

So it seems I'm missing a "load balancer ingress IP address". 

I also find it odd that the relevant configs are not automatically added to the git repo. I decided to experiment with adding files to the git repo, rather than using the flux cli. 

```{.default}
[moonpie@lizard flux-config]$ ls traefik/
config.yaml  source.yaml
```

```{.default}
[moonpie@lizard traefik]$ cat config.yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: traefik
  namespace: flux-system
spec:
  chart:
    spec:
      chart: traefik
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: traefik
      version: 31.0.0
  interval: 1m0s
  values:
    service:
        type: LoadBalancer
[moonpie@lizard traefik]$ cat source.yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 1m0s
  url: https://traefik.github.io/charts/
```

This actually deploys properly without errors, so it seems that the flux git repo organization is arbitrary and for the purposes of maknig it readable for humans, and is not actually necessary. 

It probably doesn't error because I have the `service: type: LoadBalancer`, but it doesn't actually use any ports or seem to be deployed in a useful manner.

Also:

```{.default}
[moonpie@lizard traefik]$ kubectl get -n flux-system service
NAMESPACE     NAME                               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
default       kubernetes                         ClusterIP      10.43.0.1       <none>        443/TCP                      6d20h
flux-system   notification-controller            ClusterIP      10.43.164.182   <none>        80/TCP                       2d14h
flux-system   source-controller                  ClusterIP      10.43.58.240    <none>        80/TCP                       2d14h
flux-system   traefik                            LoadBalancer   10.43.109.84    <pending>     80:30239/TCP,443:31645/TCP   18h
flux-system   webhook-receiver                   ClusterIP      10.43.226.89    <none>        80/TCP                       2d14h
```

It seems that traefik comes with a load balancer type service, but it doesn't actually get an external ip. Why?


After more research, it seems that a load balancer is actually needed in order to use a load balancer type service. On cloud instances, the cloud server acts as a load balancer and can do this. On bare metal instances, users are on their own. The most common deployment for a bare metal load balancer seems to be [metallb](https://metallb.io/), but that doesn't really work for me, as I only have ONE ip address and it looks like metallb expects you to be able to ask for more on the spot somehow. 

(well... technically, I can use dhcp to ask for more ip addresses, but it doesn't look like metallb supports that use case, only something different)

Instead, I found [klipper](https://docs.k3s.io/networking/networking-services?_highlight=ingress#service-load-balancer). Klipper is an *extremely* simple load balancing service built into K3s — but disabled in RKE2 by default. All it does is use iptables/nftables to forward traffic from ports you want the load balancer to forward from, to inside the cluster. 

[RKE2 can deply klipper by using an install flag](https://docs.rke2.io/networking/networking_services?_highlight=load#service-load-balancer)... and it seems, **only** via an install flag. There doesn't seem to be another way to install klipper, no helm charts or anything... it seems to just be a bash script in a docker container. 

So, it looks like I need to uninstall my cluster and redeploy it...

```{.default}
curl -sfL https://get.rke2.io --output install.sh
chmod +x install.sh

./install.sh --serviceLB # with root privileges
```

But, after I reinstalled flux:

```{.default}
[moonpie@lizard traefik]$ flux get all -n flux-system
NAME                            REVISION                SUSPENDED       READY   MESSAGE
gitrepository/flux-system       main@sha1:819432fd      False           True    stored artifact for revision 'main@sha1:819432fd'

NAME                    REVISION        SUSPENDED       READY   MESSAGE
helmrepository/traefik  sha256:1c0fc56c False           True    stored artifact: revision 'sha256:1c0fc56c'

NAME                            REVISION        SUSPENDED       READY   MESSAGE
helmchart/flux-system-traefik   31.0.0          False           True    pulled 'traefik' chart with version '31.0.0'

NAME                    REVISION        SUSPENDED       READY   MESSAGE

helmrelease/traefik     31.0.0          False           False   Helm install failed for release flux-system/traefik with chart traefik@31.0.0: Unable to continue with install: Service "traefik" in namespace "flux-system" exists and cannot be imported into the current release: invalid ownership metadata; label validation error: missing key "app.kubernetes.io/managed-by": must be set to "Helm"; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "traefik"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "flux-system"

NAME                            REVISION                SUSPENDED       READY   MESSAGE
kustomization/flux-system       main@sha1:819432fd      False           True    Applied revision: main@sha1:819432fd
```

```{.default}
root@thoth:/usr/local/bin# ls
rke2  rke2-killall.sh  rke2-uninstall.sh
root@thoth:/usr/local/bin# rke2
rke2               rke2-killall.sh    rke2-uninstall.sh
root@thoth:/usr/local/bin# rke2
rke2               rke2-killall.sh    rke2-uninstall.sh
root@thoth:/usr/local/bin# rke2 server --help
NAME:
   rke2 server - Run management server

USAGE:
   rke2 server [OPTIONS]

OPTIONS:
   --config FILE, -c FILE                        (config) Load configuration from FILE (default: "/etc/rancher/rke2/config.yaml") [$RKE2_CONFIG_FILE]
   --debug                                       (logging) Turn on debug logs [$RKE2_DEBUG]
   --bind-address value                          (listener) rke2 bind address (default: 0.0.0.0)
   --advertise-address value                     (listener) IPv4/IPv6 address that apiserver uses to advertise to members of the cluster (default: node-external-ip/node-ip)
   --tls-san value                               (listener) Add additional hostnames or IPv4/IPv6 addresses as Subject Alternative Names on the server TLS cert
   --tls-san-security                            (listener) Protect the server TLS cert by refusing to add Subject Alternative Names not associated with the kubernetes apiserver service, s
   --data-dir value, -d value                    (data) Folder to hold state (default: "/var/lib/rancher/rke2") [$RKE2_DATA_DIR]
   --cluster-cidr value                          (networking) IPv4/IPv6 network CIDRs to use for pod IPs (default: 10.42.0.0/16)
   --service-cidr value                          (networking) IPv4/IPv6 network CIDRs to use for service IPs (default: 10.43.0.0/16)
   --service-node-port-range value               (networking) Port range to reserve for services with NodePort visibility (default: "30000-32767")
   --cluster-dns value                           (networking) IPv4 Cluster IP for coredns service. Should be in your service-cidr range (default: 10.43.0.10)
   --cluster-domain value                        (networking) Cluster Domain (default: "cluster.local")
   --egress-selector-mode value                  (networking) One of 'agent', 'cluster', 'pod', 'disabled' (default: "agent")
   --servicelb-namespace value                   (networking) Namespace of the pods for the servicelb component (default: "kube-system")
   --write-kubeconfig value, -o value            (client) Write kubeconfig for admin client to this file [$RKE2_KUBECONFIG_OUTPUT]
   --write-kubeconfig-mode value                 (client) Write kubeconfig with this mode [$RKE2_KUBECONFIG_MODE]
   --write-kubeconfig-group value                (client) Write kubeconfig with this group [$RKE2_KUBECONFIG_GROUP]
   --helm-job-image value                        (helm) Default image to use for helm jobs
   --token value, -t value                       (cluster) Shared secret used to join a server or agent to a cluster [$RKE2_TOKEN]
   --token-file value                            (cluster) File containing the token [$RKE2_TOKEN_FILE]
   --agent-token value                           (cluster) Shared secret used to join agents to the cluster, but not servers [$RKE2_AGENT_TOKEN]
   --agent-token-file value                      (cluster) File containing the agent secret [$RKE2_AGENT_TOKEN_FILE]
   --server value, -s value                      (cluster) Server to connect to, used to join a cluster [$RKE2_URL]
   --cluster-reset                               (cluster) Forget all peers and become sole member of a new cluster [$RKE2_CLUSTER_RESET]
   --cluster-reset-restore-path value            (db) Path to snapshot file to be restored
   --kube-apiserver-arg value                    (flags) Customized flag for kube-apiserver process
   --etcd-arg value                              (flags) Customized flag for etcd process
   --kube-controller-manager-arg value           (flags) Customized flag for kube-controller-manager process
   --kube-scheduler-arg value                    (flags) Customized flag for kube-scheduler process
   --kube-cloud-controller-manager-arg value     (flags) Customized flag for kube-cloud-controller-manager process
   --datastore-endpoint value                    (db) Specify etcd, NATS, MySQL, Postgres, or SQLite (default) data source name [$RKE2_DATASTORE_ENDPOINT]
   --datastore-cafile value                      (db) TLS Certificate Authority file used to secure datastore backend communication [$RKE2_DATASTORE_CAFILE]
   --datastore-certfile value                    (db) TLS certification file used to secure datastore backend communication [$RKE2_DATASTORE_CERTFILE]
   --datastore-keyfile value                     (db) TLS key file used to secure datastore backend communication [$RKE2_DATASTORE_KEYFILE]
   --etcd-expose-metrics                         (db) Expose etcd metrics to client interface. (default: false)
   --etcd-disable-snapshots                      (db) Disable automatic etcd snapshots
   --etcd-snapshot-name value                    (db) Set the base name of etcd snapshots (default: etcd-snapshot-<unix-timestamp>) (default: "etcd-snapshot")
   --etcd-snapshot-schedule-cron value           (db) Snapshot interval time in cron spec. eg. every 5 hours '0 */5 * * *' (default: "0 */12 * * *")
   --etcd-snapshot-retention value               (db) Number of snapshots to retain (default: 5)
   --etcd-snapshot-dir value                     (db) Directory to save db snapshots. (default: ${data-dir}/db/snapshots)
   --etcd-snapshot-compress                      (db) Compress etcd snapshot
   --etcd-s3                                     (db) Enable backup to S3
   --etcd-s3-endpoint value                      (db) S3 endpoint url (default: "s3.amazonaws.com")
   --etcd-s3-endpoint-ca value                   (db) S3 custom CA cert to connect to S3 endpoint
   --etcd-s3-skip-ssl-verify                     (db) Disables S3 SSL certificate validation
   --etcd-s3-access-key value                    (db) S3 access key [$AWS_ACCESS_KEY_ID]
   --etcd-s3-secret-key value                    (db) S3 secret key [$AWS_SECRET_ACCESS_KEY]
   --etcd-s3-bucket value                        (db) S3 bucket name
   --etcd-s3-region value                        (db) S3 region / bucket location (optional) (default: "us-east-1")
   --etcd-s3-folder value                        (db) S3 folder
   --etcd-s3-proxy value                         (db) Proxy server to use when connecting to S3, overriding any proxy-releated environment variables
   --etcd-s3-config-secret value                 (db) Name of secret in the kube-system namespace used to configure S3, if etcd-s3 is enabled and no other etcd-s3 options are set
   --etcd-s3-insecure                            (db) Disables S3 over HTTPS
   --etcd-s3-timeout value                       (db) S3 timeout (default: 5m0s)
   --disable value                               (components) Do not deploy packaged components and delete any deployed components (valid items: rke2-coredns, rke2-metrics-server, rke2-sna
   --disable-scheduler                           (components) Disable Kubernetes default scheduler
   --disable-cloud-controller                    (components) Disable rke2 default cloud controller manager
   --disable-kube-proxy                          (components) Disable running kube-proxy
   --embedded-registry                           (experimental/components) Enable embedded distributed container registry; requires use of embedded containerd; when enabled agents will als
   --supervisor-metrics                          (experimental/components) Enable serving rke2 internal metrics on the supervisor port; when enabled agents will also listen on the supervis
   --node-name value                             (agent/node) Node name [$RKE2_NODE_NAME]
   --with-node-id                                (agent/node) Append id to node name
   --node-label value                            (agent/node) Registering and starting kubelet with set of labels
   --node-taint value                            (agent/node) Registering kubelet with set of taints
   --image-credential-provider-bin-dir value     (agent/node) The path to the directory where credential provider plugin binaries are located (default: "/var/lib/rancher/credentialprovider
   --image-credential-provider-config value      (agent/node) The path to the credential provider plugin config file (default: "/var/lib/rancher/credentialprovider/config.yaml")
   --container-runtime-endpoint value            (agent/runtime) Disable embedded containerd and use the CRI socket at the given path; when used with --docker this sets the docker socket p
   --default-runtime value                       (agent/runtime) Set the default runtime in containerd
   --disable-default-registry-endpoint           (agent/containerd) Disables containerd's fallback default registry endpoint when a mirror is configured for that registry
   --snapshotter value                           (agent/runtime) Override default containerd snapshotter (default: "overlayfs")
   --private-registry value                      (agent/runtime) Private registry configuration file (default: "/etc/rancher/rke2/registries.yaml")
   --system-default-registry value               (agent/runtime) Private registry to be used for all system images [$RKE2_SYSTEM_DEFAULT_REGISTRY]
   --node-ip value, -i value                     (agent/networking) IPv4/IPv6 addresses to advertise for node
   --node-external-ip value                      (agent/networking) IPv4/IPv6 external IP addresses to advertise for node
   --resolv-conf value                           (agent/networking) Kubelet resolv.conf file [$RKE2_RESOLV_CONF]
   --kubelet-arg value                           (agent/flags) Customized flag for kubelet process
   --kube-proxy-arg value                        (agent/flags) Customized flag for kube-proxy process
   --protect-kernel-defaults                     (agent/node) Kernel tuning behavior. If set, error if kernel tunables are different than kubelet defaults.
   --enable-pprof                                (experimental) Enable pprof endpoint on supervisor port
   --selinux                                     (agent/node) Enable SELinux in containerd [$RKE2_SELINUX]
   --lb-server-port value                        (agent/node) Local port for supervisor client load-balancer. If the supervisor and apiserver are not colocated an additional port 1 less than this port will also be used for the apiserver client load-balancer. (default: 6444) [$RKE2_LB_SERVER_PORT]
   --cni value                                   (networking) CNI Plugins to deploy, one of none, calico, canal, cilium, flannel; optionally with multus as the first value to enable the multus meta-plugin (default: canal) [$RKE2_CNI]
   --ingress-controller value                    (networking) Ingress Controllers to deploy, one of none, ingress-nginx, traefik; the first value will be set as the default ingress class (default: ingress-nginx) [$RKE_INGRESS_CONTROLLER]
   --enable-servicelb                            (components) Enable rke2 default cloud controller manager's service controller [$RKE2_ENABLE_SERVICELB]
   --kube-apiserver-image value                  (image) Override image to use for kube-apiserver [$RKE2_KUBE_APISERVER_IMAGE]
   --kube-controller-manager-image value         (image) Override image to use for kube-controller-manager [$RKE2_KUBE_CONTROLLER_MANAGER_IMAGE]
   --cloud-controller-manager-image value        (image) Override image to use for cloud-controller-manager [$RKE2_CLOUD_CONTROLLER_MANAGER_IMAGE]
   --kube-proxy-image value                      (image) Override image to use for kube-proxy [$RKE2_KUBE_PROXY_IMAGE]
   --kube-scheduler-image value                  (image) Override image to use for kube-scheduler [$RKE2_KUBE_SCHEDULER_IMAGE]
   --pause-image value                           (image) Override image to use for pause [$RKE2_PAUSE_IMAGE]
   --runtime-image value                         (image) Override image to use for runtime binaries (containerd, kubectl, crictl, etc) [$RKE2_RUNTIME_IMAGE]
   --etcd-image value                            (image) Override image to use for etcd [$RKE2_ETCD_IMAGE]
   --kubelet-path value                          (experimental/agent) Override kubelet binary path [$RKE2_KUBELET_PATH]
   --cloud-provider-name value                   (cloud provider) Cloud provider name [$RKE2_CLOUD_PROVIDER_NAME]
   --cloud-provider-config value                 (cloud provider) Cloud provider configuration file path [$RKE2_CLOUD_PROVIDER_CONFIG]
   --profile value                               (security) Validate system configuration against the selected benchmark (valid items: cis) [$RKE2_CIS_PROFILE]
   --audit-policy-file value                     (security) Path to the file that defines the audit policy configuration [$RKE2_AUDIT_POLICY_FILE]
   --pod-security-admission-config-file value    (security) Path to the file that defines Pod Security Admission configuration [$RKE2_POD_SECURITY_ADMISSION_CONFIG_FILE]
   --control-plane-resource-requests value       (components) Control Plane resource requests [$RKE2_CONTROL_PLANE_RESOURCE_REQUESTS]
   --control-plane-resource-limits value         (components) Control Plane resource limits [$RKE2_CONTROL_PLANE_RESOURCE_LIMITS]
   --control-plane-probe-configuration value     (components) Control Plane Probe configuration [$RKE2_CONTROL_PLANE_PROBE_CONFIGURATION]
   --kube-apiserver-extra-mount value            (components) kube-apiserver extra volume mounts [$RKE2_KUBE_APISERVER_EXTRA_MOUNT]
   --kube-scheduler-extra-mount value            (components) kube-scheduler extra volume mounts [$RKE2_KUBE_SCHEDULER_EXTRA_MOUNT]
   --kube-controller-manager-extra-mount value   (components) kube-controller-manager extra volume mounts [$RKE2_KUBE_CONTROLLER_MANAGER_EXTRA_MOUNT]
   --kube-proxy-extra-mount value                (components) kube-proxy extra volume mounts [$RKE2_KUBE_PROXY_EXTRA_MOUNT]
   --etcd-extra-mount value                      (components) etcd extra volume mounts [$RKE2_ETCD_EXTRA_MOUNT]
   --cloud-controller-manager-extra-mount value  (components) cloud-controller-manager extra volume mounts [$RKE2_CLOUD_CONTROLLER_MANAGER_EXTRA_MOUNT]
   --kube-apiserver-extra-env value              (components) kube-apiserver extra environment variables [$RKE2_KUBE_APISERVER_EXTRA_ENV]
   --kube-scheduler-extra-env value              (components) kube-scheduler extra environment variables [$RKE2_KUBE_SCHEDULER_EXTRA_ENV]
   --kube-controller-manager-extra-env value     (components) kube-controller-manager extra environment variables [$RKE2_KUBE_CONTROLLER_MANAGER_EXTRA_ENV]
   --kube-proxy-extra-env value                  (components) kube-proxy extra environment variables [$RKE2_KUBE_PROXY_EXTRA_ENV]
   --etcd-extra-env value                        (components) etcd extra environment variables [$RKE2_ETCD_EXTRA_ENV]
   --cloud-controller-manager-extra-env value    (components) cloud-controller-manager extra environment variables [$RKE2_CLOUD_CONTROLLER_MANAGER_EXTRA_ENV]
```

So, it seems that the --servicelb system is enabled in the rke2 command line, rather than in the install script. 

So, I used `systemctl edit rke2-server.service` to create an override file for the systemd service.

```{.default}
### Editing /etc/systemd/system/rke2-server.service.d/override.conf
### Anything between here and the comment below will become the new contents of the file


[Service]
ExecStart=
ExecStart=/usr/local/bin/rke2 server --servicelb

### Lines below this comment will be discarded

### /usr/local/lib/systemd/system/rke2-server.service
# [Unit]
# Description=Rancher Kubernetes Engine v2 (server)
# Documentation=https://github.com/rancher/rke2#readme
# Wants=network-online.target
# After=network-online.target
# Conflicts=rke2-agent.service
#
# [Install]
# WantedBy=multi-user.target
#
# [Service]
# Type=notify
# EnvironmentFile=-/etc/default/%N
# EnvironmentFile=-/etc/sysconfig/%N
# EnvironmentFile=-/usr/local/lib
```

And after restarting the kubernetes service, and reconciling, traefik deploys successfully!

```{.default}
[moonpie@lizard traefik]$ flux get all
NAME                            REVISION                SUSPENDED       READY   MESSAGE
...
...

NAME                    REVISION        SUSPENDED       READY   MESSAGE
helmrelease/traefik     31.0.0          False           True    Helm install succeeded for release flux-system/traefik.v1 with chart traefik@31.0.0

...
...
```

Except... not really. The port 80 and 443 are not used when I check `sudo ss -tulpn`, and if I curl either of those ports, it just times out. A relevant [github issue](https://github.com/k3s-io/klipper-lb/issues/6) says that klipper has some problems with canal, and to enable  [canal ip forwarding](https://docs.tigera.io/calico/latest/reference/configure-cni-plugins#container-settings) in `/etc/cni/net.d/10-canal.conflist`.

However, despite doing this, and restarting, the ports are not in use, and the service times out if I try to curl my site.

But, traefik seems to be working, because if I use the `kubectl port-forward` command to port forward traefik to my local machine, I can curl it.

```{.default}
[moonpie@lizard traefik]$ kubectl port-forward -n flux-system pods/traefik-6f6c897d6-vr78w 8000
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
Handling connection for 8000

# In a different terminal

[moonpie@lizard traefik]$ curl localhost:8000
404 page not found
```

But...

```{.default}
[moonpie@lizard traefik]$ kubectl describe -n flux-system svc/traefik
Name:                     traefik
Namespace:                flux-system
Labels:                   app.kubernetes.io/instance=traefik-flux-system
                          app.kubernetes.io/managed-by=Helm
                          app.kubernetes.io/name=traefik
                          helm.sh/chart=traefik-31.0.0
                          helm.toolkit.fluxcd.io/name=traefik
                          helm.toolkit.fluxcd.io/namespace=flux-system
Annotations:              meta.helm.sh/release-name: traefik
                          meta.helm.sh/release-namespace: flux-system
Selector:                 app.kubernetes.io/instance=traefik-flux-system,app.kubernetes.io/name=traefik
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.249.0
IPs:                      10.43.249.0
LoadBalancer Ingress:     130.166.90.189
Port:                     web  80/TCP
TargetPort:               8000/TCP
NodePort:                 web  30801/TCP
Endpoints:                10.42.0.15:8000
Port:                     websecure  443/TCP
TargetPort:               websecure/TCP
NodePort:                 websecure  32357/TCP
Endpoints:                10.42.0.15:8443
Session Affinity:         None
External Traffic Policy:  Cluster
```

```{.default}
root@thoth:~# curl 10.42.0.15:8000
404 page not found
```

So I'm guessing that this is *supposed* to be forwarded to port 80 on the host, but it isn't.

```{.default}
[moonpie@lizard traefik]$ kubectl get events --sort-by='.lastTimestamp' -A
NAMESPACE     LAST SEEN   TYPE      REASON                    OBJECT                                                         MESSAGE                           
...
...
kube-system   9m43s       Warning   FailedMount               pod/helm-install-rke2-canal-jjmwv                              MountVolume.SetUp failed for volume "content" : object "kube-system"/"chart-content-rke2-canal" not registered
kube-system   5m39s       Warning   FailedMount               pod/helm-install-rke2-canal-jjmwv                              MountVolume.SetUp failed for volume "values" : object "kube-system"/"chart-values-rke2-canal" not registered
...
...
```


Although an interesting error, it's possible that this isn't *the* error that is irritating me. According to a [github issue comment](https://github.com/rancher/rke2/issues/6528#issuecomment-2278536875), RKE2 comes wtih "network policies" that can restrict traffic between pods, and that might be the issue. 

However, on [according to the fluxcd documentation on networkpolicies](https://fluxcd.io/flux/installation/configuration/optional-components/#network-policies), fluxcd comes with rules that disallow traffic to the flux-system namepsace by default... which is where I was attempting to deploy my software. 

So, after I change the configs to deploy traefik to the kubernetes `default` namespace:

```{.default}
[moonpie@lizard traefik]$ curl moonpiedumpl.ing
404 page not found
```

It works!

Now,  I need to find a test service to deploy. I deployed [podinfo](https://fluxcd.io/flux/get-started/#add-podinfo-repository-to-flux), because it is a simple web service, used as an example service for fluxcd.

Here was the ingress file that I used to expose it on <podinfo.moonpiedumpl.ing>

```{.yaml filename='podinfo-ingress.yaml'}
[moonpie@lizard podinfo]$ cat podinfo-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: podinfo
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
  namespace: default

spec:
  rules:
  - host: podinfo.moonpiedumpl.ing
    http:
      paths:
      - path: /
        pathType: Exact
        backend:
          service:
            name: podinfo
            port:
              number: 9898          
```

Not really simple, and it was a pain to edit because my editor (Kate), set tabs to 4 spaces, rather than two.

Now, how can I add HTTPS/TLS to this? Although [Traefik documents how to enable acme in the first example](https://doc.traefik.io/traefik/https/acme/#configuration-examples), however, the documentation on how to add this to each individual site is unclear. 

Based on removing the annotation, and testing, it looks like the annoation isn't needed. Also, it seems that the `kubectl explain ingress --recursive` explains the "ingress" kubernetes resource, which is above. 

However, it seems that Traefik provides an "IngressRoute" resource, which is what they expect you to use for automatic https setups like what I am trying to do. But... I'm hesitant to rely on that, as "IngressRoute" seems to be traefik specific, rather than Ingress, which is general to kubernetes. 

Actually, after doing more research, I've decided to switch to [ingress-nginx](https://kubernetes.github.io/ingress-nginx/). Unlike traefik, it seems to have build in support for [external oauth authentication](https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/). Although Traefik can do it, it's not build in, and I would have to use a plugin. 

So, this means I'm switching from Traefik to nginx and cert-manager instead. 

### Nginx/Cert-Manager

I followed the [official cert-manager installation guide](https://cert-manager.io/docs/installation/helm/), but converted it into flux configs. 

```{.yaml filename='cert-manager/helmsource.yaml'}
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: cert-manager
  namespace: default
spec:
  interval: 1m0s
  url: https://charts.jetstack.io
```


```{.yaml filename='cert-manager/helmrelease.yaml'}
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: default
spec:
  chart:
    spec:
      chart: cert-manager
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: cert-manager
      version: v1.16.0
  interval: 1m0s
  values:
    crds:
      enabled: true
```

One thing that I had to change is the values at the very bottom. It seems that the `--set crds.enabled=true ` in the helm install command options doesn't work for flux. Instead, I had to seperate it out to what is in the `values` section above. 

I also deployed ingress-nginx:

```{.yaml filename='helmsource.yaml'}
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: ingress-nginx
  namespace: default
spec:
  interval: 1m0s
  url: https://kubernetes.github.io/ingress-nginx
```

```{.yaml filename='helmrelease.yaml'}
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ingress-nginx
  namespace: default
spec:
  chart:
    spec:
      chart: ingress-nginx
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: ingress-nginx
      # version: 
  interval: 1m0s
```


Another thing I had to do was to uninstall traefik:

```{.default}
[moonpie@lizard flux-config]$ kubectl delete helm
helmchartconfigs.helm.cattle.io            helmcharts.source.toolkit.fluxcd.io        helmrepositories.source.toolkit.fluxcd.io
helmcharts.helm.cattle.io                  helmreleases.helm.toolkit.fluxcd.io
[moonpie@lizard flux-config]$ kubectl delete helmrepositories.source.toolkit.fluxcd.io traefik
helmrepository.source.toolkit.fluxcd.io "traefik" deleted
```

For whatever reason, after deleting the traefik files from my git repo, they did not get removed from flux even after reconciling them. But, after this, the install works normally. 

However, when I attempt to appy an ingress, I get an error:

```{.default}
Warning: resource ingresses/podinfo is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
Error from server (InternalError): error when applying patch:
{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"networking.k8s.io/v1\",\"kind\":\"Ingress\",\"metadata\":{\"annotations\":{},\"name\":\"podinfo\",\"namespace\":\"default\"},\"spec\":{\"rules\":[{\"host\":\"podinfo.moonpiedumpl.ing\",\"http\":{\"paths\":[{\"backend\":{\"service\":{\"name\":\"podinfo\",\"port\":{\"number\":9898}}},\"path\":\"/\",\"pathType\":\"Exact\"}]}}]}}\n"}}}
to:
Resource: "networking.k8s.io/v1, Resource=ingresses", GroupVersionKind: "networking.k8s.io/v1, Kind=Ingress"
Name: "podinfo", Namespace: "default"
for: "podinfo-ingress.yaml": error when patching "podinfo-ingress.yaml": Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": failed to call webhook: Post "https://ingress-nginx-controller-admission.default.svc:443/networking/v1/ingresses?timeout=10s": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

This seems to be a sort of race condition, caused by when resources are simautaneously brought up, despite one depending on another. I found dsome relevant github issues.

<https://github.com/kubernetes/ingress-nginx/issues/5968>

There were some hacks related to deleting the hook, but I found in the [helm chart documentation](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx), there is an official option to delete the hook. I set that:

```{.yaml filename='helmrelease.yaml'}
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ingress-nginx
  namespace: default
spec:
  chart:
    spec:
      chart: ingress-nginx
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: ingress-nginx
      # version:  
  interval: 1m0s
  values:
    controller:
      admissionWebhooks:
        enabled: false
```

Now:


```{.default}
[moonpie@lizard podinfo]$ kubectl apply -f podinfo-ingress.yaml
ingress.networking.k8s.io/podinfo created
```

But:

```{.default}
[moonpie@lizard podinfo]$ curl podinfo.moonpiedumpl.ing
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

I figured out why, somewhat. For some reason, it was using the traefik ingress class, despite the fact that I uninstalled traefik, and was using nginx. However, even after:

```{.default}
[moonpie@lizard podinfo]$ kubectl get ingressclasses.networking.k8s.io
NAME      CONTROLLER                      PARAMETERS   AGE
nginx     k8s.io/ingress-nginx            <none>       6h29m
traefik   traefik.io/ingress-controller   <none>       69m
[moonpie@lizard podinfo]$ kubectl delete ingressclasses.networking.k8s.io traefik
ingressclass.networking.k8s.io "traefik" deleted
```

It still didn't work. Also, traefik seems to have a lot of stuff still running:

```{.default}
[moonpie@lizard podinfo]$  kubectl get all -A | grep traefik
default       pod/traefik-66cc8b6ff6-64zll                                1/1     Running     0              73m
kube-system   pod/svclb-traefik-13906a53-vmt4g                            0/2     Pending     0              73m
default       service/traefik                              LoadBalancer   10.43.207.1     <pending>        80:32766/TCP,443:30881/TCP   73m
kube-system   daemonset.apps/svclb-traefik-13906a53                    1         1         0       1            0           <none>                   73m
default       deployment.apps/traefik                                1/1     1            1           73m
default       replicaset.apps/traefik-66cc8b6ff6                                1         1         1       73m
```

Woops I forgot to push my changes. Nevermind. So I did, and now it doesn't work again, and it's back to a 404. 

I think I figured it out:

```{.default}
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       32h
[moonpie@lizard podinfo]$ kubectl describe ingress podinfo
Name:             podinfo
Labels:           kustomize.toolkit.fluxcd.io/name=flux-system
                  kustomize.toolkit.fluxcd.io/namespace=flux-system
Namespace:        default
Address:
Ingress Class:    <none>
Default backend:  <default>
Rules:
  Host                      Path  Backends
  ----                      ----  --------
  podinfo.moonpiedumpl.ing
                            /   podinfo:9898 (10.42.0.40:9898,10.42.0.41:9898)
Annotations:                <none>
Events:                     <none>
```

The "Ingress Class" is empty, when it probably needs to be filled with something. There are two solutions: I can set it manually, the exact field is ingress.spec.ingressClassName, or I can [set it an an ingressclass as a default](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-ingress-class). 

I edited the nginx helm release with more configuration:

```{.default}
[moonpie@lizard flux-config]$ cat nginx/helmrelease.yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: ingress-nginx
  namespace: default
spec:
  chart:
    spec:
      chart: ingress-nginx
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: ingress-nginx
      # version:
  interval: 1m0s
  values:
    controller:
      admissionWebhooks:
        enabled: false
      ingressClassResource:
        default: true
```

And after this, I had to delete the podinfo ingress, and then recreate it, but it was working again. I wonder why it didn't change the ingressclass when I reapplied the yaml file?

Now for TLS/HTTPS.

Well, TLS already kinda works. It's just using kubernetes self signed cert, rather than a letsencrypt cert. 

[Here is the doumentation on using cert-manager and nginx together](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/). They recommend using the [http01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) ([archive](https://web.archive.org/web/20240930190112/https://cert-manager.io/docs/tutorials/acme/nginx-ingress/)) challenge, but that method (or maybe just their method) does not work with wildcard domains.

> It is not possible to obtain certificates for wildcard domain names (e.g. `*.example.com`) using the HTTP01 challenge mechanism.

From  `kubectl explain issuer.spec.acme.solvers.http01`. 

THe other thing I don't like about that page, is that it suggests that to set the "ingressClassName", but I don't want to do that. What if I want to change ingresses later on, would I have to change every single issuer? I think I will just allow it to set it's own default and hope for the best.

According the [cert-manager docs for acme http01](https://cert-manager.io/docs/configuration/acme/http01/)

> If class and ingressClassName are not specified, and name is also not specified, cert-manager will default to create new Ingress resources but will not set the ingress class on these resources, meaning all ingress controllers installed in your cluster will serve traffic for the challenge solver, potentially incurring additional cost.

I should be able to not set this field. I played around a bit with leaving the fields blank, but it didn't work. I had to actually create the field, and leave it blank.

```{.yaml filename='issuer-staging.yaml'}
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: email@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
          ingress:
            ingressClassName:
```

This of course, has the downside that it will be used on all ingresses, but I should be able to get around this with the `http01-edit-in-place: "true"` annotation.

Finally, I *think* I have TLS working properly:

```{.yaml filename='podinfo-ingress.yaml'}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: podinfo
  annotations:
    cert-manager.io/issuer: "letsencrypt-staging"
    acme.cert-manager.io/http01-edit-in-place: "true"
  namespace: default

spec:
  tls:
  - hosts: 
    - "podinfo.moonpiedumpl.ing"
    secretName: podinfo-tls
  rules:
  - host: podinfo.moonpiedumpl.ing
    http:
      paths:
      - path: /
        pathType: Exact
        backend:
          service:
            name: podinfo
            port:
              number: 9898
```


# Authentik

* <https://artifacthub.io/packages/helm/goauthentik/authentik>
* [Authentik Docs](https://docs.goauthentik.io/docs/install-config/install/kubernetes)





