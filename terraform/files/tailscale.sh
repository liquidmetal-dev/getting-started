#!/bin/bash

curl -fsSL https://tailscale.com/install.sh | sh

tailscale up --advertise-routes=192.168.10.0/25 --authkey "$AUTH_KEY"
