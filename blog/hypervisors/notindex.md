---
title: "A comparision of hypervisors/platforms"
description: ""
date: "2024-2-15"
categories: [linux]
format:
  html:
    toc-depth: 4
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: true
---

Currently incomplete, this won't render in the blog posts part until it is complete.


# Intro


Virtualization is an extremely important part of modern server infrastructure, in addition to virtual machine's other uses as a test bed, portable environments, or even a gaming host. 

Naturally, there exist a myriad of ways to virtualize, many platforms with different purposes, features, prices (time is a cost as well), and so on. 

[Wikipedia has a comparison of "platform virtualization,"](https://en.wikipedia.org/wiki/Comparison_of_platform_virtualization_software) which is brief overview of every almost every type of virtualization, including the management platforms, including containers/container platforms and other [operating system level virtualization](https://en.wikipedia.org/wiki/OS-level_virtualization)

I won't cover everything, because it's a **lot**, but I've tried out many of the relevant virtual machine managers and I thought I would share my thoughts on the one's I have experience with, most of which are the more popular options out there. 


I was also prompted to do so by the changes to VMware's liscensing, so I've heard many people are searching for alternatives. However, this article still uses ESXi as an example, to compare to other platforms like vSphere or non VMware products. 


# Desktop vs HCI vs (Selfhosted) Cloud

VMWare desktop literally has *desktop* in the name, making it's usecase pretty clear. Desktop virtualization platforms are things like VMWare Desktop, or VirtualBox which are aimed at your single computer seeking to emulate one or more machines. 

One difference between desktop hypervisors and the other options, is that VMWare and VirtualBox are [type 2 hypervisors](https://en.wikipedia.org/wiki/Hypervisor#Classification). This means that they will perform significantly worse than type 1 hyperviors, and in general, your "desktop" hypervisors sacrifice performance for convience.

There also exists libvirt + virt-manager, or hyper-v as a desktop hypervisor, which are type 1 hypervisors, but they aren't as popular. 

[Hyperconverged infrastructure](https://en.wikipedia.org/wiki/Hyper-converged_infrastructure) (HCI) is the modern server management paradigm where, rather than having multiple servers, each dedicated to something (firewall, storage, compute, etc), every machine plays every role. This is done by converting servers into a virtualization cluster, where resources such as compute, storage, and network interfaces can be pooled and shared across machines. 

A common example of HCI I see is, rather than having a physical firewall, a firewall OS will be installed on a virtual machine, and the network layout will be entirely virtual, with connections done between virtual machines. I've seen this setup on esxi/vsphere or proxmox. 

[Cloud computing](https://en.wikipedia.org/wiki/Cloud_computing), according to the Wikipedia definition, is the instant access to resources, in a multi user system. It has different [deployment models](https://en.wikipedia.org/wiki/Cloud_computing#Deployment_models), but I will be focusing on self hosted private/public clouds in this article.

In practice, I find that what seperates a self hosted cloud from an HCI platform is multi-tenancy (multiple users or organizations), and automatibility. A public/private cloud should be set up in a way that users can request resources, within limits (to prevent a single user from DOS-ing your cloud by asking for all resources), and also the ability for those users to automate provisioning resources, or setting up those resources (configuring virtual machines).

Of course, this line is very blurry. Technically, VMware vSphere supports multi-tenancy, and can be automated... but for some reason it doesn't seem to be a popular choice for a private cloud (probably the price). Rather than a binary, it would be better to look at it like a spectrum, where on one end is things like openstack, which is like your own personal AWS, even able to do things like databases as a service, and on the other end there is VMware ESXI, where the automation is locked behind the price of vSphere. 

# Automatibility

# Desktop Hypervisors comparison

Here's a list:

* Virt-manager (libvirt)
* VMware Player (or Workstation)
* VirtualBox
* Hyper-V

"Why don't you use Virt-Manager?" I asked the Fedora Linux user, who was using VMware workstation as a desktop hypervisor.

The reason: software defined networking. Although possible, if you have a good understanding of linux networking and the command line, it's much easier to do something like set up a virtual machine as a bridge, with ports from the GUI in Workstation. 

[VirtualBox's networking](https://www.VirtualBox.org/manual/ch06.html) on Linux is also lacking. There is no way to have what you can have with VMware (both) or Libvirt, where you have a virtual network and your host has full access to that virtual network. Rather, with VirtualBox, you're 3 options are:

* Forward ports from guest to host
* Host-Only networking: add a second adapter in addition to the original virtual ethernet, which can interface with the host. 
* Bridged networking: Virtual machine connects to the same network the host is connected to, on ethernet this works fine, but on wireless

But, VirtualBox is not without it's advantages. [Vagrant](https://en.wikipedia.org/wiki/Vagrant_(software)) is a software to automatically create and provision virtual machines. They selected VirtualBox as their main provider (virtual machine plaform) because it was cross platform and free, compared to other options. The [official docs for the default provider](https://developer.hashicorp.com/vagrant/docs/providers/default) mention this. 

 Most [vagrant boxes](https://app.vagrantup.com/boxes/search) are distributed at least as a VirtualBox machine, often only via VirtualBox. Vagrant supports other providers, but VirtualBox is overwhelmingly the most popular one.

Vagrant isn't the only case of this, however. For some reason, Nixos, a Linux based operating system distributes a [VirtualBox demo machine](https://nixos.org/download#nixos-virtualbox), but not one for any other platform, which always struck me as odd, considering that the popular, most supported choice of hypervisor on Linux is qemu-kvm. 

And that brings me to the the final desktop hypervisor I have personally used: qemu-kvm and frontends. 

In particular, I usually use libvirt, a daemon which manages qemu-kvm.

I use virt-manager, which is a GUI frontend to libvirt. the core benefit of libvirt as opposed to alternatives, is performance. 

KVM is a type 1 hypervisor, as opposed to VMware Workstation/Player, or VirtualBox, which are both type 2. 



# HCI/Clouds

These are roughly ordered from less private cloud features, to a fully featured private cloud. This doesn't include everything, just what I've looked at/worked with.

* VMware ESXi
* Proxmox
* LXD
* OpenSuse Harvester
* XCP-NG + Xen Orchestra
* VMware vSphere
* Openstack


# "Appliance" vs "Hackable" hypervisor platforms

From a [reddit post](https://www.reddit.com/r/homelab/comments/12j0rry/my_personal_impressions_on_proxmox_vs_xcpng/), they compared proxmox and xcp-ng, and one criticism that they had of xcp was that it wasn't "hackable". 

For some context, desktop/consumer oriented Nvidia GPU's are often artifically restriced from the ability to divide the GPU up among virtual machines, instead, you can only do all or nothing passthrough.

But with some custom drivers, and software hacks, it's possible to unlock "virtual gpu" (vGPU), and split the GPU among multiple virtual machines. 

Proxmox, being just Debian Linux under the hood is very easy to modify, and vGPU is one popular hack people do.

A developer/advocate for xcp-ng replied saying that [xcp-ng is not meant to be modified, but rather an "appliance"](https://www.reddit.com/r/homelab/comments/12j0rry/my_personal_impressions_on_proxmox_vs_xcpng/jfyygkx/)

This is a crucial concept in software overall, the difference between something that "just works" and something you can modify. 

I had a similar issue with xcp-ng, where I wanted to create a cluster out of many x86_64 Mac Mini's, but the Linux kernel did not have their wifi drivers. I had a lot of trouble installing wifi drivers, since they weren't even packaged for the RHEL that xcp-ng uses under the hood, although it was very painful to even find that much out. 

Appliance type softwares are what "just works". VMWare ESXi/vSphere are more on the appliance side, although there don't seem to be as many complains about it being too simple.

On the opposite end, is openstack. Openstack is often criticized for being not a HCI platform, but rather a kludge of python code, tying together other forms of virtualized compute (libvirt, vSphere) or virtualized networking. Openstack is not one piece, but rather many components, like compute and networking are seperate components. There do exist platforms which automate the install, like [kolla-ansible](https://docs.openstack.org/kolla-ansible/latest/), which uses ansible to deploy the openstack components to docker containers, but openstack still encounters some of the same problems caused by it's *hackability*. Openstack is far from an appliance, a "just works" application, which makes it unsuited for every usecase.

For an organization seeking to do openstack, what I've seen is they'll have a full-time team of engineers, equipped to make changes to openstack's python base, or low if need be. Although a team of engineers may not be worth, openstack enables a single team of engineers to manage 100,000+ machines.

## Automatibility

How easy is it to automatically create virtual machines? Is there any way to automatically configure virtual machines?

These questions are important to users of these platforms. Typically, automation is done through some kind of API, which is accessed remotely by tools like Terraform. 

This is probably one of the crucial differences between VMware ESXi, and vSphere. vSphere, the paid version, has an API, and therefore can be automated. ESXi, doesn't. 

Although proxmox has an API, and a [terraform provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs), but it is pretty barebones, you can create a cloud-init disk, an lxc container, or a virtual machine, and that's it. A common complaint of proxmox is that automation featuers are lacking, and in this example, you cannot create networks. 

Compared this to the [terraform provider for lxd/incus](https://registry.terraform.io/providers/lxc/incus/latest/docs/resources), where, in addition to vms/lxc containers, you can configure virtual networks, volumes, snapshots, and more. 

On the even more exteme end, [the terraform provider for openstack](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs) lets you spin up databases, as part of openstack's database as a service features. 


# Performance

Here are some relevant performance articles

LXC vs Hypervisors: <https://link.springer.com/chapter/10.1007/978-3-030-74402-1_12>

Xen vs KVM and overheads: <https://sites.cc.gatech.edu/systems/projects/Elba/pub/JackLiBigdata13.pdf>

Performance of several platforms: <https://link.springer.com/chapter/10.1007/978-3-319-91186-1_16>

Comparision of desktop hypervisors: <https://link.springer.com/chapter/10.1007/978-3-030-74402-1_12>

Four hypervisor comparison: <https://ieeexplore.ieee.org/abstract/document/6572995>

Docker vs Native vs Xen: <https://ieeexplore.ieee.org/abstract/document/8248375>


Hypervisors vs Lightweight virtualization: <https://ieeexplore.ieee.org/abstract/document/7092949>




