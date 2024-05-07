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

I was working on configuring rootless podman via ansible, but I had trouble because the tooling was incomplete. Ansible is a suboptiomal way to manage containers, and rootless podman can't manage it's own services. 

For the whole journey, see the [previous post](../build-server-3/#systemd-integration)

So yeah. I've decided to switch to Kubernetes, because Kubernetes can manage it's own services, and be rootless. The configuration-as-code landscape for Kubernetes, is much, much better than podman, and I will get many more options. For example, I can use [helm](), which is somewhat like a package manager for kubernetes, to install apps. Both Caddy and Authentik offer helm packages. Using the offered packages is probably less work than converting a docker compose to a podman container.

# Rootless (?) Kubernetes

## User Namespaces

Just like how Linux has "distributions", or bundles of software that build ontop of the Linxu kernels, Kubernetes has distros. I want rootless Kubernetes, 

I started by looking at [k3s](), the version of kubernetes I have experience with. However, there appear to be some [caveats with rootless mode](https://docs.k3s.io/advanced#known-issues-with-rootless-mode)... including not being able to run a multi node cluster. 


There is an article related to Kubernetes rootless containers: <https://rootlesscontaine.rs/getting-started/kubernetes/>

And what I see is... not promising. I don't really desire to do run `kind` or `minikube`, because they are stripped down compared to more feature-full Kubernetes distros like `k3s`

Minikube, from that list above, is promising, but it is designed for development/testing, and [doesn't support a multi-machine multi node setup](https://github.com/kubernetes/minikube/issues/94)

Kind has a similar usecasde, and limitation. Despite how easy it is to do rootless on them, that makes them unsuitable for me. 

Okay, I seem to have misunderstood what <rootlesscontaine.rs> want, as compared to what I want. That site documentes how to run all of the kubernetes components, as rootless using a user namespace. What I want, is using user namespaces to isolate pods. 

Kubernetes seems to support this natively: <https://kubernetes.io/docs/tasks/configure-pod-container/user-namespaces/>

To enable user namespaces, all you need to do is set `hostUsers: false` in your kubernetes yaml... except, how can I override this for an existing helm chart?


## Helm

Helm is very nice. However, from what I've heard, it is difficult to modify repackaged charts. This is especially concerning to me, because I intend to run all of my containers within user namespaces, and many helm charts don't provide this. In order to run prepackaged apps in user namespaces, I need to modify existing helm charts.

<https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing>

Helm has docs on customizing the chart before installing. 

## Kubernetes Distro

Here is a [list on the CNCF website](https://landscape.cncf.io/?group=certified-partners-and-providers)

I see three main options available to me:

* [Kubespray](https://kubespray.io/#/) (ansible)
* [K3s](https://k3s.io/)
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

## Distributed Storage

Eventually, I do plan to scale up, and that requires a distributed storage solution. I see two main options:

* Ceph
* Longhorn (SUSE)

Longhorn appeals to me, because if I choose to use other Suse products like rancher, then they probably integrate. 

## Gitops Software

[Gitops](https://en.wikipedia.org/wiki/DevOps#GitOps) is a principle of software deployment, where the deployment infrastructure, services, and configuration, are stored in git — hence the name, Git Operations. 

There are several ways to do Gitops on Kubernetes, but the core challenge I am encountering, is that some Gitops software must be deployed to Kubernetes in order to manage the cluster, but you cannot use that sotware to deploy itself. 

What likely happens is that after you deploy the software to the cluster, then it records itself and adds itself to the state, but I have to ensure this works properly.

Or maybe the GitOps software stays outside of the configuration, eternally untracked, but still self updating?

I still haven't selected a GitOps software, but I am looking at:

* ArgoCD
* FluxCD
* Fleet (made by SUSE, just like k3s, RKE2, rancher, and longhorn)

After thinking about it, I can't find a way to deploy a cluster and the CI/CD software at once, in such a way that it provisions itself. Many deployment methods simply abstract deploying the CI/CD software afterwards.

It's probably best to not rely on abstractions since this is my first time really deploying Kubernetes, instead, I will just have to accept that the Kubernetes deployment will not be stored as code. 

I found something interesting:

* <https://github.com/farcaller/nixhelm>
* <https://github.com/farcaller/nixdockertag>

Mentioned in a Lemmy comment, it takes helm charts, and is able to convert them to a format that can be consumed by ArgoCD, using Nix. 

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


# Presearch and Notes for Future Pieces

## Openstack

Since I am using Kubernetes to deploy services, it is worth investing if I can deploy Openstack (or some other self-hosted cloud) on Kubernetes.

* [Yaook](https://yaook.cloud/)
* [Atmosphere](https://github.com/vexxhost/atmosphere)

These look appealing, but very hard to deploy.

## Kuberntes

### Multi-Tenancy

In case I can't obtain multi-tenancy by openstack provisioning kuberntes, there are some alternative solutions I am looking at:

* vcluster
* [capsule](https://github.com/projectcapsule/capsule)
* [kamaji](https://github.com/clastix/kamaji)



