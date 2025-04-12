---
title: "Software freedom and why systemd doesn't suck"
date: "2024-7-20"
categories: [blog]
draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: false
---

I use KDE and a rolling release distro. When KDE updated from 5 to 6, it was horrificially unstable. One or two crashes a day for a week or two. I could have chosen to undo the update, or change the DE, but I didn't.

It's not that KDE is defective software, but rather that they made the tradeoff of more features in exchange for stability. Many of these features were compelling enough to have me put up with the issues, like the ability to configure dra      wing tablets form settings.

Compared to KDE, Gnome or XFCE don't have these problems. But I chose KDE. I don't downplay it's issues, but rather I accept the tradeoffs.

I recently read an article about [systemd by skarnet](https://skarnet.org/software/systemd.html), and other one about [go and static linking](https://blogs.gentoo.org/mgorny/2021/02/19/the-modern-packagers-security-nightmare/).

I find articles like these frustrating (although the systemd article does not make this mistake, many of it's linked references do), because they attempt to downplay people's own reasons for selecting software with those tradeoffs. 

I find it frustrating that many of these articles about static linking, systemd or other similar security concerns, try to pretend that somehow people don't know about these tradeoffs or try to downplay them. Although I think some people certainly do, but I think that, on the other side, many entities know about the tradeoffs and accept them.

For example, Debian and systemd. I read through many of the linked articles on the article by skarnet about systemd, and although Skarnet does not make this mistake, many of their references remove agency from Debian, claiming that Debian was somehow pressured into using systemd, even though Debian is usually praised as an otherwise very good democracy. Canonical, who makes Ubuntu, was making their own init system called upstart, but decided to use systemd instead. Arch Linux, another independent distrubution, chose to use systemd instead.

Rather than being pressured or bullied into using systemd, they were aware of the tradeoffs when they chose to use systemd. The security disadvantages of using a more monolithic init system, and the political disadvantages, as I won't pretend that it's not concerning that systemd is controlled by a single entity, Red Hat.

I find it frustrating when people balk at someone not using the most theoretically secure setup available, and criticize others for making that choice. It's not that security is not valuable, but there are other things people trade off for, and accept lesser security. 

Many companies in particular, have an interesting way of going about this. They assume they will be hacked, and then work backwards from there. This is because, more often than software vulnerabilities, human error, such as phishing scams, or so on, are likely to result in a company getting hacked. For example, [Github leaked *their own private key*](https://github.blog/2023-03-23-we-updated-our-rsa-ssh-host-key/) lly. That key, would have given an attacker complete and total control over the infrastructure. Fortunately, no one took advantage of it, and they just rotated the key in use. But even if an attacker gained total control over their systems, GitHub has contingencies in place. Offsite backups. Literal financial insurance, for financial damage if their system were to go down, or a leak were to happen. 

Github isn't the only entity that leaked their private key like that. According to [Gitguardian](https://www.gitguardian.com/state-of-secrets-sprawl-report-2024), millions of private keys, were leaked on Github accidentally by developers. 

The points of those who criticize systemd, and other similar software, are, for the most part, valid. I just find it frustraing when they portray software as "defective" because they are unwilling to accept that maybe people chose those tradeoffs, and they simply have a different set of values for what they want out of software, and not everyone wants the same thing. Systemd isn't defective. And neither is KDE.