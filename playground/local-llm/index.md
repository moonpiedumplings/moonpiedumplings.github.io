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

I have since given up on Llama.cpp (see below), and I am currently trying Ollama again.

The 


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

```{.default}
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

Okay, I suspect my rocm issue is this Github issue: https://github.com/ggml-org/llama.cpp/issues/19482 . Some things don't fit, for example, mine crashes even when loading very small (<1B) models. But, I did try the `--direct-io` solution mentioned in the last comment, since it did explicitly mention AMD Strix Halo. It did work, but then it stopped working?

Also, it appears to crash all system monitoring tools. `ps` just sits there loading forever, KDE System Monitor's page for processes doesn't load, htop doesn't load and so on. This is even stranger and more frustrating. I usually have to use [magic sysrq](https://wiki.archlinux.org/title/Keyboard_shortcuts#Rebooting) keys to reboot my system, or kill all processes by manually activating the OOM killer.




#### Docker

I'm going to try the docker image now:

```{.default}
podman run --rm -it \
    --privileged \
    --network=host \
    --device=/dev/kfd \
    --device=/dev/dri \
    --group-add video \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --ipc=host \
    -v ".:/data" \
    --entrypoint /bin/bash \
    ghcr.io/ggml-org/llama.cpp:full-rocm
```

Unfortunately, this just abruptly dies, becoming "defunct". 

I also tried rebooting into the Linux LTS kernel, still no dice.

I also tried with the older image tag, `full-rocm-b7801`. But that crashes when attempting to run Qwen3.6. It looks like the older images, even though they don't hang and die, they don't support the latest models. 



## Lemonade

Lemonade server is AMD's solution, and apparently has better support. 

```{.default}
podman run -d \
  --name lemonade-server \
  -p 13305:13305 \
  -v $HOME/.cache/huggingface:/root/.cache/huggingface \
  -v lemonade-llama:/opt/lemonade/llama \
  -v lemonade-recipe:/root/.cache/lemonade \
  --privileged \
  --device=/dev/kfd \
  --device=/dev/dri \
  ghcr.io/lemonade-sdk/lemonade-server:latest
```

They also provide a [customized buid of llama.cpp](https://github.com/lemonade-sdk/llamacpp-rocm), which appears to explicitly support AMD Strix Halo devices. Okay Vulkan gives me out of memory, and ROCm gives me the same kernel issues mentioned above `:(`.

## vllm

I began to investigate vLLM, which is a more "enterprise" solution for LLM deployment. They don't even support Vulkan, it only supports ROCm. They have a [docker container](https://docs.vllm.ai/en/stable/deployment/docker/). 

However, I decided to start with the python venv install instead: <https://docs.vllm.ai/en/stable/getting_started/installation/gpu/#set-up-using-python>

However, I needed to install some system libraries to my arch system:

```{.default}
(test) [moonpie@nefertem test]$ vllm --help
(content abbreviated)
OSError: libmpi_cxx.so.40: cannot open shared object file: No such file or directory
```

I spent about 30 seconds trying to figure out which Arch Linux package would offer this library, before giving up and realizing this is the kind of problems that docker solve. 

Here is a podman command that does what I want:

```{.default}
podman run --rm -it \
    --group-add=video \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    --device /dev/kfd \
    --device /dev/dri \
    -v ".:/models" \
    -p 8000:8000 \
    --entrypoint /usr/bin/bash \
    --ipc=host \
    mirror.gcr.io/vllm/vllm-openai-rocm:latest
```

Once this is done, I can go into my downloads folder, run it, and run the model that is stored there:

Oh. vLLM can't run gguf's natively. It's currently [experimental](https://docs.vllm.ai/en/latest/features/quantization/gguf/?utm_source=chatgpt.com).

Regardless, since I am a docker container, I can do this:

`pip install --break-system-packages vllm-gguf-plugin`

Which makes it work.

And then: 

```{.default}
root@2867ca43d78e:/models# vllm serve gemma-4-12B-it-qat-UD-Q4_K_XL.gguf --tokenizer unsloth/gemma-4-12B-it-qat-GGUF --dtype float16
INFO 07-05 00:02:38 [__init__.py:112] Registered model loader `<class 'vllm_gguf_plugin.loader.GGUFModelLoader'>` with load format `gguf`
INFO 07-05 00:02:38 [config.py:420] Registered config parser `<class 'vllm_gguf_plugin.config_parser.GGUFConfigParser'>` with config format `gguf`
(APIServer pid=653) INFO 07-05 00:02:38 [api_utils.py:339] 
(APIServer pid=653) INFO 07-05 00:02:38 [api_utils.py:339]        █     █     █▄   ▄█
(APIServer pid=653) INFO 07-05 00:02:38 [api_utils.py:339]  ▄▄ ▄█ █     █     █ ▀▄▀ █  version 0.24.0
(APIServer pid=653) INFO 07-05 00:02:38 [api_utils.py:339]   █▄█▀ █     █     █     █  model   gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
```

No crash... but the server's port returns an empty response. Annoying, and worse than an error in some ways.


## Troubleshooting ROCm

Okay, it looks like I have to actually troubleshoot ROCm. I started by finding some relevant resources:

https://community.frame.work/t/experiments-with-using-rocm-on-the-fw16-amd/62189/8

https://strixhalo-homelab.d7.wtf/AI/llamacpp-with-ROCm

https://github.com/ROCm/ROCm/issues/5151

https://bbs.archlinux.org/viewtopic.php?id=310497 (downgrading firmware did not work for me but I'm going to keep it for now in case there are multiple issues). 

https://community.frame.work/t/amd-rocm-for-local-training-and-inferencing/58377

https://community.frame.work/t/amd-strix-halo-llama-cpp-installation-guide-for-fedora-42/75856

https://llm-tracker.info/_TOORG/Strix-Halo

https://dev.webonomic.nl/how-to-use-amd-rocm-on-krackan-point-ryzen-ai-300-series


I get this error in dmesg:

```{.default}
[   36.902241] Oops: general protection fault, probably for non-canonical address 0x3160244c8d480144: 0000 [#1] SMP NOPTI
1397 │ [   36.902249] CPU: 6 UID: 1000 PID: 2523 Comm: llama-cli Tainted: G           OE       7.1.3-zen1-2-zen #1 PREEMPT(full)  b184153fbcadbb0788a38e1b09442059e30aeb16
1398 │ [   36.902253] Tainted: [O]=OOT_MODULE, [E]=UNSIGNED_MODULE
1399 │ [   36.902254] Hardware name: Framework Laptop 16 (AMD Ryzen AI 300 Series)/FRANMHCP07, BIOS 03.04 11/06/2025
1400 │ [   36.902255] RIP: 0010:amdgpu_vm_cpu_update+0x27/0x120 [amdgpu]
1401 │ [   36.902420] Code: 90 90 90 f3 0f 1e fa 0f 1f 44 00 00 41 57 49 89 f7 41 56 45 89 ce 41 55 45 89 c5 41 54 49 89 d4 ba 01 00 00 00 55 48 89 fd 53 <48> 8b be 40 01 00 00 48 89 cb 31 f6 48 b9 ff ff ff ff ff ff ff 7f
1402 │ [   36.902421] RSP: 0018:ffffca3c60103760 EFLAGS: 00010246
1403 │ [   36.902423] RAX: ffffffffc0a74b90 RBX: 00400000000004f7 RCX: 0000000170800000
1404 │ [   36.902424] RDX: 0000000000000001 RSI: 3160244c8d480004 RDI: ffffca3c601038d0
1405 │ [   36.902425] RBP: ffffca3c601038d0 R08: 0000000000000001 R09: 0000000000200000
1406 │ [   36.902426] R10: 00000007ff520400 R11: ffff89349d500000 R12: 0000000000000810
1407 │ [   36.902426] R13: 0000000000000001 R14: 0000000000200000 R15: 3160244c8d480004
1408 │ [   36.902427] FS:  00007ff53abfe6c0(0000) GS:ffff893bd0e94000(0000) knlGS:0000000000000000
1409 │ [   36.902428] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
1410 │ [   36.902429] CR2: 00007ff520400010 CR3: 00000001434a3000 CR4: 0000000000f50ef0
1411 │ [   36.902430] PKRU: 55555554
1412 │ [   36.902431] Call Trace:
1413 │ [   36.902433]  <TASK>
1414 │ [   36.902435]  amdgpu_vm_ptes_update+0x497/0x17e0 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1415 │ [   36.902572]  ? __kmalloc_cache_noprof+0x135/0x480
1416 │ [   36.902576]  amdgpu_vm_update_range+0x2a3/0x7a0 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1417 │ [   36.902704]  svm_range_validate_and_map+0xeb7/0x1dd0 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1418 │ [   36.902881]  svm_range_set_attr+0x1155/0x1840 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1419 │ [   36.903021]  kfd_ioctl+0x2ea/0x5c0 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1420 │ [   36.903166]  ? __pfx_kfd_ioctl_svm+0x10/0x10 [amdgpu 45cfcfeb2399679ed2b5db4f50da5b7ed4bb62a2]
1421 │ [   36.903299]  ? try_charge_memcg+0x1a1/0x7c0
1422 │ [   36.903302]  __x64_sys_ioctl+0xb9/0xf0
1423 │ [   36.903305]  do_syscall_64+0xaa/0x660
1424 │ [   36.903308]  ? map_anon_folio_pmd_pf+0x75/0x90
1425 │ [   36.903310]  ? do_huge_pmd_anonymous_page+0x1b0/0x550
1426 │ [   36.903312]  ? count_memcg_events+0xd1/0x190
1427 │ [   36.903314]  ? handle_mm_fault+0x57f/0x14d0
1428 │ [   36.903317]  ? do_user_addr_fault+0x357/0xbd0
1429 │ [   36.903320]  ? do_syscall_64+0x5f/0x660
1430 │ [   36.903321]  ? exc_page_fault+0x90/0x1d0
1431 │ [   36.903323]  entry_SYSCALL_64_after_hwframe+0x76/0x7e
1432 │ [   36.903325] RIP: 0033:0x7ff5ce541d8f
1433 │ [   36.903352] Code: 00 48 89 44 24 18 31 c0 48 8d 44 24 60 c7 04 24 10 00 00 00 48 89 44 24 08 48 8d 44 24 20 48 89 44 24 10 b8 10 00 00 00 0f 05 <89> c2 3d 00 f0 ff ff 77 18 48 8b 44 24 18 64 48 2b 04 25 28 00 00
1434 │ [   36.903353] RSP: 002b:00007ff53abdc4e0 EFLAGS: 00000246 ORIG_RAX: 0000000000000010
1435 │ [   36.903354] RAX: ffffffffffffffda RBX: 00007ff53abdc5cc RCX: 00007ff5ce541d8f
1436 │ [   36.903355] RDX: 00007ff53abdc580 RSI: 00000000c0484b20 RDI: 0000000000000003
1437 │ [   36.903356] RBP: 00000000c0484b20 R08: 0000000000000000 R09: 00000000002ab000
1438 │ [   36.903356] R10: 00007ff53abdc720 R11: 0000000000000246 R12: 00007ff53abdc580
1439 │ [   36.903357] R13: 0000000000000003 R14: 0000000000000030 R15: 00007ff549e4fc40
1440 │ [   36.903358]  </TASK>
```

The address at the top does seem to change every run.

It does look only Ubuntu 22 + specific rocm versions are supported. It's mentioned [explicitly here](https://github.com/ROCm/ROCm/issues/6143#issuecomment-4369362515), that the Ubuntu kernel seems to have custom fixes included that mainline Linux doesn't have yet. 

OEM kernel info:

https://ubuntu.com/kernel/docs/reference/oem-kernels/

Mirror: https://github.com/anthonywong/ubuntu-oem-kernel-mirror

Sure enough, when I go through the [commits](https://github.com/search?q=repo%3Aanthonywong%2Fubuntu-oem-kernel-mirror+amd&type=commits) of that repo, I see  [Mario Limonciollo](https://community.frame.work/t/ollama-model-runner-unexpectedly-stopped-gpu-hang/76220/6), who was also on the framework forums discussing the way that 

AUR packages to potentially adapt: https://aur.archlinux.org/packages/linux-git-headers , https://aur.archlinux.org/packages/linux-git

 I want to find a recipe or similar, that way I can copy over and adapt the config for the package to the above AUR packages. But for now, I just replaced the "src" part the AUR package with the github ubuntu repo, and it's currently compiling.

 Nope, even with compiling the Ubuntu OEM kernel I still get the same kernel crash, using Arch Linux's llama.cpp package and ROCM. Also breaks with Lemonade's docker container. Also Lemonade's llama-server with `--direct-io` fails to work as well.

 Next up, I downgraded the amdgpu firmware to Ubuntu's exact version.

 Okay, `llama-cli --direct-io --no-mmap --fit off -m Qwen3-0.6B-IQ4_NL.gguf` worked!

 Once. It proceeded to crash next time `:(`

 Okay, it appears that [support for my GPU is just not done yet](https://github.com/ROCm/TheRock/issues/2310). New hardware. Though, many people mention it working, this explains somewhat why it's not stable.

Someone mentioned [downgrading](https://github.com/ROCm/ROCm/issues/5844#issuecomment-4108668995) to specific versions of the kernel and firmware, but given that I just tried  that, I'm not optimistic. More resourcesL

https://gitlab.freedesktop.org/drm/amd/-/work_items/4765 — only when running 3d workloads. Maybe I need to test with no desktop? No, it also fails with no desktop. In addition to that, this issue is closed.

`llama-cli -fa off -dio --no-mmap --fit off -m `

Okay I give up. I 'm just going to install Ubuntu 24.04.4 LTS, which is officially supported according to the ROCm compatibility matrixes:

<https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html>

<https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityryz/native_linux/native_linux_compatibility.html>

But before I try that, I'm going to try this AUR package: <https://aur.archlinux.org/packages/rocm-gfx1152-bin>, which is the latest ROCm preview, which apparently explicitly supports my hardware. 

Nope. Still crashes, even when I use Ubuntu's kernel, and  Ubuntu's firmware. 

## Vulkan

Okay, now I'm getting issues with llama.cpp and Vulkan. I am going to pull my hair out. 

The main idea I had with Vulkan is that maybe it is possible to get unified memory, which apparently it is: <https://github.com/ggml-org/llama.cpp/discussions/12770>

Indeed, llama.cpp does seem to see the whole TTM/GTT memory size from Vulkan:

```{.default}
[moonpie@nefertem moonpiedumplings.github.io]$ llama-cli --list-devices
Available devices:
  ROCm0: AMD Radeon 860M Graphics (24576 MiB, 26082 MiB free)
  Vulkan0: AMD Radeon 860M Graphics (RADV KRACKAN1) (25088 MiB, 23876 MiB free)
```

But when I actually try to run it, it just crashes: 

```{.default}
[moonpie@nefertem Downloads]$ llama-cli --device Vulkan0 -nkvo -m Huihui-gemma-4-12B-it-qat-q4_0-unquantized-abliterated-Q4_K.gguf 
Loading model... /ggml_vulkan: Device memory allocation of size 1070764064 failed.
ggml_vulkan: vk::Device::allocateMemory: ErrorOutOfDeviceMemory
0.03.527.707 E alloc_tensor_range: failed to allocate Vulkan0 buffer of size 1070764064
\0.03.641.017 E llama_model_load: error loading model: unable to allocate Vulkan0 buffer
0.03.641.021 E llama_model_load_from_file_impl: failed to load model
0.03.641.026 E cmn  common_init_: failed to load model 'Huihui-gemma-4-12B-it-qat-q4_0-unquantized-abliterated-Q4_K.gguf'
0.03.641.029 E srv    load_model: failed to load model, 'Huihui-gemma-4-12B-it-qat-q4_0-unquantized-abliterated-Q4_K.gguf'
0.03.641.425 E srv  llama_server: exiting due to model loading error
llama_server exited with code 1
Error: the server exited before becoming ready
```

1070764064 bytes is only 1 GB, a tiny amount. I have more than enough space, so why does it fail?

No wait, this is probably becuase the above option doesn't do anything, so the Vulkan backend only has 512 mb of vram. 

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
* Opencode: kept running out of context
* Zed: "Explore this repo" didn't go anywhere. Either zed issues, or it was issues with the models I was trying.

I plan to try (only mentioning some of the less popular (underrated?) options):

* Kilocode
* Littlecoder
* <https://github.com/JetBrains/junie>
* <https://github.com/Rose22/openlumara> (++ it looks very promising)
* <https://github.com/SyntheticAutonomicMind/CLIO>
* <https://github.com/tontinton/maki> (nix flake!)
* <https://github.com/charmbracelet/crush>
