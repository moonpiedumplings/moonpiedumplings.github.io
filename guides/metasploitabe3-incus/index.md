---
Title: Metasploitable 3 on Incus
draft: true
---

This was much harder than I though. 


# Start

Get vagrant from vagrant website

Unzip

Unzip, put vmdk's in directory

qemu-img -f vmd disk.vmdk -O qcow2 metasploitable2.qcow


# Metadata file





# Instance config


```{.yaml}
### This is a YAML representation of the configuration.
### Any line starting with a '# will be ignored.
###
### A sample configuration looks like:
### name: instance1
### profiles:
### - default
### config:
###   volatile.eth0.hwaddr: 10:66:6a:e9:f8:7f
### devices:
###   homedir:
###     path: /extra
###     source: /home/user
###     type: disk
### ephemeral: false
###
### Note that the name is shown but cannot be changed

architecture: x86_64
config:
  image.description: Metasploitable
  image.name: metasploitable
  image.os: Unknown Linux
  limits.cpu: "2"
  limits.memory: 4GiB
  raw.qemu.scriptlet: |
    def qemu_hook(instance, stage):
        if stage != "pre-start":
            return

        # Convert ethernet
        eth0_bus = run_qmp({"execute": "qom-get", "arguments": {"path": "/machine/peripheral/dev-incus_eth--1", "property": "parent_bus"}})["return"].split("/")[-1]
        eth0_addr = run_qmp({"execute": "qom-get", "arguments": {"path": "/machine/peripheral/dev-incus_eth--1", "property": "addr"}})["return"]
        eth0_mac = run_qmp({"execute": "qom-get", "arguments": {"path": "/machine/peripheral/dev-incus_eth--1", "property": "mac"}})["return"]
        eth0_netdev = run_qmp({"execute": "qom-get", "arguments": {"path": "/machine/peripheral/dev-incus_eth--1", "property": "netdev"}})["return"]
        run_qmp({"execute": "device_del", "arguments": {"id": "dev-incus_eth--1"}})
        run_qmp({"execute": "system_reset"})
        run_qmp({"execute": "device_add", "arguments": {"id": "dev-incus_eth--1", "driver": "e1000e", "bus": eth0_bus, "addr": eth0_addr, "netdev": eth0_netdev, "mac": eth0_mac, "romfile": "/usr/share/qemu/efi-e1000e.rom"}})
  security.csm: "true"
  security.secureboot: "false"
  volatile.base_image: 415ea4ae0e07434e8c2f73c3590e18bebc785231bf2f8edeab9db31abf7dd9ec
  volatile.cloud-init.instance-id: 3c5eee3e-a741-4d28-813b-a752bb40905c
  volatile.eth-1.host_name: tap4bb44fa8
  volatile.eth-1.hwaddr: 10:66:6a:8b:6f:78
  volatile.last_state.power: RUNNING
  volatile.last_state.ready: "false"
  volatile.uuid: d9d3e5cd-69ac-4769-9d3f-88882fd948fc
  volatile.uuid.generation: d9d3e5cd-69ac-4769-9d3f-88882fd948fc
  volatile.vm.definition: pc-q35-10.2
  volatile.vm.rtc_adjustment: "0"
  volatile.vm.rtc_offset: "0"
  volatile.vsock_id: "4189116797"
devices:
  eth-1:
    network: internal0
    type: nic
ephemeral: false
profiles:
- default
stateful: false
description: ""
created_at: 2026-02-23T09:58:46.444937025Z
name: metasploitable-test
status: Running
status_code: 103
last_used_at: 2026-02-23T19:23:26.099765113Z
location: none
type: virtual-machine
project: default
```

This was taken from 