#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

# hide the evidence
clear

# Demo time!

# slide 4
pe "kubectl get pods -A"
pe "export CAPMVM_VERSION=v0.5.1"
pe "mkdir -p ~/.cluster-api"
# rm ~/.cluster-api/clusterctl.yaml
cat << EOF >>~/.cluster-api/clusterctl.yaml
providers:
  - name: "microvm"
    url: "https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/releases/$CAPMVM_VERSION/infrastructure-components.yaml"
    type: "InfrastructureProvider"
EOF
pe "nvim ~/.cluster-api/clusterctl.yaml"
pe "export EXP_CLUSTER_RESOURCE_SET=true"
pe "clear"
pe "clusterctl init --infrastructure microvm"
pe "clear"

# slide 5
pe "export CLUSTER_NAME=mvm-test"
pe "export CONTROL_PLANE_MACHINE_COUNT=1"
pe "export WORKER_MACHINE_COUNT=5"
pe "export CONTROL_PLANE_VIP=192.168.10.25"
pe "clusterctl generate cluster -i microvm:$CAPMVM_VERSION -f cilium $CLUSTER_NAME > cluster.yaml"

# slide 6
pe "nvim cluster.yaml"
pe "clear"

# slide 7
pe "kubectl apply -f cluster.yaml"

# slide 8
pe "kubectl get secret $CLUSTER_NAME-kubeconfig -o json | jq -r .data.value | base64 -d > config.yaml"
pe "watch kubectl --kubeconfig config.yaml get nodes"
pe "clear"
pe "kubectl --kubeconfig config.yaml get pods -A"
pe "clear"
