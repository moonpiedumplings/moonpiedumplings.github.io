import requests
import tempfile
import os
import warnings

warnings.filterwarnings("ignore")

# ====== CONFIG ======
INCUS_API = "https://130.166.84.86:8443"

# Desired project state (used for create/update)
PROJECT_PAYLOAD = {
    "name": request.user.username,
    "description": "User specific project",
    "config": {
        "features.images": "false",
        "features.networks": "false",
        "limits.cpu": 4,
        "limits.memory": "8GiB",
         "restricted": "true",
         "restricted.containers.nesting": "allow",
         "restricted.backups": "block",
         "restricted.snapshots": "allow",
         "restricted.networks.access": f"internal0, {request.user.username}-vlab, {request.user.username}-cloudnet"
        }
}


PRIVATE_NETWORK = {
    "name": f"{request.user.username}-cloudnet",
    "description": f"Personal network for {request.user.username}",
    "project": f"{request.user.username}",
    "type": "ovn",
    "config": {
        "security.acls": "default",
        "network": "forovn0"
        }
    }

EMPTY_NETWORK = {
    "name": f"{request.user.username}-vlab",
    "description": f"Non routed network for {request.user.username}",
    "project": f"{request.user.username}",
    "type": "ovn",
    "config": {
        "ipv4.address": "192.168.40.1/24",
        "ipv4.dhcp": "false",
        "ipv6.address": "none",
        "ipv6.dhcp": "false",
        "network": "none"
        }
    }


cert_path = "/incus-secrets/incus-crt"
key_path = "/incus-secrets/incus-key"


s = requests.Session()
s.verify = False  # replace with a CA bundle / server cert path in real usage
s.cert = (cert_path, key_path)

# Start with the creation of the networks
api_url = f"{INCUS_API}/1.0/networks/{request.user.username}-cloudnet"
r = s.get(api_url)

if r.status_code == 200:
    api_url = f"{INCUS_API}/1.0/networks"
    s.put(api_url, json=PRIVATE_NETWORK)

elif r.status_code == 404:
    api_url = f"{INCUS_API}/1.0/networks"
    r2 = s.post(api_url, json=PRIVATE_NETWORK)
    print(r2.text)

api_url = f"{INCUS_API}/1.0/networks/{request.user.username}-vlab"
r = s.get(api_url)

if r.status_code == 200:
    api_url = f"{INCUS_API}/1.0/networks"
    r2 = s.put(api_url, json=EMPTY_NETWORK)
    print(r2.text)

elif r.status_code == 404:
    api_url = f"{INCUS_API}/1.0/networks"
    r2 = s.post(api_url, json=EMPTY_NETWORK)
    ak_message(r2.text)
    print(r2.text)



# 1) Check if the project exists
get_url = f"{INCUS_API}/1.0/projects/{request.user.username}"
r = s.get(get_url)

if r.status_code == 200:
    # 2a) Exists -> PUT update
    put_url = get_url
    s.put(put_url, json=PROJECT_PAYLOAD)

elif r.status_code == 404:
    # 2b) Missing -> POST create
    post_url = f"{INCUS_API}/1.0/projects"
    s.post(post_url, json=PROJECT_PAYLOAD)


return True