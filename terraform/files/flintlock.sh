#!/bin/bash

wget https://raw.githubusercontent.com/weaveworks-liquidmetal/flintlock/main/hack/scripts/provision.sh
chmod +x provision.sh

# this pins containerd while I work out a gcc version thing
# and also runs flintlock without any auth
# later i will update this TF to make setting certs configurable, but
# for now if you want to do that you will have to do some manual editing
# of this file before you tf apply
CONTAINERD="v1.6.6" ./provision.sh all -y \
  --grpc-address "0.0.0.0:9090" \
  --parent-iface "bond0.$VLAN_ID" \
  --insecure
