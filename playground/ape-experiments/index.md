---
title: "Portable executable experiments for CCDC"
date: "2024-10-31"
categories: [playground]  
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: auto
---

The college I am going to has a team that comeptes in a competition called [CCDC](https://en.wikipedia.org/wiki/National_Collegiate_Cyber_Defense_Competition), which is a blue team cybersecurity competition. It involves securing misconfigured, outdated OS's and services, while being asked to do tasks called "injects", and protecting a highly vulnerable environment from "red teamers" — competition organizers who play the role of a hypothetical attacker. 

One of the big problems encountered in CCDC is the portability of applications. Competitors will be asked to work across a variety of Linux distros, of various types and various package versions, and even across the BSD versions. Of course, sometimes the solution is simple: install your tools, like python or tmux, from the package manager on every Linux/BSD OS.

The second problem is that the organizers of the competition may break our package managers. Deleting repos, or giving us a distro without a package manager, or giving us End-Of-Life distributions, with dead repositories. 

And also, we aren't allowed to do a distribution release upgrade. So we can't go from CentOS 8 to CentOS Stream or other things like that. We also aren't allowed to replace non-containerized scored services with containers. We also aren't allowed to replace scored services with another application of the same type, so no replacing Apache with Caddy. 

However, we can use static executables to replace services, and there are real limits on what kind of utilities we can deploy, other than resources usage (Linux/BSD machines usually have 2 gigabytes of ram).

I was looking into portable executables, to mitigate some of the problems and restrictions. I would like to have a portable version of python, so that ansible playbooks relating to firewall automation and backups can be run as soon as possible, and also a portable terminal multiplexer, so that our team members can collaborate directly. I would also like portable (statically compiled) versions of some of the services, so that we can replace them in place, rather than being forced to rely on a package manager that may not work.


# Ape/Cosmo

[Cosmopolitan](https://justine.lol/cosmopolitan/index.html) is a project that turns C into build once, run anywhere language. It works by creating a fat binary that contains code for all other operating systems, including UEFI, and then dynamically figuring out where it is being run. 

There are some precompiled binaries for ape as well:

* <https://github.com/ahgamut/superconfigure/releases>
* <https://cosmo.zip/pub/cosmos/bin/>


Some of these tools are very interesting, in particular `tmux` and `python`. Ansible requires python to be on the machines, but it can be difficult to get python on a machine, especially if the package manager is broken. I can easily imagine something like:


`cat staticpython | ssh hostname "cat > remotestaticssh"`

The above would enable us to get a version of staticly compiled python on anything with ssh, and only ssh needed. There are also some [other ways to do it](https://superuser.com/questions/291423/how-to-copy-a-file-without-using-scp-inside-an-ssh-session). 

I download an actually portable version of tmux and python, and attempt to run them (the test is to see if they still work without glibc, which is often a limitation of portability for many other portable binaries). 


```{.default}
[moonpie@lizard apeb]$ ./python
0088:err:sync:RtlpWaitForCriticalSection section 00006FFFFFFAC440 "../wine-staging/dlls/ntdll/loader.c: loader_section" wait timed out in thread 0088, blocked by 007c, retrying (60 sec)
0120:fixme:file:server_get_file_info Unsupported info class 1c
0120:fixme:file:NtFsControlFile FSCTL_GET_REPARSE_POINT semi-stub
0120:fixme:file:server_get_file_info Unsupported info class 1c
0120:fixme:file:server_get_file_info Unsupported info class 1c
Python 3.12.3 (main, Aug  3 2024, 10:18:33) [GCC 14.1.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
0120:fixme:file:server_get_file_info Unsupported info class 1c
>>> exit(_
^C0124:err:virtual:virtual_setup_exception stack overflow 1280 bytes addr 0x952cd2 stack 0x1300b00 (0x1300000-0x1301000-0x1400000)
^C012c:err:virtual:virtual_setup_exception stack overflow 1280 bytes addr 0x952cd2 stack 0x1400b00 (0x1400000-0x1401000-0x1500000)
^C0134:err:virtual:virtual_setup_exception stack overflow 1280 bytes addr 0x952cd2 stack 0x1500b00 (0x1500000-0x1501000-0x1600000)
^C013c:err:virtual:virtual_setup_exception stack overflow 1280 bytes addr 0x952cd2 stack 0x1600b00 (0x1600000-0x1601000-0x1700000)
^C0144:err:virtual:virtual_setup_exception stack overflow 1280 bytes addr 0x952cd2 stack 0x1700b00 (0x1700000-0x1701000-0x1800000)
```

My Arch Linux install attempts to use wine to load up the python program. There are also issues quitting, and I end up having to use pkill to kill python. This is because my OS attempts to use [binfmt_misc](https://en.wikipedia.org/wiki/Binfmt_misc), and finds out that Wine is an acceptable program for launching ape binaries. ape binaries are not designed to run under wine, this behavior happens instead.

The way to avoid this is to use the [ape loader](https://justine.lol/apeloader/). 

```{.default}
[moonpie@lizard apeb]$ ./ape-x86_64.elf ./python
Python 3.12.3 (main, Aug  3 2024, 10:18:33) [GCC 14.1.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
``

And this works. But, although there is also a version of python distributed with many python libraries included, called `pypack1`, it doesn't contain some crucial python packages that I may need for ansible administration of systems, like sql manipulation tools. 

```{.default}
[moonpie@lizard apeb]$ ./ape-x86_64.elf ./python -m venv venv
Error: Command '['/home/moonpie/vscode/test/apeb/venv/bin/python', '-m', 'ensurepip', '--upgrade', '--default-pip']' returned non-zero exit status 1.
```

Yeah. I'm not too worried, because I wrote my roles so that the databse manipulation can also be done remotely, from a playbook running on localhost, but it would be simpler if everything can be run on the remote systems. 

```{.default}
[moonpie@lizard apeb]$ ./ape-x86_64.elf ./tmux
[moonpie@lizard apeb]$ ./ape-x86_64.elf ./tmux -h
tmux: unknown option -- h
usage: tmux [-2CDlNuvV] [-c shell-command] [-f file] [-L socket-name]
            [-S socket-path] [-T features] [command [flags]]
```

And tmux just won't load, although it will print the help output. I find this very weird, as I could get tmux to load earlier, but not now. It doesn't load on my host system, or in an Debian or Alpine container.

This only seems to apply to the ape tmux, as tmux installed by apt in a debian container doesn't have this issue, and then after that, tmux is able to start sessions normally, but then it can't again after I kill all sessions. At least this isolates it to an issue with ape. 

It could just be a bug of some sort, but the package version only updated 3 days ago from now (August 6th), so those haven't changed.

The weirdest thing is that the ape tmux is actually able to work normally... but only after I launch a session via  non-ape tmux. And then, one I kill all tmux sessions, then it stops working again.

It seems like the ape tmux is having trouble starting the server:

```{.default}
/stuff # ape ./tmux start-server
/stuff #
/stuff # ape ./tmux ls
no server running on /tmp/tmux-0/default
``` 

I found a [half relevant issue](https://github.com/tmux/tmux/issues/736), but the failed solution gives me more answers:

```{.default}
/stuff # ape ./tmux new-session -t testing -d
create window failed: fork failed: Operation not permitted
```

I eventually made a post on the redbean discord server, and uploaded my [strace to a github gist](https://gist.github.com/moonpiedumplings/809dcc89cfe289f8341aae85069a57e1). I'll wait to see if anyone replies.


```{.default}
[moonpie@lizard apeb]$ ./ape-x86_64.elf ./tmux new-session -d -vv
no server running on /tmp/tmux-1000/default
```

```{.default}
/stuff # ./ape-x86_64.elf ./tmux new-session -d -vv
no server running on /tmp/tmux-0/default
```

So tmux can be ran with -vv for something more verbose. 

This might also be a tmux bug, since the version of tmux provided by ape/cosmo is 3.3a, rather than the latest 3.4, however, the nix bundled tmux also has this issue, and nix has 3.4 of tmux.   

I played around with attempting to build newer versions of tmux from the [superconfigure](https://github.com/ahgamut/superconfigure?tab=readme-ov-file#how-can-i-build-these-locally) github repo, but their instructions don't seem to work. The scripts assume Ubuntu 22 LTS, although I was only able to find that out after looking at what distro was used in their github actions. 

## Openbsd

```{.default}
[vagrant@openbsd7 ~]$ ./ape ./python
Python 3.12.3 (main, Aug  3 2024, 10:18:33) [GCC 14.1.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
[vagrant@openbsd7 ~]$ ./ape ./tmux new-ession -d -vv
no server running on /tmp/tmux-1000/default
```

## NetBSD

```{.default}
[vagrant@netbsd8 ~]$ ./ape ./python
Python 3.12.3 (main, Aug  3 2024, 10:18:33) [GCC 14.1.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
[vagrant@netbsd8 ~]$ ./ape ./tmux new-session -d -vv
no server running on /tmp/tmux-1000/default
```

Vim executes successfully as well. It's able to execute without the ape interpeter, but python crashes when I try to do that.

## DragonflyBSD

We've seen this FreeBSD fork in the competition environment. But, DragonFlyBSD was forked from FreeBSD 4.8, which was nearly 21 years ago. At this point, they have diverged to the point where ape binaries do not run on Dragonfly. Cosmo does not officially support DragonflyBSD, and it's highly likely that there are other differences, like the `pf` firewall configuration file having different syntax.

```{.default}
[vagrant@dragonflybsd6 ~]$ ./ape ./python
ELF binary type "9" not known.
```

## FreeBSD

I intend to test, but vagrant networking is giving me trouble. Cosmo should work with FreeBSD though.

# Nix bundle

`nix bundle nixpkgs#programname` is a command that bundles a program into a self extracting archive that uses proot to run itself. A big problem with nix bundle is that it mostly only works on Linux, and relying on proot makes it less portable compared to ape. [Here is the official manual](https://nix.dev/manual/nix/2.13/command-ref/new-cli/nix3-bundle)... on an unofficial site. 

```{.default}
[moonpie@lizard apeb]$ nix bundle nixpkgs#zellij
[moonpie@lizard apeb]$ ls -la zellij
lrwxrwxrwx 1 moonpie moonpie 47 Aug  6 22:28 zellij -> /nix/store/5d5fi0x4g7v33m7jscxwjijaxi3lg2kp-arx
```

One thing that is mildly annoying is that nix builds stuff in the nix store, and then symlinks to it from the outside, meaning you have to copy out the binary first.

The first thing I tried to do was bundle zellij and tmux, and funnily enough, they run into the exact same issue as ape. If I launch a zellij or tmux session using a non-ape, non nix-bundled session, first, then I can use the nix bundled zellij or tmux normally.

# Guix pack

Guix pack is different. Rather than doing self extracting or staticly compiled executables, it generates a tarball (or docker image, but I'm focused on tarball), which can be extracted and has the programs with a vendored dependency. 

I found a [docker container for guix](https://hub.docker.com/r/metacall/guix), which is good because I'd rather run guix entirely in a podman container in my home volume, to avoid snapshotting guix in btrfs snapshots of the root subvolume. 

`podman run -it --rm -v ".:/stuff" --privileged`

I had to run it with --privileged, otherwise the guix builder fails. 

Once inside, the `guix pack` command packs programs into a tarball. [Documentation](https://guix.gnu.org/manual/en/html_node/Invoking-guix-pack.html) 

`guix pack -RR tmux` generates a tarball... but I'm struggling to run it outside the store. 

# Appimage

Appimages are good, but with a few caveats: They only work on Linux, and they require fuse2 (not fuse3, but fuse2) to run, and they rely on the same version of glibc.

There are some [prebuilt appimages for tmux](https://github.com/tmux/tmux/wiki/Installing#appimage-package) and it works fine after I install fuse2. 

# Static Compilation

## Tmux

[tmux has instructions for installing](https://github.com/tmux/tmux/wiki/Installing).

`apk add git gcc musl-dev openssl-dev openssl-libs-static openssl ncurses-terminfo`

After these packages are installed, compiling tmux staticly will work. (it should be noted that the instructions assume you use the relase tarball, rather than directly from the source code). 

```{.default}
./configure --enable-static

make
```

However:

```{.default}
/stuff # ./stmux
can't find terminfo database
```

The staticly compiled tmux doesn't include ncurses and terminfo libraries. After installing `ncurses-terminfo` then it works fine.

Apparently it's possible to staticly bundle ncurses, libevent, and tmux, but it's an even more involved process. Users must compile ncurses, which generates .a files and then link those to tmux when compiling using LIBS and -l flag to link it.

## Zellij

```{.default}
git clone https://github.com/zellij-org/zellij/

podman run -it --rm -v "./zellij:/zellij" docker.io/library/rust:alpine3.18

apk add openssl1.1-compat openssl1.1-compat-dev openssl1.1-compat-libs-static musl-utils musl-dev protoc # but only for alpine 3.18

alternatively: apk add openssl openssl-libs-static openssl-dev musl-utils musl-dev protoc

cd /zellij

rustup target add x86_64-unknown-linux-musl

rustup target add wasm32-wasi

RUSTFLAGS="-C target-feature=+crt-static" OPENSSL_NO_VENDOR="1" cargo build --target x86_64-unknown-linux-musl  


/stuff/zellij # RUSTFLAGS="-C target-feature=+crt-static" OPENSSL_NO_VENDOR="1" cargo xtask build
error: cannot produce proc-macro for `prost-derive v0.11.9` as the target `x86_64-unknown-linux-musl` does not support these crate types
```

This still crashes for now, but I need to figure out how to compile it if I want to target other BSD's.

`error: couldn't read /stuff/zellij/zellij-utils/../target/wasm32-wasi/debug/compact-bar.wasm: No such file or directory (os error 2)`

Let's try debian, since it seems they do their official builds — even musl ones — on ubuntu. 

```{.default}

podman run -it --rm -v "./zellij:/zellij" docker.io/library/rust:bookworm

apt update && apt install musl-tools protobuf-compiler

rustup target add x86_64-unknown-linux-musl

rustup target add wasm32-wasi

cargo xtask ci cross x86_64-unknown-linux-musl   # This crashes

cargo build --verbose --release --target x86_64-unknown-linux-musl # This works

rustup target add x86_64-unknown-netbsd

cargo build --verbose --release --target x86_64-unknown-netbsd
 error occurred: Failed to find tool. Is `x86_64--netbsd-gcc` installed?
```

So it seems like cross compilation support isn't too good. 

Then I tried with the alpine container in the same directory:

```{.default}

apk add openssl openssl-libs-static openssl-dev musl-utils musl-dev protoc gcc-cross-embedded

rustup target add wasm32-wasi

rustup target add x86_64-unknown-netbsd

RUSTFLAGS="-C target-feature=+crt-static" OPENSSL_NO_VENDOR="1" OPENSSL_INCLUDE_DIR="/usr/include/openssl" OPENSSL_LIB_DIR="/usr/lib" cargo build --target x86_64-unknown-freebsd

```

This is much closer, but doesn't work.  

```{.default}
note: /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lexecinfo: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lkvm: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lmemstat: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lkvm: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lprocstat: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -ldevstat: No such file or directory
          /usr/lib/gcc/x86_64-alpine-linux-musl/13.2.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lexecinfo: No such file or directory
          collect2: error: ld returned 1 exit status
```

Zellij already ships a [static version on their releases](https://github.com/zellij-org/zellij/releases) (zellij-x86_64-unknown-linux-musl.tar.gz). From my testing, it only runs on Linux.


## Python

* <https://github.com/indygreg/python-build-standalone> / <https://gregoryszorc.com/docs/python-build-standalone/main/>
* <https://pyoxidizer.readthedocs.io/en/latest/pyoxy.html>
* <https://wiki.python.org/moin/BuildStatically> — not as promising
* <https://github.com/RustPython/RustPython>
  - Not [feature complete](https://rustpython.github.io/pages/whats-left)

Also, I just want to note about python, that `help('modules')` in an interactive shell will list all the modules that a python interpreter is able to access. With statically compiled versions of python, this shows what python libraries have been bundled with the library. 
      

### IndyGreg Python

```{.default}
usage: build-main.py [-h]
                     [--target-triple {s390x-unknown-linux-gnu,x86_64_v4-unknown-linux-gnu,ppc64le-unknown-linux-gnu,x86_64_v2-unknown-linux-gnu,i686-unknown-linux-gnu,x86_64_v3-unknown-linux-gnu,x86_64-unknown-linux-musl,x86_64-unknown-linux-gnu,armv7-unknown-linux-gnueabihf,armv7-unknown-linux-gnueabi,x86_64_v4-unknown-linux-musl,mipsel-unknown-linux-gnu,x86_64_v3-unknown-linux-musl,mips-unknown-linux-gnu,aarch64-unknown-linux-gnu,x86_64_v2-unknown-linux-musl}]
                     [--optimizations {lto,pgo+lto,noopt,pgo,debug}] [--python {cpython-3.10,cpython-3.11,cpython-3.8,cpython-3.12,cpython-3.9}] [--python-source PYTHON_SOURCE]
                     [--break-on-failure] [--no-docker] [--serial]
                     [--make-target {default,toolchain-image-xcb,toolchain-image-build,empty,toolchain-image-xcb.cross,toolchain-image-gcc,toolchain,toolchain-image-build.cross}]
build-main.py: error: argument --target-triple: invalid choice: 'x86_64-unknown-freebsd' (choose from 's390x-unknown-linux-gnu', 'x86_64_v4-unknown-linux-gnu', 'ppc64le-unknown-linux-gnu', 'x86_64_v2-unknown-linux-gnu', 'i686-unknown-linux-gnu', 'x86_64_v3-unknown-linux-gnu', 'x86_64-unknown-linux-musl', 'x86_64-unknown-linux-gnu', 'armv7-unknown-linux-gnueabihf', 'armv7-unknown-linux-gnueabi', 'x86_64_v4-unknown-linux-musl', 'mipsel-unknown-linux-gnu', 'x86_64_v3-unknown-linux-musl', 'mips-unknown-linux-gnu', 'aarch64-unknown-linux-gnu', 'x86_64_v2-unknown-linux-musl')
[moonpie@lizard python-build-standalone]$ ./build-linux.py --target x86_64-unknown-freebsd
```

No freebsd or other non-linux support. 

## Coreutils

* <https://github.com/uutils/coreutils>
* <https://packages.debian.org/sid/busybox-static>
* <https://busybox.net/FAQ.html> — looks like busybox releases are already staticly linked, but they mostly focus on Linux releases
* <https://github.com/ahgamut/superconfigure/releases/> — this is cosmo. I would prefer a single binary though, for simplicity, rather than seperate staticly compiled coreutils which is what this is. But, if in a pinch, it makes a good replacement for a broken coreutil.

            
## Toolpacks

I recently learned about a new project, called [Toolpacks](https://github.com/Azathothas/Toolpacks). Toolpacks is a truly massive set of static binaries, with so many utilities, including zellij, tmux, ssh, and many others. I see 2292 binaries for x86_64 Linux, and good amounts for Windows and Arm Linux as well. 

Another cool thing about Toolpacks is that they also provide [UPX](https://en.wikipedia.org/wiki/UPX) versions of the software they distribute. UPX is a method of creating self extracting, compressed binaries that further saves space. For example:

```{.default}
[moonpie@lizard toolpack]$ du -sh zellij
30M     zellij
[moonpie@lizard toolpack]$ du -sh zellij.upx
8.6M    zellij.upx
```

That's a pretty big reduction on the zellij binary, which is one of the largest binaries I've seen. Interesting, they also have caddy, and nginx. I find this very promising.

There are also builds of busybox or toybox, which could replace coreutils in a pinch on Linux machines. There are a few other interesting one's, such as [nmap-formatter](https://github.com/vdjagilev/nmap-formatter), a software that can format nmap XML output and convert it to CSV or other formats, which we may find easier to submit.



# Dockerc

[Dockerc](https://github.com/NilsIrl/dockerc) is a project that compiles a docker container to a static executable, by bundling the runtime. I discovered this because it was packaged on the Toolpacks listed above.

Because it is a container, I'm going to assume that this solution only works on Linux — but that doesn't mean it's not useful.

```{.default}
vagrant@debian10:~$ sudo dockerc --image docker://library/httpd -o httpd --rootfull
vagrant@debian10:~$ sudo ./httpd
unknown argument ignored: lazytime
AH00557: httpd: apr_sockaddr_info_get() failed for umoci-default
AH00557: httpd: apr_sockaddr_info_ge....
```

And it works — kinda. httpd doesn't seem to bind an address. However, if I use an alpine container (which starts a shell), and then test with `python -m http.server`, that binds an address to the same localhost as the alpine machine. 

```{.default}
sudo dockerc --image docker://docker.io/library/nginx --output nginx --rootfull

sudo ./nginx
```

This also does not bind ports. 

# Less promising options

## pkgin

<https://pkgin.net/>

Pkgin is a package manager that can manage packages compiled by [pkgsrc](https://www.pkgsrc.org/). It works on multiple BSDs (including Dragonfly), Macos, and Debian Linux. I don't think we'll ever see OpenSolaris but we'll see.
