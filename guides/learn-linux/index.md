---
title: "Free resources to learn various software things"
date: "2024-4-6"
categories: [linux]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

My browser bookmarks bar is massive. I basically bookworm anything interesting I come across, and now I have a lot of resources accumulated, and I think it's worth it to write them down, although formatting is still a work in progress. 

When not otherwise stated, the resource is related to Linux administration.



# Linux/Terminal Basics

[Linux Up Skill Challenge](https://linuxupskillchallenge.org/)

* This is definitely one of my favorites. They mention that they don't have a free server for people to work with. However, some of the cloud providers offer 1 year's worth of credit's for a free server. Most notably, Oracle has an always free tier, which offers a very small server. I recommend this, because you don't have to give up your credit/debit card information (dealing with cloud provider pricing can be... difficult), although Oracle has been known to randomly delete people on the "Truly Free" (no credit card) tier, to make room for paying customers. 
  - Related: [Comparison of cloud provider free tiers](https://github.com/cloudcommunity/Cloud-Free-Tier-Comparison)


[OverTheWire Bandit](https://overthewire.org/wargames/bandit/)

- OverTheWire Bandit is a bit different from the other resoures on this list. When I first used it, both personally and as a teaching tool, I was frustrated, because some of the commands it makes you use, will probably never show up in a real world usecase. I was frustrated with it's "trickyness", but I now realize the point of overthewire isn't to teach commands, but to teach reading the manual. The answer to every challenge they give can be found in [manpages](https://en.wikipedia.org/wiki/Man_page), the built in Linux documentation.

[Linux Survival](https://linuxsurvival.com/linux-tutorial-introduction/)

<https://ryanstutorials.net/linuxtutorial/>

[Linux — The Penguin Marches On (Libretexts)](https://eng.libretexts.org/Bookshelves/Computer_Science/Operating_Systems/Linux_-_The_Penguin_Marches_On_(McClanahan))

[Ubuntu's Terminal Basics](https://help.ubuntu.com/community/UsingTheTerminal)


## Troubleshooting servers

[SadServers](https://sadservers.com/)

* Interactive troubleshooting of broken Linux servers.

# Hacking


[https://www.isc2.org/](https://www.isc2.org/landing/1MCC?utm_source=isc2&utm_medium=textlink&utm_campaign=GBL-CC-1M-DG&utm_term=bundlepage&utm_content=awareness)

[https://overthewire.org/wargames/](https://overthewire.org/wargames/)

[https://www.cyberstartamerica.org/](https://www.cyberstartamerica.org/)

[http://ctfs.github.io/resources/topics/web/http/README.html](http://ctfs.github.io/resources/topics/web/http/README.html)

[https://hackgame.chaurocks.com/level6](https://hackgame.chaurocks.com/level6)

[https://www.sandiego.gov/cyber-lab](https://www.sandiego.gov/cyber-lab)

[https://www.picoctf.org/](https://www.picoctf.org/)

[https://grow.google/intl/ALL_ca/certificates/cybersecurity/#?modal_active=none](https://grow.google/intl/ALL_ca/certificates/cybersecurity/#?modal_active=none)

[https://exploit.education/protostar/](https://exploit.education/protostar/)

[https://pwn.college/](https://pwn.college/)

* This is the site for many cybersecurity courses at Arizona State University. They also have an assocaited [twitch stream](https://www.twitch.tv/pwncollege), where they stream classes as they happen.

[https://www.cyber-fasttrack.org/](https://www.cyber-fasttrack.org/)

[https://book.hacktricks.xyz/welcome/readme](https://book.hacktricks.xyz/welcome/readme)


# Nix

<https://github.com/justinwoo/nix-shorts/><br>
<https://nix.ug/><br>
<https://teu5us.github.io/nix-lib.html#nix-builtin-functions><br>
<https://nixos.org/manual/nix/stable/language/operators.html#has-attribute><br>
<https://book.divnix.com/><br>
<https://ianthehenry.com/posts/how-to-learn-nix/><br>
<https://noogle.dev/><br>
<https://nix-community.github.io/awesome-nix/#learning><br>
<https://www.youtube.com/@jonringer117><br>
<https://summer.nixos.org/><br>
<https://nix.camp/><br>
<https://nixlang.wiki/>


Below is stuff I don't like as much:

<https://zero-to-nix.com/><br>
<https://nix.dev/><br>
<https://nixos.wiki/><br>
<https://nixos.org/guides/nix-pills/><br>


# Devops/K8s

<https://killercoda.com/>

* Interactive courses relating to a variety of topics, including Linux basics, Ansible, and Kubernetes. Requires login, although Github login can be used.

devops

<https://nubenetes.com/>

k8s

https://learnk8s.io/troubleshooting-deployments
https://wellarchitectedlabs.com/security/

<https://sre.google/sre-book/table-of-contents/>odma


# Low Level Operating System Programming

<https://pages.cs.wisc.edu/~remzi/teaching/>

<https://pages.cs.wisc.edu/~remzi/OSTEP/>

<https://wiki.osdev.org/Expanded_Main_Page>


# Documentation (writing)


[Divio Documentation System](https://documentation.divio.com/) — More about differences between the types of documentation; there's actually 4 types. 

* I really like this one to explain the differences between the four types of documentation: tutorial, how-to, reference, and explanation.

[Software Technical Writings — A guidebook (pdf)](https://jamesg.blog/book.pdf) — nitty gritty technical writing details.


# Teaching

[How to help someone use a computer (1996)](https://pages.gseis.ucla.edu/faculty/agre/how-to-help.html)


# Git

<https://shafiul.github.io/gitbook/index.html>

* Data structure oriented guide to git. It starts at explaining what an object is, rather than how the command line works. I like this guide of git more than many other guides I've seen, although it's still missing things (yes, git does a snapshot of the repo's state at every point, as seperate objects, but it deduplicates data between those objects).



# College Courses or Equivalent:

* https://github.com/ossu/computer-science
* https://github.com/ForrestKnight/open-source-cs
* 