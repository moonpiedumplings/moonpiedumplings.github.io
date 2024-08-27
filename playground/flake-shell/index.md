---
title: "Creating a nix flake shell, the \"proper\" way"
date: "2024-6-21"
categories: [nix, _playground]
# draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
execute:
  freeze: auto
---

So, I think it's time for me to move from the older channels way of doing things in nix, to the newer flakes. I am using the [determinate system nix installer](https://github.com/DeterminateSystems/nix-installer), which only comes with flakes. However, the nix docs are very poor, so I am going to document my process of converting my development environment here. 

The first thing, is that despite the fact that there is a lot of the existing flakes use a utility called [flake-utils](https://github.com/numtide/flake-utils). However, this tool was ultimately started as an experiment, and has issues. A [blog post](https://ayats.org/blog/no-flake-utils/) ([archive](https://web.archive.org/web/20240229094244/https://ayats.org/blog/no-flake-utils/)) goes over some of the issues it has, and recommends against it... except I can't figure out at all how to apply it. 
          
The other recommendation is another pattern, recommended by Reddit user Tomberek:

```{.nix}
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/22.05";
  outputs = {self,nixpkgs}: {
    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        shellHook = ''
          echo 'WARNING: gotcha during nix develop shellHooks'
          function _direnv_hook(){
              echo 'WARNING, "_direnv_hook" has been overwritten"'
          }
        '';
        packages = [
          (pkgs.writeShellApplication {
            name = "ls";
            text = ''
              echo 'WARNING, "ls" has been overwritten"'
            '';
          }
            )
        ];
      };
    }) nixpkgs.legacyPackages;
  };
}
```

There are multiple different ways of creating an output for multiple systems at once, it seems. 

So far:

* ForEachSystem
* Flake-parts
* Flake-utils
* Tomberek's method

I suspect there are other methods, potentially better one's, that aren't documented. However, because of the [no-flake-utils](https://ayats.org/blog/no-flake-utils/) blogpost, where the author suggests to use pure nix and no libraries, I have decided to opt for that approach.

My ultimate goal is to convert the shell.nix I am using, into a flake. 


I have a simple outline:

```{.nix filename='flake.nix'}
{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, ...}: let

    pkgs = import nixpkgs {};

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            inputs.something.overlays.default
          ];
        }));

  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ 
            nodePackages_latest.npm
            quarto
            ];
  };
  };
}
```

After some tinkering, I get this to at least load, and not give me a syntax error. Instead, it gives me a different error:

`error: flake 'git+file:///home/moonpie/vscode/test/flake-test' does not provide attribute 'packages.x86_64-linux.default' or 'defaultPackage.x86_64-linux'`

I find this odd, since I provide a devshell. However, I realized that the other command to get a reproducible shell environment, `nix develop`, might be what is used instead to call upon the `devShells` attribute. 

```{.default}
[moonpie@lizard flake-test]$ nix develop
error:
       … while evaluating a branch condition
         at /nix/store/2yb39wmx10a5lsm4d2jj7c6h94h36spi-source/pkgs/stdenv/booter.nix:64:9:
           63|       go = pred: n:
           64|         if n == len
             |         ^
           65|         then rnul pred

       … while calling the 'length' builtin
         at /nix/store/2yb39wmx10a5lsm4d2jj7c6h94h36spi-source/pkgs/stdenv/booter.nix:62:13:
           61|     let
           62|       len = builtins.length list;
             |             ^
           63|       go = pred: n:

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: attribute 'currentSystem' missing
       at /nix/store/2yb39wmx10a5lsm4d2jj7c6h94h36spi-source/pkgs/top-level/impure.nix:17:43:
           16|   # (build, in GNU Autotools parlance) platform.
           17|   localSystem ? { system = args.system or builtins.currentSystem; }
             |                                           ^
           18|
```

What's the difference between nix shell and nix develop? From my understanding, `nix develop` is designed for developing packages, as it brings in build dependencies, rather than only runtime dependencies. It's because of this, that I want `nix shell` to work instead, because that command seems to be focused more on simply getting the tools I want. 

Except, according to some comparisons I found online, [nix shell can't even adjust environment variables](https://discourse.nixos.org/t/difference-between-nix-shell-nix-shell-nix-develop/32469/4). Now of course, a single forum reply is *not* documentation... but nix's documentation is very poor, and this is a common frustration, being forced to rely on forum posts rather than official documentation for information.

The [official docs](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-shell) talk about using `nix shell` as a command line program, but not at all how it interacts with flakes and .nix files. 

I got something that works for `nix develop`

```{.nix filename='flake.nix'}
{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, ...}: let

    pkgs = import nixpkgs {};

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

  in {

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [ 
            nodePackages_latest.npm
            quarto
            ];
      };
    });
    packages = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
            nodePackages_latest.npm
            quarto
            ];
      };
    });
  };
}
```

`nix develop` works fine, except it takes a long time to setup on the first run, compared to `nix-shell -p quarto nodePackages_latest.npm`. I wonder if this is because, since `nix develop` is designed for development purposes, it pulls in more dependencies than `nix-shell` does. 

`nix shell` doesn't work at all. It gives me a different shell, and adds things to the path, but it doesn't actually add any of the programs I specify to the path. 

(Also, I still have another unanswered question: What does the `@` symbol mean in a nix expression).

I later went and [found an answer](https://nix.dev/tutorials/nix-language.html#named-attribute-set-argument). `@` *names* the attribute set 


I managed to get `nix shell` working... somewhat.

```{.nix filename='flake.nix'}
{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, ...}: let

    pkgs = import nixpkgs {};

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

  in {
packages = forAllSystems (pkgs: {
      default = pkgs.jupyter;
    });
  };
}
```

And this makes the `jupyter` command available to me in my shell, and the library I called upon. But, this doesn't seem scalable. How do I get this to do more packages? How do I get this to do environment variables? And is this really better than `nix develop`?

I started to do some testing. The big problem, I've found with nix develop, is that since it is designed for development, it brings in development dependencies, regardless of the fact that I am *not* doing development, and am instead just aiming for a reproducible shell environment. 

```{.nix}
devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
#         packages = with pkgs; [
#             jupyter
#            ];
        buildInputs = with pkgs; [ jupyter ];
      };
```

Results in:

<details><summary>Show path</summary>

```{.default}
[moonpie@lizard flake-test]$ nix develop
warning: Git tree '/home/moonpie/vscode/test/flake-test' is dirty
evaluating derivation 'git+file:///home/moonpie/vscode/test/flake-test#devShells.x86_64-linux.default'
(nix:nix-shell-env) [moonpie@lizard flake-test]$ echo $PATH
/nix/store/pdqndw2kgjv8l3kd5ii0c833jqmxdanq-patchelf-0.15.0/bin:/nix/store/mpm3i0sbqc9svfch6a17179fs64dz2kv-gcc-wrapper-13.3.0/bin:/nix/store/zc0nsv23pakbafngjy32kvhfzb16as43-gcc-13.3.0/bin:/nix/store/082x03cmpnsqkfp4ljrhsadz68rh3q1h-glibc-2.39-52-bin/bin:/nix/store/i7qhgc0bs725qw3wdanznfkdna4z2ns2-coreutils-9.5/bin:/nix/store/l46fjkzva0bhvy9p2r7p4vi68kr7a1db-binutils-wrapper-2.41/bin:/nix/store/wwfrj9kvfi14xclc38qfwm71ah6aawdh-binutils-2.41/bin:/nix/store/hn4bklvwvjjhkqy8d5npgb0aq8hba27s-python3-3.11.9-env/bin:/nix/store/i7qhgc0bs725qw3wdanznfkdna4z2ns2-coreutils-9.5/bin:/nix/store/rr1yixvn0z63mgq9s04ig9j9qlz23s2g-findutils-4.9.0/bin:/nix/store/j4gkc44c1pwl5ccgxm83s4r746bsdcw9-diffutils-3.10/bin:/nix/store/ks6c62g0m3gqrs5i7m0cv6d6aqhdvirn-gnused-4.9/bin:/nix/store/md9apn3290h7kv0x198ihaaa3k6icg4b-gnugrep-3.11/bin:/nix/store/hkx0wcm23i9ihqlysri8n41kl232kawb-gawk-5.2.2/bin:/nix/store/95ljdxg4drk1iq8jkjfq2c0z5vbwv8vm-gnutar-1.35/bin:/nix/store/nc9lq1lra01932rfyclq3gsh82cxbmii-gzip-1.13/bin:/nix/store/cyc3v8qfkhn4r38a8s5d7f2c33q624mz-bzip2-1.0.8-bin/bin:/nix/store/18z454gyz0wpb641rw6gpqk0vi4wbxy6-gnumake-4.4.1/bin:/nix/store/agkxax48k35wdmkhmmija2i2sxg8i7ny-bash-5.2p26/bin:/nix/store/r05c0lpbnjc8dg3rrr3ck7s07pjy86j3-patch-2.7.6/bin:/nix/store/qqhrymypl970jc6npvi9a6sikhr84mdf-xz-5.4.6-bin/bin:/nix/store/qcqmiq1mb3pkk2bxbj6d6gb2fk9knk8l-file-5.45/bin:/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
```

</details>

Compared to the same thing for nix shell:

```{.nix}
packages = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        #packages = with pkgs; [ jupyter ];
        buildInputs = with pkgs; [ jupyter ];
        TEST_ENV = "test environment variable";
      };
```

<details><summary>Show path</summary>

```{.default}
[moonpie@lizard flake-test]$ nix shell
warning: Git tree '/home/moonpie/vscode/test/flake-test' is dirty
evaluating derivation 'git+file:///home/moonpie/vscode/test/flake-test#packages.x86_64-linux.default'
[moonpie@lizard flake-test]$ echo $PATH
/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/nix/store/i4zy8833s3dxrk3dmzb29k3y6rik15a4-nix-shell/bin:/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/moonpie/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
```

</details>

However...

```{.default}
[moonpie@lizard flake-test]$ echo $TEST_ENV

```

And nothing. (no reply to that command means the environment variable is unset). `nix shell` does not seem to set environment variables at all, even if I set them in the `pkgs.mkShell`, compared to `nix develop`, which does that. 

However, I don't want to bring *every* single build dependency as just for my shell environments. 

I did more testing with the various [types of dependencies](http://ryantm.github.io/nixpkgs/stdenv/stdenv/#ssec-stdenv-dependencies-reference) that a `pkgs.mkShell` (or more accurately, what it abstracts, `stdenv.mkDerivation`), and every single type of them brings build dependencies. This is a feature of nix develop, but it is becoming a hindrance. 

Nevermind. Apparently, `nix-shell` also brings in build dependencies, and behaves identically to `nix develop`, and completely unlike `nix shell`. Some part of me wonders if there is some way to get this working. Another part of me doesn't care. 

Since I have something working, I modified the [super fast nix shell](https://nixos.wiki/wiki/flakes#Super_fast_nix-shell) example to not use flakes. 

```{.nix}
{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, ...}: let

    pkgs = import nixpkgs {};

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

  in {

    devShells = forAllSystems (pkgs: {
      default = import ./shell.nix { inherit pkgs; };
    });
  };
}
```

This errors:

<details><summary>Show errors</summary>

```{.default}
[moonpie@lizard moonpiedumplings.github.io]$ nix develop
warning: Git tree '/home/moonpie/vscode/moonpiedumplings.github.io' is dirty
warning: creating lock file '/home/moonpie/vscode/moonpiedumplings.github.io/flake.lock':
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/3f84a279f1a6290ce154c5531378acc827836fbb?narHash=sha256-u1fA0DYQYdeG%2B5kDm1bOoGcHtX0rtC7qs2YA2N1X%2B%2BI%3D' (2024-06-13)
warning: Git tree '/home/moonpie/vscode/moonpiedumplings.github.io' is dirty
error:
       … while calling the 'import' builtin
         at /nix/store/jd6fy6iw7fsj0135phhd7awmq5s00sgj-source/flake.nix:22:17:
           21|     devShells = forAllSystems (pkgs: {
           22|       default = import ./shell.nix { inherit pkgs; };
             |                 ^
           23|     });

       … while evaluating the file '/nix/store/jd6fy6iw7fsj0135phhd7awmq5s00sgj-source/shell.nix':

       … while calling the 'import' builtin
         at /nix/store/jd6fy6iw7fsj0135phhd7awmq5s00sgj-source/shell.nix:2:12:
            1| let
            2|     pkgs = import <nixpkgs> {};
             |            ^
            3|

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: cannot look up '<nixpkgs>' in pure evaluation mode (use '--impure' to override)
[moonpie@lizard moonpiedumplings.github.io]$ nix develop --impure
warning: Git tree '/home/moonpie/vscode/moonpiedumplings.github.io' is dirty
error: attempt to call something which is not a function but a set: { type = "derivation"; PYTHONPATH = «thunk»; QUARTO_PANDOC = «thunk»; QUARTO_PYTHON = «thunk»; __ignoreNulls = true; __structuredAttrs = «thunk»; all = «thunk»; args = «thunk»; buildInputs = «thunk»; buildPhase = "{ echo \"------------------------------------------------------------\";\n  echo \" WARNING: the existence of this path is not guaranteed.\";\n  echo \" It is an internal implementation detail for pkgs.mkShell.\";\n  echo \"------------------------------------------------------------\";\n  echo;\n  # Record all build inputs as runtime dependencies\n  export;\n} >> \"$out\"\n"; «36 attributes elided» }
       at /nix/store/0symal17vrawjkdmbp0afyrz45ax5fay-source/flake.nix:22:17:
           21|     devShells = forAllSystems (pkgs: {
           22|       default = import ./shell.nix { inherit pkgs; };
             |                 ^
           23|     });
```

</details>


Okay, I got it. There was one change I needed to make. 

```{.default filename='shell.nix'}
let
    pkgs = import <nixpkgs> {};
    python3 = pkgs.python311;
```

In my shell.nix, I should have:

```{.nix filename='shell.nix'}
{ pkgs ? import <nixpkgs> {} }:

let
    python3 = pkgs.python311;
```

One last thing. What does the `@` symbol do? I suspect nothing. Kate (my IDE for nix testing), complains about the `input` binding being unused, so I am gussing it doesn't do anything. 

When I remove it, and replace that line with:

`outputs = {nixpkgs, ...}: let`

It works fine. 

After all of this, I did realize something. 

The configuration file for nix has an option called "extra-nix-path"

```{.nix filename='/etc/nix/nix.conf'}
build-users-group = nixbld
experimental-features = nix-command flakes repl-flake
auto-optimise-store = true
bash-prompt-prefix = (nix:$name)\040
max-jobs = auto
extra-nix-path = nixpkgs=flake:nixpkgs
upgrade-nix-store-path-url = https://install.determinate.systems/nix-upgrade/stable/universal
```

This option makes channel commands available and working, even though no nix channels are actually installed. Meaning, I could have continued to use `nix-shell`, and it would have worked...

Well, flakes still have their own benefits. The version of `nixpkgs` used is tracked in a `flake.lock` file in the git repo. This ensures reproducibility, as I would be able to update the version of `nixpkgs` for everyone using the repo, rather than having to rely on people updating their channels manually (running `nix-channel --update`). With the latter, channels will result in a different version of `nixpkgs` being used, but with flakes, everybody uses the same version of `nixpkgs`. 

However, I still would like to know if there is a way to not bring along every development dependency. 

Okay, I asked on the Nixos Discord about not bringing along every development dependency, and I was told that wasn't how `nix develop` worked. Rather, they claimed, the default `pkgs.mkShell` brings upon a "standard environment" of some build tools like gcc. Alternatively, you can use `pkgs.mkShellNoCC`. 

This actually, works, to an extent. Using [nix-tree](https://github.com/utdemir/nix-tree), I can analyze the disk space used by the various things downloaded by nix.


With the standard environment:

```{.default}
┌───────────────────────────────────────────┬───────────────────────────────────────────┬───────────────────────────────────────────┐
│nix-shell               7.49 GiB (7.49 GiB)│texlive-combined-full-2 6.24 GiB (5.62 GiB)│fonts.conf               3.64 GiB (3.1 KiB)│
│                                           │quarto-1.5.25          1.5 GiB (620.99 MiB)│texlive-combined-full-2 3.64 GiB (2.38 MiB)│
│                                           │python3-3.11.9-env  916.46 MiB (282.95 MiB)│texlive-combined-full-2 3.64 GiB (3.52 KiB)│
│                                           │stdenv-linux        332.93 MiB (166.29 KiB)│texlive-combined-full-2 3.64 GiB (3.45 GiB)│
│                                           │gcc-wrapper-13.3.0   312.31 MiB (60.92 KiB)│asymptote-2.88        1.24 GiB (660.91 MiB)│
│                                           │npm-10.8.1           310.91 MiB (97.35 MiB)│tlcockpit-1.2        1022.89 MiB (1.12 KiB)│
│                                           │gcc-13.3.0          274.27 MiB (223.02 MiB)│arara-7.1.3           966.03 MiB (1.14 KiB)│
│                                           │binutils-wrapper-2.41  86.52 MiB (50.1 KiB)│latex2nemeth-1.1.3       957.76 MiB (768.0)│
│                                           │binutils-2.41         71.24 MiB (31.32 MiB)│albatross-0.5.1       955.15 MiB (1.16 KiB)│
│                                           │diffutils-3.10         43.66 MiB (1.53 MiB)│texplate-1.0.4         953.4 MiB (1.14 KiB)│
│                                           │findutils-4.9.0        43.46 MiB (1.32 MiB)│bib2gls-3.9           952.17 MiB (1.99 KiB)│
│                                           │coreutils-9.5          42.13 MiB (2.12 MiB)│texosquery-1.7        950.24 MiB (2.35 KiB)│
│                                           │patchelf-0.15.0      40.02 MiB (234.31 KiB)│memoize-1.1.2        231.84 MiB (65.53 KiB)│
│                                           │file-5.45              39.42 MiB (8.33 MiB)│texlive-scripts-705 218.42 MiB (168.54 KiB)│
│                                           │gnutar-1.35            33.85 MiB (2.67 MiB)│texlive.infra-69740- 210.01 MiB (22.95 MiB)│
│                                           │gnugrep-3.11         33.68 MiB (922.61 KiB)│pygmentex-0.11       188.14 MiB (18.76 KiB)│
│                                           │glibc-2.39-52-bin       33.57 MiB (2.6 MiB)│pythontex-0.18      185.94 MiB (300.51 KiB)│
│                                           │gawk-5.2.2             33.54 MiB (2.57 MiB)│dvisvgm-3.2.2        184.64 MiB (50.79 MiB)│
│                                           │gzip-1.13             32.66 MiB (152.8 KiB)│lilyglyphs-0.2.4     175.43 MiB (24.97 KiB)│
│                                           │bash-5.2p26            32.51 MiB (1.54 MiB)│webquiz-5.2          173.81 MiB (44.94 KiB)│
│                                           │gnumake-4.4.1           32.47 MiB (1.5 MiB)│dviasm-68043         173.61 MiB (44.14 KiB)│
└───────────────────────────────────────────┴───────────────────────────────────────────┴───────────────────────────────────────────┘
/nix/store/r7zsi6cdib2yrhp7cpx4qn9d1b70jll5-texlive-combined-full-2023-final
NAR Size: 342.99 MiB | Closure Size: 6.24 GiB | Added Size: 5.62 GiB
Immediate Parents (1): nix-shell
```

Without the standard environment:

```{.default}
┌───────────────────────────────────────────┬───────────────────────────────────────────┬───────────────────────────────────────────┐
│nix-shell               7.23 GiB (7.23 GiB)│texlive-combined-full-2 6.24 GiB (5.62 GiB)│fonts.conf               3.64 GiB (3.1 KiB)│
│                                           │quarto-1.5.25          1.5 GiB (620.99 MiB)│texlive-combined-full-2 3.64 GiB (2.38 MiB)│
│                                           │python3-3.11.9-env  916.46 MiB (282.95 MiB)│texlive-combined-full-2 3.64 GiB (3.52 KiB)│
│                                           │npm-10.8.1           310.91 MiB (97.35 MiB)│texlive-combined-full-2 3.64 GiB (3.45 GiB)│
│                                           │stdenv-linux         67.13 MiB (166.23 KiB)│asymptote-2.88        1.24 GiB (660.91 MiB)│
│                                           │diffutils-3.10         43.66 MiB (1.53 MiB)│tlcockpit-1.2        1022.89 MiB (1.12 KiB)│
│                                           │findutils-4.9.0        43.46 MiB (1.32 MiB)│arara-7.1.3           966.03 MiB (1.14 KiB)│
│                                           │coreutils-9.5          42.13 MiB (2.12 MiB)│latex2nemeth-1.1.3       957.76 MiB (768.0)│
│                                           │patchelf-0.15.0      40.02 MiB (234.31 KiB)│albatross-0.5.1       955.15 MiB (1.16 KiB)│
│                                           │file-5.45              39.42 MiB (8.33 MiB)│texplate-1.0.4         953.4 MiB (1.14 KiB)│
│                                           │gnutar-1.35            33.85 MiB (2.67 MiB)│bib2gls-3.9           952.17 MiB (1.99 KiB)│
│                                           │gnugrep-3.11         33.68 MiB (922.61 KiB)│texosquery-1.7        950.24 MiB (2.35 KiB)│
│                                           │gawk-5.2.2             33.54 MiB (2.57 MiB)│memoize-1.1.2        231.84 MiB (65.53 KiB)│
│                                           │gzip-1.13             32.66 MiB (152.8 KiB)│texlive-scripts-705 218.42 MiB (168.54 KiB)│
│                                           │bash-5.2p26            32.51 MiB (1.54 MiB)│texlive.infra-69740- 210.01 MiB (22.95 MiB)│
│                                           │gnumake-4.4.1           32.47 MiB (1.5 MiB)│pygmentex-0.11       188.14 MiB (18.76 KiB)│
│                                           │xz-5.4.6-bin         31.91 MiB (172.22 KiB)│pythontex-0.18      185.94 MiB (300.51 KiB)│
│                                           │gnused-4.9           31.67 MiB (714.07 KiB)│dvisvgm-3.2.2        184.64 MiB (50.79 MiB)│
│                                           │patch-2.7.6          31.32 MiB (359.24 KiB)│lilyglyphs-0.2.4     175.43 MiB (24.97 KiB)│
│                                           │bzip2-1.0.8-bin       31.11 MiB (67.24 KiB)│webquiz-5.2          173.81 MiB (44.94 KiB)│
│                                           │                                           │dviasm-68043         173.61 MiB (44.14 KiB)│
└───────────────────────────────────────────┴───────────────────────────────────────────┴───────────────────────────────────────────┘
/nix/store/r7zsi6cdib2yrhp7cpx4qn9d1b70jll5-texlive-combined-full-2023-final
NAR Size: 342.99 MiB | Closure Size: 6.24 GiB | Added Size: 5.62 GiB
Immediate Parents (1): nix-shell
```

This is a decent difference (26 megabytes) — and indeed, it was as I thought, the latex bundle package uses up the most disk space out of everything.

I did some research, continuing to find an even more minimal shell. However, it doesn't seem to be worth it. One [solution](https://discourse.nixos.org/t/with-default-nix-empty-nix-installs-packages-why/20284/3) mentions to use [devshell](https://github.com/numtide/devshell), however, after browsing the source code, it doesn't seem to be that much more minimal thank mkShellNoCC, and the documentation is sparse... it suggestst TOML, rather than nix for configuring the shell environment. And finally, the entire point of this endeavor was to *avoid* using external dependencies for my shell environments...

There is also [another blogpost](https://fzakaria.com/2021/08/02/a-minimal-nix-shell.html) where they attempt to strip down the nix shell environment of dependencies, including GNU coreutils, but it eventually fails because the basic nix shell environment requires `mkdir`. 

Now... which latex distribution should I switch to? I probably don't need the every single latex package in nixpkgs, especially if all I want is to render a pdf. 

Currently, I am using `texlive.combined.scheme-full`, which is exactly that. According to the [quarto pdf docs](https://quarto.org/docs/output-formats/pdf-engine.html#overview), quarto recommends, and also is able to install `tinytex`. WHen quarto manages a texlive or tinytex distribution, it is also able to automatically install missing packages. 


```{.default}
────────────────────────────────────────┬────────────────────────────────────────┬───────────────────────────────────────┐
│nix-shell            1.84 GiB (1.84 GiB)│quarto-1.5.25       1.5 GiB (620.99 MiB)│python3-3.11.9- 916.46 MiB (729.13 MiB)│
│                                        │python3-3.11.9-e 916.46 MiB (729.13 MiB)│deno-1.43.6     239.73 MiB (199.93 MiB)│
│                                        │texlive-2023-env 527.99 MiB (340.17 MiB)│dart-sass-1.77.4  49.52 MiB (18.54 MiB)│
│                                        │stdenv-linux      67.13 MiB (166.23 KiB)│esbuild-0.21.5     43.2 MiB (10.09 MiB)│
│                                        │diffutils-3.10      43.66 MiB (1.53 MiB)│bash-5.2p26        32.51 MiB (1.54 MiB)│
│                                        │findutils-4.9.0     43.46 MiB (1.32 MiB)│                                       │
│                                        │coreutils-9.5       42.13 MiB (2.12 MiB)│                                       │
│                                        │patchelf-0.15.0   40.02 MiB (234.31 KiB)│                                       │
│                                        │file-5.45           39.42 MiB (8.33 MiB)│                                       │
│                                        │gnutar-1.35         33.85 MiB (2.67 MiB)│                                       │
│                                        │gnugrep-3.11      33.68 MiB (922.61 KiB)│                                       │
│                                        │gawk-5.2.2          33.54 MiB (2.57 MiB)│                                       │
│                                        │gzip-1.13          32.66 MiB (152.8 KiB)│                                       │
│                                        │bash-5.2p26         32.51 MiB (1.54 MiB)│                                       │
│                                        │gnumake-4.4.1        32.47 MiB (1.5 MiB)│                                       │
│                                        │xz-5.4.6-bin      31.91 MiB (172.22 KiB)│                                       │
│                                        │gnused-4.9        31.67 MiB (714.07 KiB)│                                       │
│                                        │patch-2.7.6       31.32 MiB (359.24 KiB)│                                       │
│                                        │bzip2-1.0.8-bin    31.11 MiB (67.24 KiB)│                                       │
│                                        │                                        │                                       │
│                                        │                                        │                                       │
│                                        │                                        │                                       │
└────────────────────────────────────────┴────────────────────────────────────────┴───────────────────────────────────────┘
/nix/store/gc3phrmibx7zp5q16n5vy3h1ra6wjckr-quarto-1.5.25
NAR Size: 392.41 MiB | Closure Size: 1.5 GiB | Added Size: 620.99 MiB
Immediate Parents (1): nix-shell
```

After a lot of tinkering with latex packages, I manage to get it down to just under 2 GB of disk space used. Can I make it smaller? What about bzip, tar, or other coreutils that are taking up space?

I decided to tinker with python and jupyter notebooks next. I was previously using the `juptyer` package, which is a metapackage containing all the jupyter components. I managed to cut it down quite a bit, to just `jupyter-core` and `pyaml`. This reduced the size further: 

```{.default}
┌──────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┬─────────────────────────────────────────────────────┐
│nix-shell                          1.11 GiB (1.11 GiB)│quarto-1.5.47                  529.43 MiB (479.77 MiB)│deno-1.43.6                   239.73 MiB (199.93 MiB)│
│                                                      │texlive-2023-env               527.99 MiB (462.84 MiB)│typst-0.11.1                    76.53 MiB (30.55 MiB)│
│                                                      │python3-3.11.9-env              176.66 MiB (120.1 MiB)│dart-sass-1.77.4                49.52 MiB (18.54 MiB)│
│                                                      │stdenv-linux                    67.13 MiB (166.23 KiB)│esbuild-0.21.5                   43.2 MiB (10.09 MiB)│
│                                                      │diffutils-3.10                    43.66 MiB (1.53 MiB)│bash-5.2p26                      32.51 MiB (1.54 MiB)│
│                                                      │findutils-4.9.0                   43.46 MiB (1.32 MiB)│                                                     │
│                                                      │coreutils-9.5                     42.13 MiB (2.12 MiB)│                                                     │
│                                                      │patchelf-0.15.0                 40.02 MiB (234.31 KiB)│                                                     │
│                                                      │file-5.45                         39.42 MiB (8.33 MiB)│                                                     │
│                                                      │gnutar-1.35                       33.85 MiB (2.67 MiB)│                                                     │
│                                                      │gnugrep-3.11                    33.68 MiB (922.61 KiB)│                                                     │
│                                                      │gawk-5.2.2                        33.54 MiB (2.57 MiB)│                                                     │
│                                                      │gzip-1.13                        32.66 MiB (152.8 KiB)│                                                     │
│                                                      │bash-5.2p26                       32.51 MiB (1.54 MiB)│                                                     │
│                                                      │gnumake-4.4.1                      32.47 MiB (1.5 MiB)│                                                     │
│                                                      │xz-5.4.6-bin                    31.91 MiB (172.22 KiB)│                                                     │
│                                                      │gnused-4.9                      31.67 MiB (714.07 KiB)│                                                     │
│                                                      │patch-2.7.6                     31.32 MiB (359.24 KiB)│                                                     │
│                                                      │bzip2-1.0.8-bin                  31.11 MiB (67.24 KiB)│                                                     │
│                                                      │                                                      │                                                     │
└──────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘
/nix/store/5phsvm3n78djp6gbmmda3jvm912h3gwg-quarto-1.5.47
NAR Size: 220.63 MiB | Closure Size: 529.43 MiB | Added Size: 479.77 MiB
Immediate Parents (1): nix-shell
```

However, can I reduce it further? I remove the size of quarto's installation, by deleting the vendored versions of deno, typst, dart-sass, and esbuild, and using the nix versions instead. But what if that's what's using up more space?

```{.default}
┌──────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┬─────────────────────────────────────────────────────┐
│nix-shell                          1.04 GiB (1.04 GiB)│texlive-2023-env               527.99 MiB (462.84 MiB)│bash-5.2p26                      32.51 MiB (1.54 MiB)│
│                                                      │quarto-1.5.47                  434.33 MiB (401.81 MiB)│                                                     │
│                                                      │python3-3.11.9-env             176.66 MiB (120.21 MiB)│                                                     │
│                                                      │stdenv-linux                    67.13 MiB (166.23 KiB)│                                                     │
│                                                      │diffutils-3.10                    43.66 MiB (1.53 MiB)│                                                     │
│                                                      │findutils-4.9.0                   43.46 MiB (1.32 MiB)│                                                     │
│                                                      │coreutils-9.5                     42.13 MiB (2.12 MiB)│                                                     │
│                                                      │patchelf-0.15.0                 40.02 MiB (234.31 KiB)│                                                     │
│                                                      │file-5.45                         39.42 MiB (8.33 MiB)│                                                     │
│                                                      │gnutar-1.35                       33.85 MiB (2.67 MiB)│                                                     │
│                                                      │gnugrep-3.11                    33.68 MiB (922.61 KiB)│                                                     │
│                                                      │gawk-5.2.2                        33.54 MiB (2.57 MiB)│                                                     │
│                                                      │gzip-1.13                        32.66 MiB (152.8 KiB)│                                                     │
│                                                      │bash-5.2p26                       32.51 MiB (1.54 MiB)│                                                     │
│                                                      │gnumake-4.4.1                      32.47 MiB (1.5 MiB)│                                                     │
│                                                      │xz-5.4.6-bin                    31.91 MiB (172.22 KiB)│                                                     │
│                                                      │gnused-4.9                      31.67 MiB (714.07 KiB)│                                                     │
│                                                      │patch-2.7.6                     31.32 MiB (359.24 KiB)│                                                     │
│                                                      │bzip2-1.0.8-bin                  31.11 MiB (67.24 KiB)│                                                     │
│                                                      │                                                      │                                                     │
└──────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘
/nix/store/a6v1glf1w6jfm949jlydb6imlbyimddw-quarto-1.5.47
NAR Size: 401.81 MiB | Closure Size: 434.33 MiB | Added Size: 401.81 MiB
Immediate Parents (1): nix-shell
```

Removing nix dependencies gets it down to 1.04 GB... but I don't really like this setup. Vendoring is kinda problematic for a variety of reasons. I'm already vendoring pandoc, for example, and if pandoc is used again outside of the nix store, then it would take up twice as much disk space. 

Another thing is versioning. Although the pandoc version quarto provides is newer than the one in nixpkgs, the version of typst is the same, and the versions of dart-sass and deno is *older* by 4 minor versions.

But, when comparing nix-tree and looking at the ark, most of the packages outside quarto are bigger... or are they?

```{.default}
┌──────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┬─────────────────────────────────────────────────────┐
│                                                      │nix-shell                          1.03 GiB (1.03 GiB)│texlive-2023-env              527.99 MiB (462.84 MiB)│
│                                                      │                                                      │quarto-1.5.47                 443.91 MiB (396.38 MiB)│
│                                                      │                                                      │python3-3.11.9-env            176.66 MiB (120.21 MiB)│
│                                                      │                                                      │stdenv-linux                   67.13 MiB (166.23 KiB)│
│                                                      │                                                      │diffutils-3.10                   43.66 MiB (1.53 MiB)│
│                                                      │                                                      │findutils-4.9.0                  43.46 MiB (1.32 MiB)│
│                                                      │                                                      │coreutils-9.5                    42.13 MiB (2.12 MiB)│
│                                                      │                                                      │patchelf-0.15.0                40.02 MiB (234.31 KiB)│
│                                                      │                                                      │file-5.45                        39.42 MiB (8.33 MiB)│
│                                                      │                                                      │gnutar-1.35                      33.85 MiB (2.67 MiB)│
│                                                      │                                                      │gnugrep-3.11                   33.68 MiB (922.61 KiB)│
│                                                      │                                                      │gawk-5.2.2                       33.54 MiB (2.57 MiB)│
│                                                      │                                                      │gzip-1.13                       32.66 MiB (152.8 KiB)│
│                                                      │                                                      │bash-5.2p26                      32.51 MiB (1.54 MiB)│
│                                                      │                                                      │gnumake-4.4.1                     32.47 MiB (1.5 MiB)│
│                                                      │                                                      │xz-5.4.6-bin                   31.91 MiB (172.22 KiB)│
│                                                      │                                                      │gnused-4.9                     31.67 MiB (714.07 KiB)│
│                                                      │                                                      │patch-2.7.6                    31.32 MiB (359.24 KiB)│
│                                                      │                                                      │bzip2-1.0.8-bin                 31.11 MiB (67.24 KiB)│
│                                                      │                                                      │                                                     │
└──────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘
/nix/store/67sndag759yw2wvfrfgfszpgzvbyg3gk-nix-shell
NAR Size: 5.35 KiB | Closure Size: 1.03 GiB | Added Size: 1.03 GiB
Immediate Parents: -
```

Changing to the typst in nixpkgs decreases the size just a little bit. Not a lot, but just a little bit. It's a pity that changing deno and dart-sass for the nixpkgs versions increases the size by quite a bit, as the nixpkgs versions are newer. Changing pandoc also increases size, but the pandoc version provided by quarto is newer. 

I also changed esbuild, and got it down to 1.02 GB. 

```{.default}
┌──────────────────────────────────────────────────────┬──────────────────────────────────────────────────────┬─────────────────────────────────────────────────────┐
│nix-shell                          1.02 GiB (1.02 GiB)│texlive-2023-env               527.99 MiB (462.84 MiB)│typst-0.11.1                    76.53 MiB (30.55 MiB)│
│                                                      │quarto-1.5.47                  434.75 MiB (387.22 MiB)│bash-5.2p26                      32.51 MiB (1.54 MiB)│
│                                                      │python3-3.11.9-env             176.66 MiB (120.21 MiB)│                                                     │
│                                                      │stdenv-linux                    67.13 MiB (166.23 KiB)│                                                     │
│                                                      │diffutils-3.10                    43.66 MiB (1.53 MiB)│                                                     │
│                                                      │findutils-4.9.0                   43.46 MiB (1.32 MiB)│                                                     │
│                                                      │coreutils-9.5                     42.13 MiB (2.12 MiB)│                                                     │
│                                                      │patchelf-0.15.0                 40.02 MiB (234.31 KiB)│                                                     │
│                                                      │file-5.45                         39.42 MiB (8.33 MiB)│                                                     │
│                                                      │gnutar-1.35                       33.85 MiB (2.67 MiB)│                                                     │
│                                                      │gnugrep-3.11                    33.68 MiB (922.61 KiB)│                                                     │
│                                                      │gawk-5.2.2                        33.54 MiB (2.57 MiB)│                                                     │
│                                                      │gzip-1.13                        32.66 MiB (152.8 KiB)│                                                     │
│                                                      │bash-5.2p26                       32.51 MiB (1.54 MiB)│                                                     │
│                                                      │gnumake-4.4.1                      32.47 MiB (1.5 MiB)│                                                     │
│                                                      │xz-5.4.6-bin                    31.91 MiB (172.22 KiB)│                                                     │
│                                                      │gnused-4.9                      31.67 MiB (714.07 KiB)│                                                     │
│                                                      │patch-2.7.6                     31.32 MiB (359.24 KiB)│                                                     │
│                                                      │bzip2-1.0.8-bin                  31.11 MiB (67.24 KiB)│                                                     │
│                                                      │                                                      │                                                     │
└──────────────────────────────────────────────────────┴──────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘
/nix/store/zv70xxgak45jl997c53lwh91b7v3qz6s-quarto-1.5.47
NAR Size: 356.66 MiB | Closure Size: 434.75 MiB | Added Size: 387.22 MiB
Immediate Parents (1): nix-shell
```

I think this is the final iteration. Down to 1 GB is already a lot, and I think this will be the final iteration. 

Here is the final shell.nix:

```{.nix filename='shell.nix'}
{ pkgs ? import <nixpkgs> { } }:

let
  python3 = pkgs.python311;
  pythonDeps = ps: with ps; [
    jupyter-core
    pyyaml
  ];

  texDeps = ps: with ps; [
    collection-latex
    collection-latexrecommended
    xetex
  ];

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: rec {
    # 1.3 + newer (I think) has a weird bug with the text boxes where they are white on a black background. Readable, but ugly
    version = "1.5.47";
    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      sha256 = "sha256-Zfx3it7vhP+9vN8foveQ0xLcjPn5A7J/n+zupeFNwEk=";
    };
    preFixup = ''
      wrapProgram $out/bin/quarto \
        --prefix QUARTO_TYPST : ${pkgs.lib.makeBinPath [ pkgs.typst ]}/typst \
        --prefix QUARTO_ESBUILD ${pkgs.lib.makeBinPath [ pkgs.esbuild ]}/esbuild
    '';
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -rf bin/tools/*/typst
      rm -rf bin/tools/*/esbuild

      mv bin/* $out/bin
      mv share/* $out/share

      runHook postInstall
    '';
  });
in
pkgs.mkShellNoCC {
  PYTHONPATH = "${pkgs.python3.withPackages pythonDeps}/bin/python3";
  QUARTO_PYTHON = "${pkgs.python3.withPackages pythonDeps}/bin/python3";

  packages = with pkgs; [
    (python3.withPackages pythonDeps)
    quarto
    (texlive.withPackages texDeps)
  ];
}
```

# More issues, no tab autocomplete

Nope, it's not the final shell. For whatever reason, if I open Vscode, or zellij using the `nix develop` shell, I cannot use tab autocomplete. In addition to that, the Vscode shell seems to be broken in others ways. 

Here is the shell prompt:

```{.default}
\[\][moonpie@lizard moonpiedumplings.github.io]$ \[\]
```

Yeah. Not what it's supposed to be. I don't know what the backslashes signify. However, `nix-shell` continues to work fine for zellij. 

There are some relevant issues for this:

* https://github.com/NixOS/nix/issues/6091
* https://github.com/NixOS/nix/issues/6982
* https://github.com/NixOS/nix/issues/8764


In a related [discourse post](https://discourse.nixos.org/t/general-nix-office-hours/15019/37), Nobbz suggests to use `eval`, but that also does not work, not do related solutions with `. <()`. 

The big problem is that `nix develop` is designed for emulation of the nix build environment, which is non-interactive. `nix shell`, as I noted above, does not properly replace `nix-shell`, as it does not allow for any configuration of environment variables. Or can it?

I also investigated `pkgs.buildEnv`, which is [literally undocumented](https://github.com/NixOS/nixpkgs/issues/251039), in classic Nix fashion. I read the [source code](https://github.com/NixOS/nixpkgs/blob/master/pkgs%2Fbuild-support%2Fbuildenv%2Fdefault.nix), but it doesn't seem to be able to set environment variables outside of wrapping programs. It mainly seems to be ableto add programs to the path. 

Another solution is [flake-compat](https://github.com/edolstra/flake-compat). It's a bit of nix code by Eelco Dostra that has creates a `shell.nix` that enables `nix-shell` to be used with flakes. I find it deeply ironic that despite all this effort to use flakey commands, I still end up finding that the non-flake commands work perfectly. 

Another suggestion was to use direnv, but I don't want to use that. 

Anyway, I noticed something different about the `nix-shell` vs `nix develop`: 

```{.default}
[nix-shell:~/vscode/moonpiedumplings.github.io]$ echo $SHELL
/nix/store/bh6w9sbfz2m5w1bd4cg2ndw1s66agkfd-bash-interactive-5.2p26/bin/bash
```

```{.default}
[moonpie@lizard moonpiedumplings.github.io]$ nix develop
warning: Git tree '/home/moonpie/vscode/moonpiedumplings.github.io' is dirty
evaluating derivation 'git+file:///home/moonpie/vscode/moonpiedumplings.github.io#devShells.x86_64-linux.default'
(nix:nix-shell-env) [moonpie@lizard moonpiedumplings.github.io]$ echo $SHELL
/nix/store/m101dg80ngyjdb02g6jwy80sr7kzj26g-bash-5.2p26/bin/bash
```


`nix-shell` defaults to an bash-interactive, whereas `nix develop` seems to use a stripped down, noninteractive version of bash. This is probably because `nix develop` 

The first thing I tried was to have `SHELL = "${pkgs.bashInteractive}/bin/bash";` in `pkgs.mkShell`, but this didn't work. `nix develop` seems to set it's own environment variables, *after* the other variables are set. 

The first thing I did was to set a post shellHook, which `nix develop` would run, and would `export` the variable. 

```{.nix}
pkgs.mkShellNoCC {
   shellHook = ''
    export SHELL='${pkgs.bashInteractive}/bin/bash'
  '';
}
```

This worked for zellij, but vscode's terminal was still broken. To get vscode's terminal working, I had to add `bashInterative` to packages:

```{.default}
pkgs.mkShellNoCC {
  packages = with pkgs; [ bashInteractive ];
   shellHook = ''
    export SHELL='${pkgs.bashInteractive}/bin/bash'
  '';
}
```

I actually encountered a similar issue with python. Vscode seems to ignore things not added to path, even if they are specified in other ways, like `$PYTHONPATH` pointing to the correct version of python.

But now, this finally works.


# Home-Manager

Next thing is to convert home manager to flakes. I need a slightly older version of kubectl, and flakes allow me to use packages from multiple versions of nixpkgs. 

I followed the [standalone flakes installation instructions](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone)

`nix run home-manager/master -- init --switch`

And with this, I get a basic flake.nix, flake.lock, and home.nix in `.config/home-manager/`. 


For older versions of packages, there are two sites I like, nixhub and lazamar's site:

* https://www.nixhub.io/
* https://lazamar.co.uk/nix-versions/

I found the correct nixpkgs revision for what I want: `7a339d87931bba829f68e94621536cad9132971a`.

However, using packages from multiple versions of nipkgs isn't as easy as I thought it would be. The [officail docs](https://wiki.nixos.org/wiki/Flakes#Importing_packages_from_multiple_nixpkgs_branches) suggest to use an overlay, which feels unecessary. Why can't I just replicate what it does for `nixpkgs`, but for `nixpkgs` again? 

I tried that, and it didn't work. The error's aren't very clear, but I think it's because the home manager configuration is a function with explicit arguments, and it errors when I try to feed it more than what it wants. 

Thankfully, I found another simple solution:

```{.nix filename='flake.nix'}
{
  description = "Home Manager configuration of moonpie";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    pkgs-kubectl.url = "github:nixos/nixpkgs/7a339d87931bba829f68e94621536cad9132971a";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, pkgs-kubectl, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."moonpie" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          pkgs-kbctl = import pkgs-kubectl {inherit system;};
        };
        modules = [ ./home.nix ];
      };
    };
}
```

And then in the beginning of home.nix:

```{.nix filename='home.nix'}
{ config, pkgs, pkgs-kbctl, ... }:

```

And this works. I can use `pkgs-kbctl.kubectl` to reference kubectl version 1.28.4, which is what's on my server. 
