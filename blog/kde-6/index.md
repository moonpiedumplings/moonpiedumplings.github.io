---
title: "KDE 6 — New features"
date: "2024-3-13"
categories: [linux]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

KDE 6 is released, and it comes with quite a few new features. 


Firstly, I can finally use Nvidia + Wayland on my larger laptop! It's very smooth and performant, and exciting because there are certain wayland specific features I want.

# OBS

One features I've been waiting on, which I think will only end up coming in Wayland, is the ability to share some windows, but not all. I experimented with some of the new features of OBS, but they don't do quite what I want. 

For example, with OBS and pipewire, I noticed I can select multiple windows from the "Window Share" source:

![](images/obswindowsshare.jpg)


Except it doesn't actually work. Instead, it just puts one of the windows on top, and none of the others. 


I tried an alternative to this:

![](images/virtualoutput.jpg)


But it doesn't do quite what I want. It creates a literal virtual monitor, including the ability to change settings to things like "unify outputs", or "extend outputs".


What I really want is the ability to share only a single [kde workspace](https://kde.org/announcements/4/4.5.0/plasma/).

OBS had an option to share a KDE plasma workspace, but it doesn't work like what I want. Instead of just sharing a single workspace, it turns all monitors into a single input source. If I switch workspaces, then the screen video switches as well.


# Drawing Tablets


KDE 6 finally makes support for drawing tablets first class. 




