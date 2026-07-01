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
        "features.networks": "true",
        "features.storage.buckets": "true",
        "features.profiles": "true",
        "features.storage.volumes": "true",
        "limits.cpu": 4,
        "limits.memory": "8GiB",
         "restricted": "true",
         "restricted.containers.nesting": "allow",
         "restricted.backups": "block",
         "restricted.snapshots": "allow",
         "restricted.networks.uplinks": "forovn0"
        }
}

cert_path = "/incus-secrets/incus-crt"
key_path = "/incus-secrets/incus-key"


s = requests.Session()
s.verify = False  # replace with a CA bundle / server cert path in real usage
s.cert = (cert_path, key_path)


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