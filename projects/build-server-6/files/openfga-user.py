import json
from authentik.core.models import Group

system_groups = ["authentik Read-only", "authentik Admins"]

all_groups = [group.name for group in Group.objects.all()]

all_groups = list(set(all_groups) - set(system_groups))

user_groups = [group.name for group in request.user.all_groups()]

# Might need a secret key
openfga_api_key = ""

writes = {
    "writes": {
        "tuple_keys": [
            {
                "user": f"user:{request.user.username}",
                "relation": "member",
                "object": "group"
            }
        ]
    },
    "authorization_model_id": "01K70P5HAQ8K2J3AN978F7Y1EC"
}

user_project_writes = {
    "writes": {
        "tuple_keys": [
            {
                "user": f"user:{request.user.username}",
                "relation": "operator",
                "object": f"project:{request.user.username}"
            }
        ]
    },
    "authorization_model_id": "01K70P5HAQ8K2J3AN978F7Y1EC"
}

deletes = {
    "deletes": {
        "tuple_keys": [
            {
                "user": f"user:{request.user.username}",
                "relation": "member",
                "object": "group"
            }
        ]
    },
    "authorization_model_id": "01K70P5HAQ8K2J3AN978F7Y1EC"
}


headers = {
    "Authorization": f"Bearer {openfga_api_key}",
    "content-type": "application/json"
}


for group in list(set(all_groups) - set(user_groups)):
  deletes["deletes"]["tuple_keys"][0]["object"] = f"group:{group}"
  requests.post('https://openfga.moonpiedumpl.ing/stores/01K70P3ZX9DJEHF85XDJS4PXN2/write', data=json.dumps(deletes), headers=headers)

requests.post('https://openfga.moonpiedumpl.ing/stores/01K70P3ZX9DJEHF85XDJS4PXN2/write', data=json.dumps(user_project_writes), headers=headers)

for group in user_groups:
    writes["writes"]["tuple_keys"][0]["object"] = f"group:{group}"
    requests.post('https://openfga.moonpiedumpl.ing/stores/01K70P3ZX9DJEHF85XDJS4PXN2/write', data=json.dumps(writes), headers=headers)

return True