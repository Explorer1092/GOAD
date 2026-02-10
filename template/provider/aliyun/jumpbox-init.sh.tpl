#!/bin/bash

set -e

useradd -m -s /bin/bash {{ username }} || true
mkdir -p /home/{{ username }}/.ssh
chown -R {{ username }}:{{ username }} /home/{{ username }}/.ssh
