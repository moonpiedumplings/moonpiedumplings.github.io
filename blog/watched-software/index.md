---
title: "Software Projects I follow"
date: "2024-9-7"
categories: [blog]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: false
---


# Vulnerability Scanning (Greenbone)

External:

(<https://programming.dev/post/17335421>)

* <https://github.com/future-architect/vuls> <https://h0bbl3s.port0.org/vulnerability-scanning-with-vuls/>
* <https://github.com/vulsio/vulsctl>
* <https://github.com/projectdiscovery/nuclei>
* <https://doc.ivre.rocks/en/latest/>
* <https://github.com/tlkh/prowler> — last update 6 years ago

* Nmap scripts
    * <https://github.com/scipag/vulscan> — vulnerability scanning project for nmap
    * <https://github.com/vulnersCom/nmap-vulners>
    * <https://github.com/cloudflare/flan> — last update 2 years ago, based on vulners fro nmap


Web scanning:

* <https://www.zaproxy.org/>


# Browser based Desktop (Kasmweb/VNC)

Full featured: 

Multi user Full Featured:

* <https://games-on-whales.github.io/> — <https://github.com/games-on-whales>
* <https://github.com/spaceness/stardust> 
* kasmweb — not open source
* <https://github.com/pwncollege/dojo>
  - Is an addon to <https://docs.ctfd.io/docs/overview/>, but adds web workspaces and more.
  - [ctfd has SSO support](https://docs.ctfd.io/docs/settings/single-sign-on/#oauth) 
* <https://coder.com/> 
  * Open source, self hostable
* <https://github.com/opencloudplay>
* FastX — offers student discounts, according to the person at the booth at the So Cal Linux Expo.
* <https://github.com/giongto35/cloud-morph>

Single User full featured: 

* <https://docs.linuxserver.io/images/docker-kasm/>
* <https://github.com/Fmstrat/webbian> — [Docs](https://nowsci.com/webbian/)
* <https://github.com/m1k1o/neko>
  - Notable because this one supports password auth, and viewer/controller style setups. It's explicitly designed for multi-user web browsing activities.
* <https://github.com/accetto/ubuntu-vnc-xfce-g3>
* <https://github.com/gezp/docker-ubuntu-desktop>
* <https://github.com/selkies-project/docker-nvidia-egl-desktop>
  - Also has nvidia-glx-desktop
  - Although the docker containers seem to be maintained, the overall product seems to be dead. It looks like they were working towards a full web UI before it died.
* <https://github.com/vital987/vubuntu> — last updated 2 years ago

Web apps:

* <https://github.com/DustinBrett/daedalOS>
* <https://docs.fullstacked.org/#/>
* <https://github.com/MercuryWorkshop/anuraOS>
    - This one is special because it uses a javascript linux emulator combined with a proxy, to have a full linux environment running in your browser.
* <https://copy.sh/v86/>
  - No networking
* <https://bellard.org/jslinux/> — linux emulator
* <https://github.com/shmuelhizmi/web-desktop-environment> — web app, but has xpra support


Somewhat related: <https://github.com/udevbe/greenfield> — it's an html5 wayland compositor.

Also related: [cloud-morph](https://github.com/giongto35/cloud-morph) and [cloud-game](https://github.com/giongto35/cloud-game)

<https://eclipse.dev/che/> — seems to be a promising alternative to Coder.


## Browser Based IDE (javascript/wasm)

* <https://github.com/styfle/awesome-online-ide>

[Livecodes](https://github.com/live-codes/livecodes) from this list is pretty cool.

There is also this one project: [Interactive Code Playgrounds](https://github.com/lucademenego99/icp-bundle). This one is the best thing I have found so far for generally embedding code snippets into blogposts or slides I might make. [Example slides here](https://lucademenego99.github.io/icp-slides/editors.html#/).

# Intrustion Detection System (Wazuh)

* Wazuh
* [Samhain](https://www.la-samhna.de/samhain/)
* [Tiger](https://www.nongnu.org/tiger/)
* [Tripwire](https://en.wikipedia.org/wiki/Open_Source_Tripwire) (last update 6 years ago)
* [Falco](https://github.com/falcosecurity/falco)


# Domain/AD

* <https://cid-doc.github.io/>


# CI/CD Security

There was an interesting project, but I don't remember it's name. 

# Staticrypt:

Software that encrypts contents of a static site, to be unlocked by a password. Staticrypt was were I first saw this idea.

* [Staticrypt](https://github.com/robinmoisson/staticrypt)
* <https://github.com/mprimi/portable-secret>
* <https://github.com/sowbug/quaid>


[Hacker News Discussion](https://news.ycombinator.com/item?id=41404064)

[Lemmy Discussion](https://programming.dev/post/18818724)

Lots of similar software mentioned there.

# AI

## Speech-To-Text and Text-To-Speech

* <https://github.com/k2-fsa/sherpa-onnx>
* 

## LLM's

* <https://github.com/Mozilla-Ocho/llamafile>


# Misc: 

* <https://github.com/jvoisin/php-malware-finder> — Uses yara rules to find PHP webshells and other malware.
* <https://github.com/lakinduakash/linux-wifi-hotspot>
* <https://github.com/pieroproietti/penguins-eggs> — create custom arch isos
* <https://github.com/sickcodes/Docker-OSX>
* <https://github.com/wavemakercards/wavemaker-cards-v4>
* <https://github.com/Kron4ek/Conty>
* <https://github.com/jordansissel/fpm> — Can convert packages from one type to another.
* <https://github.com/Fmstrat/winapps> and <https://github.com/Fmstrat/loffice-365>


# Kubernetes

* <https://github.com/freelensapp>
* <https://github.com/wiredoor/wiredoor>
* <https://github.com/werf/nelm> — I want a helm alternative, helm has certain issues
  * [Reddit post](https://www.reddit.com/r/kubernetes/comments/1jqd4pb/werfnelm_nelm_is_a_helm_3_alternative/)
* <https://yokecd.github.io/docs/>
* <https://github.com/ctrox/zeropod> — container pause and save to memory, then resume. Comes with an experimental in memory

# Openstack

* [Substation TUI](https://substation.cloud/)
  * Code: <https://github.com/cloudnull/substation>

Known deployment solutions:

Kubernetes:

* Openstack-helm
  * Genestack
  * Understack
  * Atmosphere
  * Starlingx
* Yaook
* Openstack k8s operators
* Mirantis Rockoon
* Canonical Sunbeam
  * Although this one is different because it's somewhat opaque and I cannot see any easy docs about installing it to an existing k8s cluster.

Not kubernetes:

* [Debian](https://salsa.debian.org/openstack-team/debian/openstack-cluster-installer)
* Kolla-ansible
  * [OSISM](https://osism.tech/)/[SCS](docs.scs.community/docs/iaas/guides/concept-guide/components/openstack)
* Openstack-ansible


Configuration:

* <https://k-orc.cloud/> — Gives you a k8s operators for managing openstack

# Nix

Sandboxing solutions:

* <https://github.com/Naxdy/nix-bwrapper>
* <https://github.com/nixpak/nixpak>

These are similar solutions, although they have slightly different goals.

# OpenBSD

<https://learnbchs.org/>

Unique web development framework using C and openbsd.

# Cyber Ranges

A cyber range is a set of virtual machines for you to hack into and around.

<https://github.com/Orange-Cyberdefense/GOAD>

<https://orange-cyberdefense.github.io/GOAD/>

<https://mayfly277.github.io/posts/GOADv2/#installation>

<https://docs.ludus.cloud/>

<https://docs.platform.cyberrange.cz/>


<https://github.com/stratosphereips/stratocyberlab>

<https://github.com/GSI-Fing-Udelar/tectonic>


Just a single virtual machine:

<https://www.vulnhub.com/>

[Secgen](https://github.com/cliffe/SecGen) — randomly generate vulnerable VM's. 


Related: Scoring engine/inject software:

<https://github.com/dbaseqp/Quotient>

<https://docs.openbas.io/latest/deployment/ecosystem/executors/>


# Music

[Tidalcycles](https://en.wikipedia.org/wiki/TidalCycles) — haskell based language for generating music.


[https://patterns.slab.org](Strudel) — Javascript based runtime for the above.



# Hardware

[Raptor Computing Systems](https://www.raptorcs.com/).

[Starlabs](https://us.starlabs.systems/?shpxid=e8451cdf-7b0a-4505-967f-f75f00144a4a) — Arm laptops

Thinkpad X13s

# Funny

* <https://github.com/Daniel-Liu-c0deb0t/uwu>
* <https://github.com/sudofox/shell-mommy>