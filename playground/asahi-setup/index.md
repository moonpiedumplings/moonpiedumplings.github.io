---
title: "Asahi Linux"
date: "2026-1-21"
categories: [playground]
execute:
  freeze: false
draft: true
---


I have decided to setup [Asahi Linux](https://asahilinux.org/), which is the Linux for M1 Macs. My sister gave me her old Macbook Air (2020), and it has an M1 and 8 gb of ram. 

After removing all the stickers, it will become my daily driver device. 


# Initial Install

The install is pretty easy, as the install script that you run from MacOS just works. Sadly, it does not come with full disk encryption, which I had to enable. I fiddled with USB boot, but eventualy I couldn't get it working, and I also wasn't really interesting in doing open heart surgery and trying to encrypt the system in place.

Eventually, I decided to install two Asahi partitions. One was a "minimal" type install, and the other was my regular KDE. 

From the minimal install, I ran <https://github.com/osx-tools/asahi-encrypt> on the regular install, and full disk encryption with LUKS was enabled. 

In addition to that, I had to do further steps. I created more subvolumes, for /nix and /var, so that they wouldn't be caught in the 


```{.default filename='in the minimal install'}
cryptsetup open /dev/mainroot root

mount /dev/mapper/root /mnt

btrfs subvolume create /mnt var

btrfs su cre /mnt nix

cp /mnt/root/var/* /mnt/var/
```

And then I edited the fstab file to contain the new subvolumes. I also amped up the zstd compression, from 1 to 3, since my Macbook only has 256 gb of storage total, and the Linux root partition is only 160 gb. 

```{.default filename='/mnt/root/etc/fstab'}
UUID=rootuuid / btrfs x-systemd.growfs,compress=zstd:3,defaults,subvol=root 0 1
UUID=bootuuid /boot ext4 defaults 0 0
UUID=rootuuid /home btrfs x-systemd.growfs,compress=zstd:3,subvol=home 0 0
UUID=rootuuid /nix btrfs compress=zstd:3,subvol=nix 0 0
UUID=rootuuid /var btrfs compress=zstd:3,subvol=var 0 0
UUID=efiuuid /boot/efi vfat defaults,umask=0077,shortname=winnt 0 0
/var/swap/swapfile swap swap sw 0 0
```

After making these changes I rebooted and it worked. I then proceeded to install timeshift as an easy way to redo/undo my tinkering, like the changes I make below.


# Memory Optimization

I really want 4 firefox sessions open and two vscode sessions open at once. I know it's possible. I don't want to give my normal workflow up. 

## Zswap

Zswap doesn't seem to be as effective by default, so I decided to tinker it with it a bit. 

```{.default filename='/etc/tmpfiles.d/asahi-enable-zswap.conf'}
#Type Path                                            Mode UID  GID  Age  Content
w     /sys/module/zswap/parameters/max_pool_percent   -    -    -    -    50
w     /sys/module/zswap/parameters/zpool              -    -    -    -    zsmalloc
w     /sys/module/zswap/parameters/enabled            -    -    -    -    Y
w     /sys/module/zswap/parameters/compressor         -    -    -    -    zstd
```

<https://github.com/Flisk/zswapstat>

```{.default}
stored_pages           170842
pool_total_size        601358336
written_back_pages     761753
decompress_fail        0
reject_compress_poor   0
reject_compress_fail   50432
reject_kmemcache_fail  0
reject_alloc_fail      0
reject_reclaim_fail    41
pool_limit_hit         0

compressed             573.5 MiB
uncompressed           2669.4 MiB
space_savings          0.785
```

I don't see anywhere near as aggressive space savings as I did when I used zram on other devices. In addition to that, all swap is slowly consumed before I begin to hit an OOM.

```{.default}
NAME               TYPE SIZE USED PRIO
/var/swap/swapfile file   8G   8G   -2
```

I *could* add more swap. But I know it's possible to fit a lot more data into ram.

##  Zram


I switched to Zram, because zram's compression is really impressive:

```{.default}
NAME       ALGORITHM DISKSIZE  DATA COMPR TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd         11.7G  7.3G  1.7G  1.7G         [SWAP]
```


Assuming decompressing data from ram is faster than reading from disk, it is quite a bit of swap. I no longer encounter any OOM's after switching to zram. At least not before I try 5 firefox sessions and 3 vscode's up at once.

To switch to zram, firstly zswap needs to be disabled:

```{.default filename='/etc/tmpfiles.d/asahi-enable-zswap.conf'}
#Type Path                                            Mode UID  GID  Age  Content
w     /sys/module/zswap/parameters/max_pool_percent   -    -    -    -    50
w     /sys/module/zswap/parameters/zpool              -    -    -    -    zsmalloc
w     /sys/module/zswap/parameters/enabled            -    -    -    -    N
```

The last "N" used to be "Y", which is what I have changed.

To enable zram:

`sudo dnf install zram-generator`

And then the settings I used 

```{.ini filename='cat /etc/systemd/zram-generator.conf'}
[zram0]
zram-size = 12000
compression-algorithm = zstd(level=3)
```

Howevever, zram has some flaws. For example, when zram is full, the extra data from ram will spill over into swap instead. Another problem is that zram doesn't use swap at all. Often, programs will put pages in memory that they only need as part of the startup process. Keeping those in memory forever is annoying. Swap lets the kernel move those not needed things onto the disk, freeing up more ram. See also <https://chrisdown.name/2018/01/02/in-defence-of-swap.html>.

A good way to get around this is via zram's option for a backing device. However, unlike zswap it is not automatic. The backing device can automatically track `idle`, or untouched pages, but this needs a kernel option only set at compile time, that the asahi kernel does not come with this. 

This does have to be set up manually for now, since I don't have a partition. 

```{.default}
swapoff /dev/zram0

losetup -f /var/swap/zrambacker.img

echo /dev/loop0 > /sys/block/zram0/backing_dev

swapon /dev/zram0
```


<https://docs.kernel.org/admin-guide/blockdev/zram.html#idle-pages-tracking>

For preliminary testing, I did have to set up the loopback device manually, and then reset zram before assinging it the backing device.

But despite this, it still requires manual intervention to actually do the process of pushing pages. 

`echo all > /sys/block/zram0/idle`

Sadly I cannot push a number instead . I must mark all pages as all, then push them to disk. This still works though.

`echo idle > /sys/block/zram0/writeback`

And then indle pages are pushed to disk after a few seconds.

To check how much is on the disk: 

`awk '{printf "%.2f GiB\n", $1 * 4096 / 1024 / 1024 / 1024}' /sys/block/zram0/bd_stat`

```
root@sobek:/sys/block/zram0# awk '{printf "%.2f GiB\n", $1 * 4096 / 1024 / 1024 / 1024}' /sys/block/zram0/bd_stat
3.90 GiB
```

It would make sense for this to be an optimization that distros designed for more optimized memory usage. A custom daemon could regularly push pages that were idle for too long. I think this is what Android does to make zram work. Or maybe Android operates entirely in ram and doesn't touch swap to avoid writes to the disk, I know that can be a concern on lower quality solid state/flash devices. Although, this is less of a concern because zram pushes compressed data to the disk, unlike a traditional swap setup.


One disappointing thing is that zram seems to count data pushed to disk as stored on the zram disk device, rather than being seperate. This means there is no way to individually measure except to look at `bd_stat` and substract from zram. It just doesn't count this data as compressed data. 


# Podman Machine

I attempted to run Microsoft's SQL in a container, and although an arm version is supplied, it errors:

```{.default}
moonpie@sobek:~/vscode/home-manager$ podman run -e "ACCEPT_EULA=1" -e "MSSQL_SA_PASSWORD=MyStrongPass123" -e "MSSQL_PID=Developer" -e "MSSQL_USER=SA" -p 1433:1433 -d --name=sql mcr.microsoft.com/azure-sql-edgeTrying to pull mcr.microsoft.com/azure-sql-edge:latest...
911ec509fd6e8a06777fd929f32066c1303ea9cbea3391898d823fa4c6a75aa3
moonpie@sobek:~/vscode/home-manager$ podman logs sql 
Azure SQL Edge will run as non-root by default.
This container is running as user mssql.
To learn more visit https://go.microsoft.com/fwlink/?linkid=2140520.
2026/01/22 18:33:18 [launchpadd] INFO: Extensibility Log Header: <timestamp> <process> <sandboxId> <sessionId> <message>
2026/01/22 18:33:18 [launchpadd] WARNING: Failed to load /var/opt/mssql/mssql.conf ini file with error open /var/opt/mssql/mssql.conf: no such file or directory
2026/01/22 18:33:18 [launchpadd] INFO: DataDirectories =  /bin:/etc:/lib:/lib32:/lib64:/sbin:/usr/bin:/usr/include:/usr/lib:/usr/lib32:/usr/lib64:/usr/libexec/gcc:/usr/sbin:/usr/share:/var/lib:/opt/microsoft:/opt/mssql-extensibility:/opt/mssql/mlservices:/opt/mssql/lib/zulu-jre-11:/opt/mssql-tools
2026/01/22 18:33:18 Drop permitted effective capabilities.
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
Error in GnuTLS initialization: ASN1 parser: Element was not found.
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
<jemalloc>: Unsupported system page size
Out of memory allocating bitmask: Cannot allocate memory
```

Apparently, jemalloc is often compiled to work on only 4k page systems, whereas the M Mac's use a 16k page size. So it results in a crash. 

The easiest way to get around this seems to be with podman's virtual machine, that isn't really designed for native linux systems but I think it will work here.

However, because nobody ever expected that someone would use the tool designed to virtualize linux on Mac/NonLinux systems to run containers on a Linux system, the podman package does not pull in, or even mention any of the dependencies needed to start the podman machine.

```{.default}
gvisor-tap-vsock
virtiofsd
```

In addition to that, podman machine must be told where to find the virtiofsd binary.

```{.default filename='}
[engine]

helper_binaries_dir = [
  "/usr/local/libexec/podman",
  "/usr/local/lib/podman",
  "/usr/libexec/podman",
  "/usr/libexec",
  "/usr/lib/podman",
]
```

```{.default}
podman machine init 

podman machine start
```

And then a podman virtual machine starts. I can run `podman machine ssh podman-machine-default` to enter into it, or I can point the docker or podman socket at it. 

Overall, I find this deeply ironic. podman machine was originally designed for MacOS users to run a Linux virtual machine, so they could use Linux containers. But instead, I am have to use it on Linux on my Macbook so I can run Linux containers due to a mismatch in page size which makes things incompatible anyways. I was so excited about not needing a virtual machine but I needed one anyway :P.

`sudo dnf install docker` 

And then to use the docker cli with the podman machine:

`export DOCKER_HOST='unix:///run/user/1000/podman/podman-machine-default-api.sock'`

Then, you can run docker containers with volume mounts, port forwarding, etc from the asahi host, but they actually run in the virtual machine. Ideally, I shouldn't need to do this for arm 

# Misc Notes

These are miscellanous notes for myself, for smaller one off tasks. 

Since the grub config is in a different spot, and Fedora doesn't come with an `update-grub` script or equivalent, regenerating the grub config must be done manually:

`sudo grub2-mkconfig -o /boot/boot/grub2/grub.cfg`

Extracting passwords from my old firefox profiles can be done with [firefox_decrypt](https://github.com/unode/firefox_decrypt/). 

And then this can be ran, pointed at a firefox profile folder and it will spit out passwords. Actually, I later found someting better, it's possible to run `firefox --profile folder` directly on a folder to continue to use the profile.

Sadly Fedora KDE's Dolphin does not seem to come with the right click > New Libreoffice Writer that I am used to. However, I have realized that ODT documents seem to be empty by default, so simply by creating an empty text file named `*.odt`, libreoffice can open it. 
