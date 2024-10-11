---
title: "Software Projects I follow"
date: "2024-9-7"
categories: [_blog, linux]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
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

# Funny

* <https://github.com/Daniel-Liu-c0deb0t/uwu>
* <https://github.com/sudofox/shell-mommy>