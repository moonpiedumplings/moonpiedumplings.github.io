---
title: "Container images and setuid binaries"
date: "2024-5-2"
categories: [playground]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---


A friend sends me a message in Discord:

`$ find / -perm /4000`

> That will show all suid executables on your system

They then post the output of this command on openbsd:

```{.default}
/usr/bin/chfn
/usr/bin/chpass
/usr/bin/chsh
/usr/bin/doas
/usr/bin/lpr
/usr/bin/lprm
/usr/bin/passwd
/usr/bin/su
/usr/libexec/lockspool
/usr/libexec/ssh-keysign
/usr/sbin/authpf
/usr/sbin/authpf-noip
/usr/sbin/pppd
/usr/sbin/traceroute
/usr/sbin/traceroute6
/sbin/ping
/sbin/ping6
/sbin/shutdown
```

Another friend tries it out on Gentoo Linux

```{.default}
/usr/bin/chfn
/usr/bin/chpass
/usr/bin/chsh
/usr/bin/doas
/usr/bin/lpr
/usr/bin/lprm
/usr/bin/passwd
/usr/bin/su
/usr/libexec/lockspool
/usr/libexec/ssh-keysign
/usr/sbin/authpf
/usr/sbin/authpf-noip
/usr/sbin/pppd
/usr/sbin/traceroute
/usr/sbin/traceroute6
/sbin/ping
/sbin/ping6
/sbin/shutdown
```


I suppose I should explain what setuid binaries are. Setuid binaries run with the permissions of the user who owns the binary. Usually, it's used for things like `sudo`, which use setuid to elevate the binary to root first, and then the rootful binary then does the things, like grant permissions. 

Setuid binaries are typically considered a security risk, because an exploit like a buffer overflow or some other exploit can be disasterous in a process running as root. In fact, that's how many privilege escalation vulnerabilities on Linux have happened — exploiting a setuid binary owned by root. 

I then run the command on my own system (Arch Linux)


```{.default}
[moonpie@lizard ~]$ find / -perm /4000 2>/dev/null
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/chfn
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/chsh
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/gpasswd
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/mount
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/newgrp
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/passwd
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/su
/home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/umount
/home/moonpie/.local/share/containers/storage/overlay/b2a22dd93936f487715bbc38b3a93f3f8e7d927fbf473871581c0a333f94d23a/diff/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/home/moonpie/.local/share/containers/storage/overlay/af21757bc7d5f497f4ce0552dbad07cf0725413c3a305e1ff2c8a7b5097eeb49/diff/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/chfn
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/chsh
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/gpasswd
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/mount
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/newgrp
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/passwd
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/su
/home/moonpie/.local/share/containers/storage/overlay/ae134c61b154341a1dd932bd88cb44e805837508284e5d60ead8e94519eb339f/diff/usr/bin/umount
/home/moonpie/.local/share/containers/storage/overlay/fd77695eba64b4eb5db10dd9ef0181d0053dbc23e6c465f3001d664f19e621d7/diff/usr/lib/openssh/ssh-keysign
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/chfn
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/chsh
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/gpasswd
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/mount
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/newgrp
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/passwd
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/su
/home/moonpie/.local/share/containers/storage/overlay/ede391454aeab91f6777dd38e55e085975ffcfd298987b8ec685196f2a6c811a/diff/usr/bin/umount
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/chage
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/gpasswd
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/mount
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/newgrp
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/passwd
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/su
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/bin/umount
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/sbin/pam_timestamp_check
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/sbin/unix_chkpwd
/home/moonpie/.local/share/containers/storage/overlay/c4bc4a1387e82c199a05c950a61d31aba8e1481a94c63196b82e25ac8367e5d1/diff/usr/sbin/userhelper
/home/moonpie/.local/share/containers/storage/overlay/9b1016e74f7eb4282d4aa84ecefedda2bc0f6625203e5085e070bd649945a965/diff/usr/bin/fusermount3
/usr/bin/fusermount
/usr/bin/mount.cifs
/usr/bin/fusermount3
/usr/bin/mount.nfs
/usr/bin/ksu
/usr/bin/sudo
/usr/bin/pkexec
/usr/bin/chage
/usr/bin/expiry
/usr/bin/gpasswd
/usr/bin/passwd
/usr/bin/sg
/usr/bin/unix_chkpwd
/usr/bin/crontab
/usr/bin/vmware-authd
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/mount
/usr/bin/newgrp
/usr/bin/su
/usr/bin/umount
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/polkit-1/polkit-agent-helper-1
/usr/lib/mail-dotlock
/usr/lib/ssh/ssh-keysign
/usr/lib/kf5/fileshareset
/usr/lib/qemu/qemu-bridge-helper
/usr/lib/cockpit/cockpit-session
/usr/lib/vmware/bin/vmware-vmx
/usr/lib/vmware/bin/vmware-vmx-debug
/usr/lib/vmware/bin/vmware-vmx-stats
/usr/lib/virtualbox/VBoxHeadless
/usr/lib/virtualbox/VBoxNetAdpCtl
/usr/lib/virtualbox/VBoxNetDHCP
/usr/lib/virtualbox/VBoxNetNAT
/usr/lib/virtualbox/VBoxSDL
/usr/lib/virtualbox/VirtualBoxVM
/usr/lib/electron27/chrome-sandbox
/usr/lib/chromium/chrome-sandbox
/usr/lib/electron28/chrome-sandbox
/usr/lib/Xorg.wrap
/opt/microsoft/msedge/msedge-sandbox
```


But okay. This isn't too bad. Maybe I can't execute binaries from the contianer images, outside the container images.

```{.default}
[moonpie@lizard ~]$ cd /home/moonpie/.local/share/containers/storage/overlay/2fa37f2ee66efbd308b9b91bce81c262f5e6ab6c3bf8056632afc60cc602785c/diff/usr/bin/
[moonpie@lizard bin]$ ./gpasswd
configuration error - unknown item 'FAIL_DELAY' (notify administrator)
Usage: gpasswd [option] GROUP

Options:
  -a, --add USER                add USER to GROUP
  -d, --delete USER             remove USER from GROUP
  -h, --help                    display this help message and exit
  -Q, --root CHROOT_DIR         directory to chroot into
  -r, --remove-password         remove the GROUP's password
  -R, --restrict                restrict access to GROUP to its members
  -M, --members USER,...        set the list of members of GROUP
  -A, --administrators ADMIN,...
                                set the list of administrators for GROUP
Except for the -A and -M options, the options cannot be combined.
```

That error is likely due to the fact that my Arch system has a newer version of the config file then whatever this `gpasswd` binary is expecting.


Theoretically, if there was a vulnerable setuid binary in one of these containers, then someone could execute it to become able to do things as my user.

However, this isn't actually that big of an issue, because only I can access my home direcotry, where the container images are stored.

I also experimented with docker images, with the rootful docker daemon. The same thing happened, where only root has permission to read and execuite the directories those docker images are stored in. 



I panicked at first, seeing all those setuid binaries, but it doesn't seem to be that much of a deal, and doesn't give people access to things they don't already have access to.. by default at least. 





