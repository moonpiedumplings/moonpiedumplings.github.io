---
title: "My first Def 
Con"
date: "2025-8-7"
categories: [blog]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: false
draft: true
---

This year, I went to Def Con.


# Line Con

"LineCon" is when you join the line badges overnight, and hang out with people. It was a LOT of fun, kinda like the experience I would get at the Linux user group which runs from 6:30pm to 12am, but instead this one was all night.

At the beginning, I got passed out this sick badge:



It's laser tag, but as a badge. There are  few rules:

* If you shoot someone, they are temporarily unable to shoot (just like normal laser tag)
    * You do not lose points for getting shot
* You can only shoot someone and get points from each person 5 times every hour
    * This is signified by the LED's in the middle lighting up. 1-5 of them will light up, before flashing red when "full".


There is actually, either intentionally or unintentionally, a very clever, ingenious design behind this. Because no points are lost when a player is hit, there is no downside to "trading" 5 hits with another player, you only gain points. The optimal strategy is not to compete and try to hit others without being hit, but instead to cooperate, and trade 5 hits with as many people as you can. The person who cooperates with the most wins.

And the more people you cooperate with, the more people you meet, and the more friends you make. This badge, despite seeming competitive on the surface, is actually extremely pro-social. 

There is also a "home mode" which, of course, changes the rules to be more competitive, like removing the 5 hit rule. With the removal of the 5 hit per hour limit, sniping people while hiding becomes a much more viable strategy.


Pizza was provided, Little Caesars, and it was pretty good.

I slept twice, once at around 1 am, and once at around 4 am, taking one 3 hour one and one 90 minute one. 

Overall, I mostly chatted with people and hung out.

# Talks

## Locked down workstations

Slides were broken lol.

"We're following the rules, not just the ones attackers play by" — there is often a "checklist" mentality when it comes to doing security. He went over there of some of the pitalls of this

Techniques noted:

* Default passwords
  * Sometimes they just change the 1 to a 2 or some other non-change
* Login scripts that happen when admins log in and do stuff
* Desktops in the DMZ that can be used
* Privileged session managers
  * MobaXTerm, etc, which store keys encrypted in the registry
* 


Q&A:

* He argues that there is an overrliance of firewall rules and zones to try to be secure
    * This doesn't work, because it's *people* that need to reach these privileged resources, rather than 256 devices from a subnet
* The integrators have aggressive timelines and often value efficiency over security
* It's not about technology but implementation
  * He has seen many, many vulnerable Distributed Control Questions
* when relying on simple physical security, have an alert when it is opened
  * "Prevention is ideal, detection is "



## C4 — External C2 framework

* Modern attackers often host their control centers from Github, Google, or other legitimate sites
  * This makes them difficult to detect
* There exists *some* integration for workflows like this, with existing C2 frameworks, but the 
  * e.g: https://docs.mythic-c2.net/ has some stuff
  * Another example given was: https://lolc2.github.io/ , a collection of C2 frameworks that use existing services as the controller


* Creator wanted their own solution
* So they found webassembly, which is able to compile from any langauge, to any WASM runtime
  * The WASI — webassembly system interface, lets you interact with system components, if you are running outside of a browser 
* They used Extism (by Dylibso), a universal wasm plugin system

* Final Product: https://github.com/scottctaylor12/C4
* This lets you 