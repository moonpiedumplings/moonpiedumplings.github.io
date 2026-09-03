---
title: "Creating a Pandoc Flake"
date: "2025-6-5"
categories: [playground]
draft: true
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: false
---

# Status: Dropped

There is a [working patch](https://github.com/NixOS/nixpkgs/issues/519484#issuecomment-4825420112), that makes the latest version of quarto work with older versions of pandoc. This was fun, but I don't care about a newer pandoc, just a newer quarto. I have implemented this into my development shell, and I will be using that for the forseeable future. 

This was a fun journey though.

# Main

This static site is made using [quarto](https://quarto.org/). Quarto does a few things I like, like having fulltext search built in. 

But, the version of quarto in [nixpkgs](https://nixos.org/) is outdated. After some investigation, this is because the version of pandoc in nixpkgs is outdated, which is what quarto depends on. 

So, this is my journey to figure out how 

There were 3 solutions I looked at first:

* [haskell.nix](https://github.com/input-output-hk/haskell.nix)
* [cabal2nix](https://github.com/NixOS/cabal2nix) (official, what NixOS uses to generate the haskell packages)
* [stackage2nix](https://github.com/typeable/stackage2nix) (seems dead)

I eventually settled on haskell.nix, and I got it working. But the pandoc version was wrong. So I am going to do it all over again, but for an older version of pandoc, and record my steps here. 


First, I started by cloning the pandoc repo and then checking out the `3.8.2` tag, since that's what quarto wants. 

Before I started following the haskell.nix instructions, I added myself as a trusted user to the nix daemon at `/etc/nix/nix.conf` (or `/etc/nix/nix.custom.conf` for determinate nix). 

```{.default}
[moonpie@nefertem pandoc-flake]$ cat /etc/nix/nix.custom.conf 
# Written by https://github.com/DeterminateSystems/nix-installer.
# The contents below are based on options specified at installation time.

trusted-users = moonpie
```

This makes it so that when haskell.nix enables binary caches, they will be used instead of my machine compiling the software.

And then I started following instructions [on getting started](https://input-output-hk.github.io/haskell.nix/tutorials/getting-started.html#getting-started-with-hix) to set up haskell.nix.

```{.default}
[moonpie@nefertem pandoc-flake]$ rm flake.nix 
[moonpie@nefertem pandoc-flake]$ rm flake.lock 
[moonpie@nefertem pandoc-flake]$ rm stack.yaml 
[moonpie@nefertem pandoc-flake]$ 
```


```{.default}
[moonpie@nefertem pandoc-flake]$ nix run "github:input-output-hk/haskell.nix#hix" -- init
`flake.nix` file created.
`nix/hix.nix` project configuation:
─────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
     │ File: nix/hix.nix
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ {pkgs, ...}: {
   2 │   # name = "project-name";
   3 │   compiler-nix-name = "ghc96"; # Version of GHC to use
   4 │ 
   5 │   # Cross compilation support:
   6 │   # crossPlatforms = p: pkgs.lib.optionals pkgs.stdenv.hostPlatform.isx86_64 ([
   7 │   #   p.mingwW64
   8 │   #   p.ghcjs
   9 │   # ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
  10 │   #   p.musl64
  11 │   # ]);
  12 │ 
  13 │   # Tools to include in the development shell
  14 │   shell.tools.cabal = "latest";
  15 │   # shell.tools.hlint = "latest";
  16 │   # shell.tools.haskell-language-server = "latest";
  17 │ }
─────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
[moonpie@nefertem pandoc-flake]$ nix flake update
```


To build the pandoc cli package (which is what I want):

```
[moonpie@nefertem pandoc-flake]$ nix shell .#packages.x86_64-linux."pandoc-cli:exe:pandoc"
warning: Git tree '/home/moonpie/Projects/pandoc-flake' has uncommitted changes
evaluation warning: Nixpkgs 26.05 will be the last release to support x86_64-darwin; see https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05
[8/5/52 built, 33 copied (14.3 MiB), 4.2 MiB DL] building citeproc-lib-citeproc-0.12
```

This verifies that the nix code resolves, and it will attempt to compile pandoc.

Firstly, it [breaks on symlinks](https://github.com/input-output-hk/haskell.nix/issues/1134). I have to replace the `COPYING.md` file in pandoc-server, pandoc-cli, and pandoc-lua-engine folders with a real file that's not a symlink.


Once this is fixed, it takes a while to compile. But it works!

And then I can update my quarto nix flake and shell to represent this:

```{.nix}
{
nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    pandoc-flake = {
      url = "github:moonpiedumplings/pandoc-flake?ref=3.8.3-nix-flake";
      # tag 3.8.3 
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
..., outputs, etc
}
``

And the shell uses that version of pandoc: 

```{.nix}
let
quarto-newpandoc = pkgs.quarto.override {
     pandoc = pandoc-flake.packages.x86_64-linux."pandoc-cli:exe:pandoc";
  };

  quarto = quarto-newpandoc.overrideAttrs (oldAttrs: rec {

    pname = "quarto";
    version = "1.9.38";

    src = pkgs.fetchurl {
      url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
      hash = "sha256-6oyJc2h5GtnyAAEMCH6jERsuVWsSqWBIfdTiFpAqoQI=";
  };
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share

      rm -r bin/tools/*

      mkdir bin/tools/aarch64
      mkdir bin/tools/x86_64

      ln -s ${pkgs.lib.makeBinPath [ pandoc ]}/pandoc bin/tools/x86_64/pandoc
      ln -s ${pkgs.lib.makeBinPath [ pandoc ]}/pandoc bin/tools/aarch64/pandoc


      mv bin/* $out/bin
      mv share/* $out/share

      runHook postInstall
    '';
  });

in

... pkgs.mkShell, etc
``

Unfortunately, there is still an issue with quarto rendering that I cannot fix:

```{.default}
[ 20/105] blog/twitch/index.qmd
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
ERROR (/nix/store/6iny0dmxsrv5n6rjgialwrqkfklvh86q-quarto-1.9.38/share/pandoc/datadir/../../filters/modules/jog.lua:173) Don't know how to traverse TableBody
```

I tried overriding some of pandoc's dependencies, to make the lua api match, but it's the same issue. I suspect the issue isn't the version of pandoc, but some internal dependency of quarto that pandoc's lua interpreter isn't seeing.

It's not a fatal error though. The site continues to render perfectly fine, including pages where this error appears. 

Taking a look through the pandoc repo, I found the precise commit that adds that feature: <https://github.com/jgm/pandoc/commit/62ac67cff4b50674d2bfbf192f279466c2ad0f4a> 

It looks like it's something that's only available in the latest version, but not quite only the latest version, also requiring a specific version of pandoc-server and pandoc-lua-engine.

It's probably that the latter two packages are not the correct version, even though my pandoc flake updates the pandoc cli itself. 

No, that doesn't appear to be the case. Even when looking at the 3.10 tag, the code in that commit is present there. Upon further investigation, the issue might be that the lua version itself is different. Quarto's vendored pandoc might be using a different version of Lua.
