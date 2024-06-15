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

So, I think it's time for me to move from the older channels way of doing things in nix, to the newer flakes. However, the nix docs are very poor, so I am going to document my process of converting my development environment here. 

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

(Also, I still have another unanswered question. What does the `@` symbol mean in a nix expression).


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
      default = pkgs.;
    });
  };
}
```

And this makes the `python` command available to me in my shell, and the library I called upon. But, this doesn't seem scalable. How do I get this to do more packages? How do I get this to do environment variables? And is this really better than `nix develop`?
