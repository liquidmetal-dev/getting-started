#!/bin/bash

sudo apt-get install -y socat ebtables ethtool conntrack

# To do: do we need to add host name to /etc/hosts
cat /etc/hosts

curl -L https://github.com/vmware-tanzu/cluster-api-provider-bringyourownhost/releases/download/v0.3.0/byoh-hostagent-linux-amd64 -o ~/byoh-hostagent-linux-amd64
chmod +x ~/byoh-hostagent-linux-amd64

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --accept-routes --authkey "$AUTH_KEY"