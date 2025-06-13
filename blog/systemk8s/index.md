---
title: "Systemd is Basically One Node Kubernetes"
date: "2025-5-24"
categories: [blog]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: false
---


Systemd, is essentially designed to replicate features of Kubernetes. 

Kubernetes is (buzzwords incoming), a clustered, highly available, multi tenant, declarative, service manager and job scheduler. To break down what that means:

* Multi tenant: There can be different "users" on a Kubernetes cluster, which can be granually given access to different resources or capabilities
* Declarative: All of the Kubernetes config, roles, users, and jobs, and can be declared as code, "yaml". 
* Service Manager: Kubernetes can run services, specifically containers (this is important to note).
* Job Scheduler: Users can start short or long running "jobs"
* Clustered: Kubernetes can combine resources from more than one physical or virtual server into a cluster. It does not literally combine them, but rather it shifts around services and jobs to make more room. Some services can take direct advantage of this though, where running multiple instances of them does let you combine resources.
* Highly Available: If any single "node" of a kubernetes cluster goes down, the services Kubernetes runs, and Kubernetes itself, stay active.

Systemd is essentially trying to Kubernetes, without the clustering and highly available parts of Kubernetes. It is/has:

* Multi tenant: This is what polkit, and logind do. They give users the ability to run long running services, but control the resources and capabilities those users who have access to
* Declarative: Systemd doesn't use yaml like kubernetes, but instead it uses the ini file format — but almost everything in Systemd can be declared as an ini file.
* Service Manager: This one is mostly self explanatory — but what's important to note is the focus that systemd has on containers. There is support for OCI containers via [podman quadlets](https://blog.while-true-do.io/podman-quadlets/), but Systemd also has it's *own* container format that it can [launch rootlessly](https://github.com/systemd/systemd/issues/30239), and built on top of this is [systemd portablectl](https://systemd.io/PORTABLE_SERVICES/), which is essentially an [application container](https://en.wikipedia.org/wiki/Application-level_virtualization) format, similar to docker. You tell systemd to run a service with a root image of one of these containers, and it does so.
* Job Scheduler: Timers, but it's not a full featureset. Perhaps Systemd doesn't care about this because people can simply run commands after they are ssh'ed in.

Now, based on the assumption, I can make some (possibly incorrect) predictions about what features systemd will add next:

* Firewall service: Kubernetes has something akin to a firewall, but mostly this prediction is because Linux doesn't really have a declarative firewall. [Systemd kinda already has something similar](https://www.ctrl.blog/entry/systemd-application-firewall.html) but it's not complete. 
* More advanced manipulation of user resource and capability constraints. It looks like there is some [simple cgroup stuff](https://unix.stackexchange.com/questions/351466/set-a-default-resource-limit-for-all-users-with-systemd-cgroups), but I do think we are going to eventually see Seccomp and other restrictions. 
* A "container repo" for portable/nspawn services. I think they used to have one for [OS containers](https://en.wikipedia.org/wiki/OS-level_virtualization) for machinectl, but I can't find it. But If they are actually trying to be Kubernetes, then I would expect to see a setup where you can have a file declaring a service, and then it pulls the container image for that service and then runs it. 

Now, "one node Kubernetes" probably isn't the best choice for a normal server or desktop distro. (Actually I love Kubernetes as a server but that's a different discussion). But it's the most popular choice, so I think people should be aware of the architecture and intent behind the software they use. 