# Authentik expression policy that ensures that only ascii usernames are used
# Things get weird when non ascii usernames are allowed
if not request.context.get("prompt_data").get("username").isalnum():
    ak_message("Only numbers and letters in usernames allowed")
    return False
elif (len(request.context.get("prompt_data").get("username")) > 16):
    ak_message("Username too long, 16 character max")
    return False
else:
    return True