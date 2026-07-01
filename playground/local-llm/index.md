---
title: "Local AI experiments"
description: And then sandboxing them
date: "2026-6-7"
categories: [playground]
format:
  html:
    code-fold: true
    code-summary: "Show the code"
    code-block-background: true
    code-overflow: wrap
execute:
  freeze: false
---


# Inference

Recently, I got a Framework 16 with the Ryzen AI. It has 32 gb of ram, which is more than enough to run local models, either on the GPU or the NPU. I am also experimenting with agents, in order to see if I can at the very least, get them to explain undocumented codebases or the like.

## NPU: FastFlowLM

[FastFlowLM](https://fastflowlm.com/) or FLM for short, is a software similar to Ollama that runs models on the Neural Processing Unit (NPU), instead of the GPU. 

One thing that makes it different is that the models must be converted to run on FLM in advance. It can't download GGUF from hugging face, it uses a different format. They do have their own [repository of downloadable models](https://fastflowlm.com/docs/models/), but its nowhere near as large as Ollama's repositories, or HuggingFace's selection of GGUF models.


It is possible to convert certain families of models manually: <https://github.com/FastFlowLM/FLM_Q4NX_Converter>, although it didn't work to much for me. Right now I have just been playing with the available models.

Okay. Upon further investigation, it looks like the process of converting a model is special, and has to be done per model. 

FastflowLM is useful, but it seems to be more for cases where you want smaller (older) models, running with less power consumption. I really want a powerful, active model, and I am okay with my computer getting warm. So, I looked to solutions that can run the current orthodox GGUF format.


## Ollama

I first started with ollama-vulkan (packaged in Arch Linux), since Vulkan is officially supported on this hardware. However, I encountered a bug: <https://github.com/ollama/ollama/issues/15261>

Apparently Vulkan is broken with the Gemma4 models, which is frustrating.

I switched to ollama-rocm (also packaged in Arch Linux). I was avoidant of this at first, because ROCM is technically only supported on datacenter AMD GPU's, but it works fine on consumer GPU's with some configuration, or in my case, no configuration. The downloaded gemma4 models now worked. 

Ollama worked, for the most part. Unfortunately, Llama.cpp is more performant, so that is why I tried below. 


## Llama.cpp

Llama.cpp is the first thing I tried in order to run LLM's. Unfortunately, it would just segfault and core dump for me, no matter what I tried. 

Okay, I finally isolated it. The problem was that I need to explicitly specify the rocm device compilation should target. Also, I am using the Nixpkgs version not on Nixos. When I used the AUR version, it worked fine, although I am trying to avoid the AUR.

Here is what I ended up doing to make Llama.cpp work:

```{.nix}
llama-cpp = pkgs.llama-cpp.override {
      vulkanSupport = true;
      cudaSupport = false;
      rocmSupport = true;
      rocmGpuTargets = ["gfx1152"];
    };

  llamacpp = llama-cpp.overrideAttrs (oldAttrs: rec {

    version = "9684";
    src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    hash = "sha256-BQrdTEXUarGZcXU/g1w0BTx6FFDbuy738mcGINmwnGE=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
    };
    npmDepsHash = "sha256-0dctM/apI3ysMIEVBaBXO9hZMWskpJpNpOws1gwiOYc=";
  }); 
```

This updates llama.cpp, and also enables GPU support via HIP/ROCM. 

Except this crashes after an update. And I haven't been able to fix it. It just dies. Worse, the process is "defunct" and can't be killed properly, without having to reboot the whole machine.

At first I thought that this was an issue with a mismatched ROCm version, between Nix and the host. But I tried the version of llama.cpp-rocm that CachyOS/Arch (now, they didn't previously) ship, and it crashes too. 

I tried vulkan, which worked, but...s

```
[moonpie@nefertem home-manager]$ llama-cli --list-devices
Warning, nixVulkanIntel overwriting existing LD_LIBRARY_PATH
Available devices:
  ROCm0: AMD Radeon 860M Graphics (15683 MiB, 26437 MiB free)
  Vulkan0: AMD Radeon 860M Graphics (RADV KRACKAN1) (16195 MiB, 14880 MiB free)
```

Vulkan has much less vram than ROCm avaialable. Models that will load in ROCm, won't load in Vulkan. I tried [increasing the vram](https://www.jeffgeerling.com/blog/2025/increasing-vram-allocation-on-amd-ai-apus-under-linux/), and llama-cli 

```{.default}
[moonpie@nefertem ~]$ llama-cli --list-devices
Available devices:
  Vulkan0: AMD Radeon 860M Graphics (RADV KRACKAN1) (25088 MiB, 21714 MiB free)
```

Unfortunately, it still doesn't work, and many of the larger models which would load with ROCm, error:

```{.default}
[moonpie@nefertem ~]$ llama-cli -hf unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M

Loading model... -ggml_vulkan: Device memory allocation of size 1056622080 failed.
ggml_vulkan: vk::Device::allocateMemory: ErrorOutOfDeviceMemory
0.22.480.740 E alloc_tensor_range: failed to allocate Vulkan0 buffer of size 1056622080
/0.22.832.396 E llama_model_load: error loading model: unable to allocate Vulkan0 buffer
0.22.832.401 E llama_model_load_from_file_impl: failed to load model
0.22.832.435 E cmn  common_init_: failed to load model '/home/moonpie/.cache/huggingface/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf'
-0.22.835.534 E srv    load_model: failed to load model, '/home/moonpie/.cache/huggingface/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf'
 
Failed to load the model
```

I attempted to increase  the GPU vram.. although it looks like the GPU vram isn't shared, meaning that anything I allocate to Vulkan can't use normally. 

```
[moonpie@nefertem ~]$ free -m
               total        used        free      shared  buff/cache   available
Mem:            7714        2372        3354          42        2428        5342
Swap:           7713           0        7713
[moonpie@nefertem ~]$ llama-cli -hf llama-cli -hf unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M -ngl 20^C
[moonpie@nefertem ~]$ llama-cli -hf unsloth/Qwen3.6-35B-A3B-GGUF:Q4_K_M -ngl 999

Loading model... \ggml_vulkan: Device memory allocation of size 1056622080 failed.
ggml_vulkan: vk::Device::allocateMemory: ErrorOutOfDeviceMemory
0.14.149.029 E alloc_tensor_range: failed to allocate Vulkan0 buffer of size 1056622080
-0.14.488.243 E llama_model_load: error loading model: unable to allocate Vulkan0 buffer
0.14.488.247 E llama_model_load_from_file_impl: failed to load model
0.14.488.295 E cmn  common_init_: failed to load model '/home/moonpie/.cache/huggingface/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf'
0.14.491.633 E srv    load_model: failed to load model, '/home/moonpie/.cache/huggingface/hub/models--unsloth--Qwen3.6-35B-A3B-GGUF/snapshots/a483e9e6cbd595906af30beda3187c2663a1118c/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf'
 
Failed to load the model
```

I sacrificed 24 gb, but the model still fails to load. Very frustrating. 

## vllm

I began to investigate vLLM, which is a more "enterprise" solution for LLM deployment. They don't even support Vulkan, it only supports ROCm. They have a [docker container](https://docs.vllm.ai/en/stable/deployment/docker/). 



## UMR

Another thing I began to investigate was [UMR](https://github.com/EvanZhouDev/umr). It was an app that made it easy to "import" external models into ollama. I started by packaging it in nix: <https://github.com/moonpiedumplings/llm-agents.nix/blob/umr-cli-bun2nix/packages/umr-cli/package.nix>

But, I immediately encountered issues. Firstly, adding models from huggingface requires python. So, I had to apply a small patch to the code, to read an enviornment variable, and hten 

```{.typescript}
async function resolvePythonCommand(runner: CommandRunner): Promise<string> {
  if (await process.env.UMR_PYTHON !== undefined) {
    return process.env.UMR_PYTHON;
  }
  else if (await runner.commandExists("python")) {
    return "python";
  }
  else if (await runner.commandExists("python3")) {
    return "python3";
  }

  throw new ManagerError("Python is required for Hugging Face support", {
    code: "missing-python",
    exitCode: 2,
  });
}
```

Then, I would create a python version with the required huggingface_hub library in Nix:

```{.nix}
pythonDeps =
    ps: with ps; [
      huggingface-hub
    ];
  pythonDist = (pkgs.python314.withPackages pythonDeps);
```

And: 

```{.nix}
 preFixup = ''
    wrapProgram $out/bin/umr \
          --set-default UMR_PYTHON ${lib.getExe pythonDist}
  '';
```

This little snippet wraps the UMR program. The wrapper checks for an environment variable UMR_PYTHON, and if it doesn't exist, then it feeds it the value UMR_PYTHON instead. And then the second bit, outputs the binary of the Python that has the huggingface_hub library added.

So after this, it mostly worked... but it still could not read from the Hugging Face cache. [Upon further investigation](https://github.com/EvanZhouDev/umr/issues/5), it looks like this software was designed for Windows, and it doesn't support Linux's symlinks, or reflinks/lightweight copies, causing lots of things to break. 

When I did test with a separate model, adding the model to the store would be done by duplicating it UMR's own cache, meaning models would take up more space with no benefit. Ouch.

The model did get linked into Ollama successfully though, and Ollama would run it. It just needs some elbow grease to actually work on Linux.



## Open WebUI

Open Web UI seems to be the easiest way to have a fully features local AI chat client. I tried searching for local apps, but they didn't have web search which was unsatisfying.

Installing it was pretty easy, I installed it using nix and [home-manager](https://github.com/nix-community/home-manager).

Starting the server was a bit of a pain though, it tries to write to the nix store, which is immutable. I had to specificy that is should be trying to write somewhere else:

```
export DATA_DIR="$HOME/.local/share/open-webui"
mkdir -p "$DATA_DIR"
open-webui serve
```

Once it works, one thing I like is that it autodetected Ollama, and let me run models via that with no configuration. 


Similarly, if I run FastFlowLM on port 11434, instead of it's default of 5-something, then it will automaticlly find it and connect to it. But FastFlowLM gives me a core dumped error when I attempt to run any models.



# Models

I have mostly been playing with the qwen3.5/6 and gemma4 family of models. Unfortunately, I have been encountering many frustrations. On



# Agents and Interfaces


Recently, I have begun to play with local LLM's for various purposes. The runtime doesn't matter too much, I am mostly bouncing between ollama-vulkan (seems to be bugged for gemini), ollama-rocm and fastflowlm (uses the NPU but doesn't have as many models).

But, what I have been playing witha  lot is the harnesses/agents. I have tried out hermes, forgecode, nanocode, and a few others. 

I mostly use nix for packages, so I found out about this cool project: <https://github.com/numtide/llm-agents.nix>

## Installation

It is essentially, nix packaging of a ton of agents and similar software. I was trying many out one by one here, but I got tired of that, so I decided to see if I could install all of them at once.


I'm using home-manager to install packages on non-nixos systems: <https://github.com/moonpiedumplings/home-manager/>

It was fairly simple actually. Because nix is a programming language, it is possible to convert it to a list, filter out broken agents, and then add them all fo 

```{.nix}
let 
  hermes = inputs.hermes.packages.${system};
  llm-agents = inputs.llm-agents.packages.${system};
  every-agent = builtins.attrValues llm-agents;
  # list of broken agents for filtering
  broken-agents = [
    "aionui"
    "hermes-desktop"
    "showboat"
    "backlog-md"
    "mistral-vibe"
    "codex"
    #"openclaw"
    # Not an agent
    "flake-inputs"
    #"oh-my-opencode"
    #"omp"
    #"gno"
    # This stuff seems to be failing due to npm network issues. 
    # It's probably my home internet rather than broken packages
    "reasonix"
    "paseo-desktop"
    "codegraph"
    "gitbutler"
    "but"
    "openclaw"
    "code"
  ];

  working-agents =  builtins.attrValues
    #(builtins.removeAttrs llm-agents [ "aionui" "hermes-desktop" "showboat" ]);
    (builtins.removeAttrs llm-agents broken-agents);

  gpu-wrapped-agents = builtins.map config.lib.nixGL.wrappers.mesa working-agents;
  ```

After I have almost everything that that project packages, available.

Next up, was to sandbox them. Part of why I select the nix programming, is becasue it is possible to mount the immutable nix store into virtual machines or containers, saving space. 

## Incus Containers

So, I created an incus container: 


```{.yaml}
user.ui_terminal_default_payload: '{"command":"bash -l","environment":[{"key":"TERM","value":"xterm-256color"},{"key":"HOME","value":"/root"},{"key":"PATH","value":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/run/current-system/sw/bin"},{"key":"LANG","value":"C.UTF-8"},{"key":"USER","value":"root"},{"key":"NIX_REMOTE","value":"daemon"}],"user":0,"group":0}'
config:
  image.description: Debian trixie amd64 (20260608_05:24)
  image.os: Debian
  image.release: trixie
devices:
  disk-device-1:
    path: /nix/store
    readonly: "true"
    source: /nix/store
    type: disk
  disk-device-2:
    path: /nix/var/nix/daemon-socket
    readonly: "true"
    source: /nix/var/nix/daemon-socket
    type: disk
type: container
project: default
```

Th big things to note are the way I mount the nix daemon, and the nix store into the container read only. Another thing to note is the custom termianl payload. I use the command `bash -l` so that it loads an interactive bash shell, which is needed for nix to be present in the shell. The other thing I do is set the environment variable `NIX_REMOTE=daemon`, which makes it so that Nix understands that it itself isn't supposed to run the builds, it's supposed to communicate through the container to the host.


Inside the virtual machine, I can install nix by running `apt install nix-bin`. 

Then, I have to set up the profiles so they are used properly:

```{.bash filename='/etc/profile.d/nix.sh'}
export NIX_REMOTE=daemon # Ensures that nix tries to talk to the socket
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
```

I also have to add channels, and enable flakes and the new nix command.

Once these are configured, when I run nix operations, like installing home manager and pointing home manager at the same config my host is using, it works, saving space becuase it is using the same binaries and libraries from the host. And every



## Git Environments

Next, is safely giving the Incus container access to the git environment. I created another directory, `agent-sandbox`, and shared that to the Incus container with read and write permissions.

```{.yaml}
devices:
  disk-device-3:
    path: /root/agent-sandbox
    # Shift true makes it so that the container can actually read and write the host path
    shift: 'true'
    source: /home/moonpie/Projects/agent-sandbox
    type: disk
```

With git, you can actually git clone/push from a local repository. So if I run this on my host:

```{.default}
[moonpie@nefertem Projects]$ cd agent-sandbox/
[moonpie@nefertem agent-sandbox]$ git clone ../coder-templates/
Cloning into 'coder-templates'...
remote: Enumerating objects: 171, done.
remote: Counting objects: 100% (171/171), done.
remote: Compressing objects: 100% (119/119), done.
remote: Total 171 (delta 44), reused 171 (delta 44), pack-reused 0 (from 0)
Receiving objects: 100% (171/171), 19.81 MiB | 2.02 MiB/s, done.
Resolving deltas: 100% (44/44), done.
[moonpie@nefertem agent-sandbox]$ cd coder-templates/
[moonpie@nefertem coder-templates]$ touch test.txt
[moonpie@nefertem coder-templates]$ echo test > test.txt 
[moonpie@nefertem coder-templates]$ git add .
[moonpie@nefertem coder-templates]$ git commit -m "test commit"
[main a31feff] test commit
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt
[moonpie@nefertem coder-templates]$ cd ..
[moonpie@nefertem agent-sandbox]$ cd ..
[moonpie@nefertem Projects]$ cd coder-templates/
[moonpie@nefertem coder-templates]$ git pull ../agent-sandbox/coder-templates/ main
From ../agent-sandbox/coder-templates
 * branch            main       -> FETCH_HEAD
Updating 99ed112..a31feff
Fast-forward
 test.txt | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 test.txt
[moonpie@nefertem coder-templates]$ 
```

The agent now has a copy of the repo, they can do git operations on, but they can't touch the original repo becasue that is outside of the sandbox.

What this does, is it prevents agents from screwing up git history, or incorrectly pushing when they shouldn't. By making them do all git operations in another repo, I can inspect the history before pulling it over. 

Transferring git commits is fairly easy. You can `git pull` from either repo, to either repo, by specifying the filesystem location. `git pull ../agent-sandbox/coder-templates`

Not everything is git, so this has to be transferred over. The easiest way to do it, is run `git diff` and `git apply` to create an apply a patch.

Because I'm on Linux/Wayland, I can use `wl-copy` and `wl-paste` to save the patch to my clipboard.

In the normal repo, I run: `git diff | wl-copy`

In the sandboxed repo, I can then just run: `wl-paste | git apply`

Or vice versa, depending on which way I want the changes to go. 

The idea behind this whole setup is that I should be able to run the agents in always confirm (YOLO) or similar modes, safely in a sandboxed environment.


## Agents

I tried a few agents out. Unfortunately... my current favorite is Copilot, even for local models. It can be put into an "offline mode", where you point it at a local model and it won't force you to login to Github, or require internet at all.

### Copilot

```
export COPILOT_PROVIDER_BASE_URL=http://localhost:8080/v1 # For llama.cpp
export COPILOT_PROVIDER_BASE_URL=http://localhost:52625/v1 # for flm
export COPILOT_PROVIDER_BASE_URL=http://localhost:11434/v1 # for olllama
export COPILOT_MODEL=YOUR-MODEL-NAME
export COPILOT_OFFLINE=true # avoids fallback to online models


# defaults/not needed
export COPILOT_PROVIDER_TYPE=openai # or anthropic or azure
export COPILOT_PROVIDER_API_KEY # no auth needed for local
```

With these settings, Copilot actually works pretty well offline. Unfortunately it does run out of context a lot, so it's not really good at *coding*. But for things like exploring/explaining repos, and smaller changes, it is the least finicky for me.

In addition to that, Copilot is only source available, and not actually open source.


### Hermes

Hermes is a bit of a pain to configure, but it is my second favorite. It's very full featured, and the thing I especially like is the automatic context compression, so it is much more usable for longer running sessions with local models.

Hermes does a few things I really like, one thing I like is how easy it makes it to add MCP servers that use `stdout` (that is, they run locally).

`hermes mcp add --command uvx --arguments ddg-mcp-server`

Just like that, hermes can now search the web.


I also tried, and may elaborate on:

* Forgecode
* Goose-cli
* Nanocoder
* Opencode (kept running out of context)

I plan to try (only mentioning some of the less popular (underrated?) options):

* Kilocode
* Littlecoder
* <https://github.com/JetBrains/junie>
* <https://github.com/Rose22/openlumara> (++ it looks very promising)
* <https://github.com/SyntheticAutonomicMind/CLIO>
* <https://github.com/tontinton/maki> (nix flake!)
* <https://github.com/charmbracelet/crush>
