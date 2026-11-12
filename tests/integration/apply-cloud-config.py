#!/usr/bin/env python3
"""Minimal stand-in for cloud-init inside a container.

Installs the packages listed in a #cloud-config document and writes its
write_files entries. runcmd is handled by server.sh, because containers have
no systemd.
"""
import os
import subprocess
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as fh:
    text = fh.read()

if not text.startswith("#cloud-config\n"):
    sys.exit("user_data is not a #cloud-config document")

config = yaml.safe_load(text)

subprocess.run(["apt-get", "install", "-y", "-qq", *config["packages"]], check=True)

for entry in config["write_files"]:
    path = entry["path"]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(entry["content"])
    os.chmod(path, int(entry["permissions"], 8))
    print(f"wrote {path} ({entry['permissions']})")

for cmd in config["runcmd"]:
    print("runcmd:", " ".join(cmd))
