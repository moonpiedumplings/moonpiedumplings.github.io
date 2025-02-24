---
title: "Free resources to learn various things"
date: "2025-2-15"
categories: [guides]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

My browser bookmarks bar is massive. I basically bookmark anything interesting I come across, and now I have a lot of resources accumulated, and I think it's worth it to write them down, although formatting is still a work in progress. 

I have a heavy preference for Free and Open Source resources, because I believe that things like wikibooks will be much more resilient in the long run, and stay up. I've seen similar lists of learning, and it is frustrating when I'm no longer able to buy or view one of the textbooks on the list.

I also like resources maintained by some kind of organization, either the official organzition behind the software (think Microsoft and powershell), or a nonprofit, (Overthewire), because again, I think they will be more resilient in the long run.


# Linux

[Linux Up Skill Challenge](https://linuxupskillchallenge.org/)

* This is definitely one of my favorites. They mention that they don't have a free server for people to work with. However, many of the cloud providers offer 1 year's worth of credit's for a free server. Most notably, Oracle has an always free tier, which offers a very small server. I recommend this, because you don't have to give up your credit/debit card information (dealing with cloud provider pricing can be... difficult), although Oracle has been known to randomly delete people on the "Truly Free" (no credit card) tier, to make room for paying customers. 
  - Related: [Comparison of cloud provider free tiers](https://github.com/cloudcommunity/Cloud-Free-Tier-Comparison)


[OverTheWire Bandit](https://overthewire.org/wargames/bandit/)

- OverTheWire Bandit is a bit different from the other resources on this list. When I first used it, both personally and as a teaching tool, I was frustrated, because some of the commands it makes you use, will probably never show up in a real world usecase. I was frustrated with it's "trickyness", but I now realize the point of overthewire isn't to teach commands, but to teach reading the manual. The answer to every challenge they give can be found in [manpages](https://en.wikipedia.org/wiki/Man_page), the built in Linux documentation.

[Terminus](https://web.mit.edu/mprat/Public/web/Terminus/Web/main.html) — A linux tutorial in the style of a text based rpg. 

[Linux Survival](https://linuxsurvival.com/linux-tutorial-introduction/)

<https://ryanstutorials.net/linuxtutorial/>

[Linux — The Penguin Marches On (Libretexts)](https://eng.libretexts.org/Bookshelves/Computer_Science/Operating_Systems/Linux_-_The_Penguin_Marches_On_(McClanahan))

[Ubuntu's Terminal Basics](https://help.ubuntu.com/community/UsingTheTerminal)

## Ansible

[Het-Tanis Lab on Killercoda](https://killercoda.com/het-tanis/course/Ansible-Labs)

## Docker/Kubernetes/Containers

[Play with Docker Classroom](https://training.play-with-docker.com/)

* There is also the [lab](https://labs.play-with-docker.com/) where you can just play in an unstructured environment


[Play with Kubernetes Classroom](https://training.play-with-kubernetes.com/)

* There is also the [lab](https://labs.play-with-k8s.com/), an unstructured environemnt to play

[container.training](https://container.training/)

* The "[Getting started with Kubernetes and container orchestration](https://pycon2019.container.training/#1)" is one of the better resources I've seen on Kubernetes concepts.

<https://killercoda.com/>

* Interactive courses relating to a variety of topics, including Linux basics, Ansible, and Kubernetes. Requires login, although Github login can be used.


## Troubleshooting servers

[SadServers](https://sadservers.com/)

* Interactive troubleshooting of broken Linux servers.

# Windows

## Active Directory

[Microsoft](https://learn.microsoft.com/en-us/training/paths/administer-active-directory-domain-services/)

[Adsecurity](https://adsecurity.org/?page_id=41) (List of resources)

# Devops

https://learnk8s.io/troubleshooting-deployments
https://wellarchitectedlabs.com/security/


<https://nubenetes.com/>
<https://sre.google/sre-book/table-of-contents/>


# Programming

## Rust

[The Rust Programming Language](https://doc.rust-lang.org/book/title-page.html)

[Roguelike Tutorial in Rust](https://bfnightly.bracketproductions.com/rustbook/chapter_0.html)

[Rust playground](https://play.rust-lang.org/) — open ended web based playground for rust.

## C

[Wikiversity](https://en.wikiversity.org/wiki/C_Programming)

[Wikibooks](https://en.wikibooks.org/wiki/C_Programming)

## Python

[Wikibooks Python Programming](https://en.wikibooks.org/wiki/Python_Programming)

[Automate the Boring Stuff with Python](https://automatetheboringstuff.com/#toc) — Practical guide which focuses on automating mundane tasks like web scraping.

[Wikibooks Python for the Non Programmer](https://en.wikibooks.org/wiki/Non-Programmer%27s_Tutorial_for_Python_3) — Similar to automate the boring stuff in python, it focuses on introducing python and programming to a non programmer.

## C\#

[Wikibooks](https://en.wikibooks.org/wiki/C_Sharp_Programming)

[Microsoft](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/) ­— Also seems to have some interactive resources in the form of modules

## Java

[Wikibooks](https://en.wikibooks.org/wiki/Java_Programming)

## Powershell

[Powershell 101](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction?view=powershell-7.5) — and in general this is 

## Bash

[Wikibooks](https://en.wikibooks.org/wiki/Bash_Shell_Scripting)

# Documentation (writing)


[Divio Documentation System](https://documentation.divio.com/) — More about differences between the types of documentation; there's actually 4 types. 

* I really like this one to explain the differences between the four types of documentation: tutorial, how-to, reference, and explanation.

[Software Technical Writings — A guidebook (pdf)](https://jamesg.blog/book.pdf) — nitty gritty technical writing details.


# Teaching

[How to help someone use a computer (1996)](https://pages.gseis.ucla.edu/faculty/agre/how-to-help.html)


# Git

<https://shafiul.github.io/gitbook/index.html>

* Data structure oriented guide to git. It starts at explaining what an object is, rather than how the command line works. I like this guide of git more than many other guides I've seen, although it's still missing things (yes, git does a snapshot of the repo's state at every point, as seperate objects, but it deduplicates data between those objects).

[Missing Semester](https://missing.csail.mit.edu/2020/version-control/)


# Computer Science

[Heffron's Theory of Computation](https://hefferon.net/computation/)

## Data Structures

[Wikibooks](https://en.wikibooks.org/wiki/Data_Structures/)

## Low Level Operating System Programming

<https://pages.cs.wisc.edu/~remzi/teaching/>

<https://pages.cs.wisc.edu/~remzi/OSTEP/>

<https://wiki.osdev.org/Expanded_Main_Page>

## Architecture and Assembly

[MIPS Wikibooks](https://en.wikibooks.org/wiki/MIPS_Assembly)

[AA Level Computing (AQA) Wikibook](https://en.wikibooks.org/wiki/A-level_Computing/AQA)


# Math

[Project Euler](https://projecteuler.net/archives) — A set of CTF like challenges, but for mathmatics. 

[A Spiral Workbook for Discrete Mathematics (Kwong)](https://math.libretexts.org/Bookshelves/Combinatorics_and_Discrete_Mathematics/A_Spiral_Workbook_for_Discrete_Mathematics_(Kwong)) 

## Calculus

[Openstax (on Libretexts)](https://math.libretexts.org/Bookshelves/Calculus/Calculus_(OpenStax))

[Wikibooks](https://en.wikibooks.org/wiki/Calculus) — Good, but doesn't have root test, only ratio. 

[Paul's Math Notes](https://tutorial.math.lamar.edu/Classes/CalcI/CalcI.aspx)

## Linear Algebra

[Heffron](https://hefferon.net/linearalgebra/)

[Libretexts (Kuttler)](https://math.libretexts.org/Bookshelves/Linear_Algebra/A_First_Course_in_Linear_Algebra_(Kuttler))

[Libretexts Denton, Cherney](https://math.libretexts.org/Bookshelves/Linear_Algebra/Map%3A_Linear_Algebra_(Waldron_Cherney_and_Denton))

* [Original Page](https://www.math.ucdavis.edu/~linear/)

[Understanding Linear Algebra](https://understandinglinearalgebra.org/home.html)

[Interactive Linear Algebra](https://textbooks.math.gatech.edu/ila/)

[Misc set](https://opentext.uleth.ca/linalg.html)

## Discrete Structures/Mathmatics

[Wikibooks Math Proofs](https://en.wikibooks.org/wiki/Mathematical_Proof/Methods_of_Proof)

# Computer Engineering

[Nand2tetris](https://www.nand2tetris.org/)


# College Courses or Equivalent:

* https://github.com/ossu/computer-science
* https://github.com/ForrestKnight/open-source-cs
* 


# Nix

<details><summary>Expand/Collapse</summary>

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

</details>


# Hacking

<details><summary>Expand/Collapse</sumamry>

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

* This is the site for many cybersecurity courses at Arizona State University. They also have an associated [twitch stream](https://www.twitch.tv/pwncollege), where they stream classes as they happen.

[https://www.cyber-fasttrack.org/](https://www.cyber-fasttrack.org/)

[https://book.hacktricks.xyz/welcome/readme](https://book.hacktricks.xyz/welcome/readme)

</details>


# Cryptography

<details><summary>Expand/Collapse</summary>

https://gotchas.salusa.dev/GettingStarted.html
https://soatok.blog/2020/06/10/how-to-learn-cryptography-as-a-programmer/
https://cryptopals.com/
https://cryptohack.org/
https://www.youtube.com/watch?v=iqSMRO78UD0&list=PLUl4u3cNGP61EZllk7zwgvPbI4kbnKhWz

</details>