---
title: "Creating a nix flake, the \"proper\" way"
date: "2024-6-4"
categories: [nix]
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

The first thing, is that despite the fact that there is a lot of the existing flakes use a utility called [flake-utils](). However, this tool was ultimately started as an experiment, and has issues. A [blog post](https://ayats.org/blog/no-flake-utils/) ([archive](https://web.archive.org/web/20240229094244/https://ayats.org/blog/no-flake-utils/)) goes over some of the issues it has, and recommends against it... except I can't figure out at all how to apply it. 

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

Well, flakes still have their own benefits. The version of `nixpkgs` used is tracked in a `flake.lock` file in the git repo. This ensures reproducibility, as I would be able to update the version of `nixpkgs` for everyone using the repo, rather than having to rely on people updating their channels manually (`running nix-channel --update`). With the latter, channels will result in a different version of `nixpkgs` being used, but with flakes, everybody uses the same version of `nixpkgs`. 


