---
title: "My server part 4 — Kubernetes"
date: "2024-3-20"
categories: [linux]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

# Why the switch?

I was working on configuring rootless podman via ansible, but I had trouble because the tooling was incomplete. Ansible is a suboptiomal way to manage containers, and rootless podman can't manage its own services. 

For the whole journey, see the [previous post](../build-server-3/#systemd-integration)

So yeah. I've decided to switch to Kubernetes, because Kubernetes can manage it's own services, and be rootless. The configuration-as-code landscape for Kubernetes, is much, much better than podman, and I will get many more options. For example, I can use [helm](), which is somewhat like a package manager for kubernetes, to install apps. Both Caddy and Authentik offer helm packages. Using the offered packages is probably less work than converting a docker compose to a podman container.

# Rootless (?) Kubernetes

## User Namespaces

Just like how Linux has "distributions", or bundles of software that build on top of the Linux kernels, Kubernetes has distros. I want rootless Kubernetes, 

I started by looking at [k3s](https://k3s.io/), the version of kubernetes I have experience with. However, there appear to be some [caveats with rootless mode](https://docs.k3s.io/advanced#known-issues-with-rootless-mode)... including not being able to run a multi node cluster. 


There is an article related to Kubernetes rootless containers: <https://rootlesscontaine.rs/getting-started/kubernetes/>

And what I see is... not promising. I don't really desire to do run `kind` or `minikube`, because they are stripped down compared to more feature-full Kubernetes distros like `k3s`

Minikube, from that list above, is promising, but it is designed for development/testing, and [doesn't support a multi-machine multi node setup](https://github.com/kubernetes/minikube/issues/94)

Kind has a similar usecase, and limitation. Despite how easy it is to do rootless on them, that makes them unsuitable for me. 

Okay, I seem to have misunderstood what <rootlesscontaine.rs> want, as compared to what I want. That site documents how to run all the kubernetes components, as rootless using a user namespace. What I want, is using user namespaces to isolate pods. 

Kubernetes seems to support this natively: <https://kubernetes.io/docs/tasks/configure-pod-container/user-namespaces/>

To enable user namespaces, all you need to do is set `hostUsers: false` in your kubernetes yaml... except, how can I override this for an existing helm chart?


## Package Manager/Helm

Helm is very nice. However, from what I've heard, it is difficult to modify repackaged charts. This is especially concerning to me, because I intend to run all of my containers within user namespaces, and many helm charts don't provide this. In order to run prepackaged apps in user namespaces, I need to modify existing helm charts.

<https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing>

Helm has docs on customizing the chart before installing. 

There exist some package repositores (similar to dockerhub) for helm:

* <https://artifacthub.io/>
  - Helm charts, package
* <https://operatorhub.io/>
  - Not helm, rather kubernetes yaml managed by a lifecycle manager
  - Packages "operators", like this [rook/ceph](https://operatorhub.io/operator/rook-ceph)
  - Appeals to me less than artifacthub

## Kubernetes Distro

Here is a [list on the CNCF website](https://landscape.cncf.io/?group=certified-partners-and-providers)

I see three main options available to me:

* [Kubespray](https://kubespray.io/#/) (ansible)
* [K3s](https://k3s.io/)>
* [RKE2](https://docs.rke2.io/)
* k0s
  - [Has an ansible playbook](https://docs.k0sproject.io/stable/examples/ansible-playbook/)
* [kurl](https://kurl.sh/)
  - Custom kubernetes installer, including things like storage
  - Supports rook, but I don't know if it is rook + ceph
  - doesn't seem to have anywhere near as much activity as I expect it to have... no CI/CD, Longhorn is deprecated
* [Kubernetes the Easier Way](https://github.com/darxkies/k8s-tew)
  - Comes with a [plethora of features](https://darxkies.github.io/k8s-tew/_build/html/features.html)
    - including nginx + letsencrypt, helm, ceph, metallb, prometheus/grafana
    - Very appealing, many features


I don't really want to opt for manual installation, or anything that's too complex for too little gains.

Kubespray appeals to me since it's ansible, and it would be cool to manage the kubernetes cluster installation and the services from the same spot — but it got ruled out:

From [the README](https://github.com/kubernetes-sigs/kubespray?tab=readme-ov-file#container-runtime-notes)

> Supported Docker versions are 18.09, 19.03, 20.10, 23.0 and 24.0. The recommended Docker version is 24.0. Kubelet might break on docker's non-standard version numbering (it no longer uses semantic versioning). To ensure auto-updates don't break your cluster look into e.g. the YUM versionlock plugin or apt pin

It seems as kubespray deploys kubernetes by installing docker, and then deploying kubespray in docker. Although this is a neat decision, I cannot use docker at all, becuause I intend to deploy openstack using [kolla-ansible](https://docs.openstack.org/kolla-ansible/latest/), which also uses docker. From my testing, the openstack deployment completely destroys docker's networking, so I probably can't use both at once. 

In addition to that, kubespray completely [uninstalls podman](https://github.com/search?q=repo%3Akubernetes-sigs%2Fkubespray%20%22podman%22&type=code), meaning I can't use podman as a provider for kubespray either. 

I found an [ansible role](https://github.com/rancherfederal/rke2-ansible) to deploy RKE2, but it seems that it just deploys vanilla RKE2, with none of the goodies that I am searching for like a load balancer or external storage.

I also found something similer for [k3s, an ansible role](https://github.com/k3s-io/k3s-ansible) to deploy a "vanilla" kubernetes cluster. However, at the bottom, they mention [some other ansible roles](https://github.com/k3s-io/k3s-ansible?tab=readme-ov-file#need-more-features) to deploy a more than vanilla k3s cluster.

I found a [reddit post](https://www.reddit.com/r/kubernetes/comments/1c09jfz/i_opensourced_today_my_fully_automated_k3s/) where someone open sourced their own [ansible playbook](https://github.com/axivo/k3s-cluster) — Only 22 days ago (as of the time of writing this), and it's quite comprehensive. It comes with Argocd, Cilium, Longhorn, Prometheus, Cloudfare Let's Encrypt certificates with cert-manager, and more.

I looks very appealing to me, despite the fact that it seems to be opinionated, and designed for personal use. In addition to that, they are simply using ansible's helm modules to deploy stuff — what would be different from me doing that, with my own deployment choices?

## Distributed (?) Storage

Eventually, I do plan to scale up, and that requires a distributed storage solution. I see two main options:

* Ceph
* Longhorn (SUSE)
  - [Artifacthub](https://artifacthub.io/packages/helm/longhorn/longhorn)
* [SeaweedFS](https://artifacthub.io/packages/helm/seaweedfs-csi-driver/seaweedfs-csi-driver)
* [Kadalu (GlusterFS)](https://github.com/kadalu/kadalu)
  - Helm chart?
* [local-path-provisioner](https://github.com/rancher/local-path-provisioner) (SUSE)
  - An enhancement to Kubernete's builtin ability to handle local storage paths, by SUSE
  - maybe this is optimal, since I have just a one node cluster?

Longhorn appeals to me, because if I choose to use other Suse products like rancher, then they probably integrate. 

But now, I've chosen to opt for FluxCD to manage my cluster rather than Longhorn. Because of this, I will probably opt for Ceph. 

I see a few options to deploy Ceph: 

* <https://artifacthub.io/packages/helm/rook/rook-ceph>
  - Has a [severe security vulnerability reported](https://artifacthub.io/packages/helm/rook/rook-ceph?modal=security-report&section=vulnerabilities&image=rook%2Fceph%3Av1.14.3&target=Python), but is it really that bad?
* CSI (link later)

I don't understand what a CSI is and how it compares to the Rook ceph operator.

However, it seems I'm running into another issue: It's [difficult to run rook-ceph](https://www.reddit.com/r/kubernetes/comments/hyvclw/how_to_run_rookceph_on_one_node/) on a single node. There are also other complaints about performance with ceph — the big complaint is that ceph uses up a lot of CPU relative to other distributed storage, but I wasn't worrying about that. However, I've seen multiple claims that ceph requires high end hardware — SSD's, which I don't have. (Right now I have just one hard drive). 

[Longhorn has a similar issue](https://github.com/longhorn/longhorn/discussions/5737) — at least it seems usable on only one node, but the recommendation is to have at least 3 nodes. 

Local-path-provisioner is probably what I'm going to use, because I think it is built into k3s (and by extension, RKE2), by default. 


## Gitops Software

[Gitops](https://en.wikipedia.org/wiki/DevOps#GitOps) is a principle of software deployment, where the deployment infrastructure, services, and configuration, are stored in git — hence the name, Git Operations. 

There are several ways to do Gitops on Kubernetes, but the core challenge I am encountering, is that some Gitops software must be deployed to Kubernetes in order to manage the cluster, but you cannot use that software to deploy itself. 

What likely happens is that after you deploy the software to the cluster, then it records itself and adds itself to the state, but I have to ensure this works properly.

Or maybe the GitOps software stays outside the configuration, eternally untracked, but still self updating?

I still haven't selected a GitOps software, but I am looking at:

* ArgoCD
* FluxCD
  - [Simple enough to bootsrap](https://fluxcd.io/flux/get-started/)
  - bootstraps itself from Github repo
* Fleet (made by SUSE, just like k3s, RKE2, rancher, and longhorn)

After thinking about it, I can't find a way to deploy a cluster and the CI/CD software at once, in such a way that it provisions itself. Many deployment methods simply abstract deploying the CI/CD software afterwards.

It's probably best to not rely on abstractions since this is my first time really deploying Kubernetes, instead, I will just have to accept that the Kubernetes deployment will not be stored as code. 

I found something interesting:

* <https://github.com/farcaller/nixhelm>
* <https://github.com/farcaller/nixdockertag>

Mentioned in a Lemmy comment, it takes helm charts, and is able to convert them to a format that can be consumed by ArgoCD, using Nix. 

Okay, but after more research, I've settled on Flux. It seems very easy to bootstrap, and to use [helm charts](https://fluxcd.io/flux/guides/helmreleases/) with it. I don't really need a GUI or multitenancy like ArgoCD provides, or the integrations that Fleet (probably) provides. 

Flux seems "lightweight". It reads from a Git repo, and applies and reconciles state. In addition to that, it can bootstrap itself. Although, I think I will end up running into a funny catch-22 when I decide to move away from github to a self hosted forgejo, on the kubernetes cluster, everything will be fine... probably.

Maybe I could have a seperate git server, and that stores the Kubernetes state? Flux seems to support [bootstrapping from any git repo](https://fluxcd.io/flux/cmd/flux_bootstrap_git/).

A few recommendations on the internet seem to suggest that I should have bootstrap flux from something external to the cluster, rather than from inside the cluster. 



## Misc Addons/Deployment

* Monitoring: [kube-prometheus-helm-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack?modal=install)

* Secrets:
  - : <https://github.com/getsops/sops>
    - Basically ansible vault, very appealing
  - : <https://external-secrets.io/latest/>
    - Seems catch-22y, I need an existing external service to manage secrets... but I suppose it is called external secrets

* Ingress
  - Nginx ingress... but how do I get SSL with this setup?
  - Traefik ingress (has [automatic https](https://www.eff.org/deeplinks/2024/03/should-caddy-and-traefik-replace-certbot))
  - Caddy: <https://github.com/caddyserver/ingress> — WIP software...



I need a simple git ssh for bootstrapping flux from.

* <https://github.com/chrisnharvey/simple-git-server>
  - Seems unmaintained
* Apparently you can just use ssh as a git server

# Services

## Authentik

Authentik provides [documentation on a Kubernetes deployment](https://docs.goauthentik.io/docs/installation/kubernetes), along with a Helm chart.

## Forgejo

Forgejo has a helm chart: <https://codeberg.org/forgejo-contrib/forgejo-helm>

Unlike authentik, forgejo's helm chart also seems to have some [support for rootless/user namespaces](https://codeberg.org/forgejo-contrib/forgejo-helm#rootless-defaults).

## Nextcloud

There is an existing [helm chart for nextcloud](https://nextcloud.github.io/helm/): <https://github.com/nextcloud/helm>

However, it says in the above, that it is community maintained, and not truly official. 

Going to the [nextcloud official docs for larger scale deployment recommendations](https://portal.nextcloud.com/article/Scalability/Deployment-recommendations/Large-Organizations-and-Service-Providers)... and it's paywalled. It's likely that Nextcloud maintains official helm charts — but only for paying customers. 


# Networking

Yup. After spending the majority of my time setting up networking on my previous iteration of this plan, it's time to do exactly that, *again*. 

My original plan was to host some components of openstack on a VPS, allowing my server to give any virtual machines public ipv6 addresses despite being firewalled and behind the NAT of Cal State Northridge's internet... except there is no NAT. Or firewall. In fact, if I set up bridging, I can give virtual machines more than one public ipv4 address without going through any of that hassle. So my plans have changed.

However, some questions come in to play that need to be answered, that I need to think about:

* Multi node kubernetes: The dream is to have some form of high availability, where any two machines can fail, and my setup stays up (high availability usually requires 3 machines). 
* Can I deploy openstack parallel to kubernetes?
* Should my router go in front of, or behind my server?

I would like to forgo the router entirely, as it reduces complexity. However, the router is useful because it can provide ethernet to my laptop, which is faster than the CSUN wifi, especially when it gets congested.

I am thinking of putting the router in front of my server, and configuring bridged networking, to allow my server to access the CSUN network directly, through both it's ethernet ports. However, I do fear a speed bottleneck — when attempting to test CSUN's ethernet speeds, I discovered that my laptop's ethernet port only supported 100 mbps, meaning even though the cable supported higher speeds, and the ethernet port potentially supported higher speeds, there was a cap. I need to research 

Another potential setup is for the server to be in front, with the router connected to it's secondary NIC/ethernet port. I could use the special bridging setup I have discovered where the primary ethernet port is both a bridge and a normal network interface, and then I could add the secondary ethernet port as a virtual port to the bridge. I would then create a second bridge, and add it to the first bridge, and openstack would use that bridge as it's bridge for virtual machines.

I've decided on the second. Although, there is another bottleneck in place, the NIC on my server itself. Although my router has all 1000 Mb/s ports, both NIC of my servers are capped at 100mb/s. I need to buy a PCI ethernet card (preferably with two ethernet ports). 

Options:

* https://www.amazon.com/Dual-Port-Gigabit-Network-Express-Ethernet/dp/B09D3JL14S

The other thing I need to get working with is dynamic dns. Since CSUN's ethernet works via DHCP, I'm not guaranteed the same ip address between reboots or other network configuration changes. I am using porkbun as my DNS provider, and I am searching for some options for that. 

* https://hub.docker.com/r/qmcgaw/ddns-updater/
  - Comes with kubernetes manifests, but look too complex for now
  - minor issue with root domain of subdomains [something needs to be "@"](https://www.reddit.com/r/homelab/comments/137y1v9/dynamic_dns_with_porkbun/kegh2xy/)

# Presearch and Notes for Future Pieces

## Openstack

Since I am using Kubernetes to deploy services, it is worth investing if I can deploy Openstack (or some other self-hosted cloud) on Kubernetes.

* [Yaook](https://yaook.cloud/)
* [Atmosphere](https://github.com/vexxhost/atmosphere)

These look appealing, but very hard to deploy.

## Kubernetes

### Multi-Tenancy

In case I can't obtain multi-tenancy by openstack provisioning kuberntes, there are some alternative solutions I am looking at:

* vcluster
* [capsule](https://github.com/projectcapsule/capsule)
* [kamaji](https://github.com/clastix/kamaji)



