---
title: liquid-metal
author: weaveworks
date: 2022-05-17
styles:
  author:
    bg: default
    fg: '#EABFF9'
  title:
    bg: default
    fg: '#EABFF9'
  slides:
    bg: default
    fg: '#EABFF9'
---

# Welcome to Liquid Metal

## In this demo...
- Overview of Liquid Metal components
- Creating a management CAPI cluster in a local kinD
- Creating a workload Bare Metal cluster via CAPMVM (cluster api provider microvm)
- Static, not dynamic, placement

## Assumed knowledge
- Cluster API (CAPI)

---

# The hosts

- Equinix machines, configured to run Liquid Metal components
- Will be hosts for MicroVMs running Kubernetes nodes
- 2 in this example
  - Any number can be used

## Flintlock

- The service which creates and manages MicroVMs

```bash
systemctl status flintlockd.service
```

## Containerd

- MicroVMs need a kernel and operating system
- Liquid Metal ships these as container images
- Containerd pulls, stores and mounts the base images used by the MicroVMs
  - Containerd is an internal component of docker

```bash
systemctl status containerd.service
```

## Firecracker

- Tool used by flintlockd to launch lightweight virtual machines
- A binary which will be executed for each MicroVM, running them as processes

---

# The network

- Basic yet practical networking setup
- Aim to do as much as possible in private networks

## Private addresses for MicroVMs

- All hosts connected to a VLAN
  - Private subnet
-  MicroVMs assigned a private address from that subnet
  - DHCP server
- NAT and filter rules applied
  - MicroVMs need egress traffic

## Private address for the cluster endpoint

- Eventual cluster endpoint will be private
- Address from the private subnet

## VPN for cluster and MicroVM access from local workstations

- VPN configured to route traffic from VLAN subnet
  - Tailscale VPN
- Connected to our local workstation(s)

---

# Create a CAPI management cluster

- CAPI workload clusters coordinated via a management cluster
- Management clusters can be run anywhere

## kinD

- Kind is a good option
  - Run a small Kubernetes cluster in a Docker container

```bash
kind create cluster
```

## CAPMVM

- Liquid Metal ships a custom CAPI infrastructure provider
  - Cluster API Provider MicroVM (capmvm)
  - Works with CAPI to create MicroVMs on our bare metal hosts
  - CAPI will then schedule Kubernetes nodes on those MicroVMs

### Configure `clusterctl`

- `clusterctl` installs the CAPI controllers in the management cluster
- Config file instructs `clusterctl` where to find the custom provider image and how to run it

```bash
export CAPMVM_VERSION=v0.5.1
mkdir -p ~/.cluster-api

cat << EOF >>~/.cluster-api/clusterctl.yaml
providers:
  - name: "microvm"
    url: "https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/releases/$CAPMVM_VERSION/infrastructure-components.yaml"
    type: "InfrastructureProvider"
EOF
```

### Configure CAPI

- Enable Cluster Resource Set feature flag in CAPI
  - So we can use Cilium for our microvm cluster's CNI.

```bash
export EXP_CLUSTER_RESOURCE_SET=true
```

### Initialise the cluster

Now we can initialise the local cluster as a management cluster.

```bash
clusterctl init --infrastructure microvm
```

---

# Creating a microvm cluster

- Export some simple configuration.

```bash
export CLUSTER_NAME=mvm-test
export CONTROL_PLANE_MACHINE_COUNT=1
export WORKER_MACHINE_COUNT=5
```

- Configure the control plane endpoint address
  - Here a private address from my Equinix host's VLAN.

```bash
export CONTROL_PLANE_VIP="192.168.10.25"
```

- Use `clusterctl` to generate a manifest definition for the microvm cluster

```bash
clusterctl generate cluster \
  --infrastructure microvm:$CAPMVM_VERSION \
  --flavor cilium \
  $CLUSTER_NAME > cluster.yaml
```

---

# Inspecting the `cluster.yaml` manifest

- `cluster.yaml` is a Kubernetes object manifest
  - Instructs the CAPI controllers and the CAPMVM controller how to build the cluster
- We can see instructions for how to deploy control plane and worker nodes
- Generated template is a "getting started" point
- For clusters across multiple hosts, we will need to edit the manifest
  - Add the endpoints for each of our Equinix hosts

```yaml
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: MicrovmCluster
metadata:
  name: mvm-test
  namespace: default
spec:
  controlPlaneEndpoint:
    host: 192.168.10.25
    port: 6443
  placement:
    staticPool:
      hosts:
      - controlplaneAllowed: true
        endpoint: 147.75.80.43:9090
      - controlplaneAllowed: true
        endpoint: 147.75.80.45:9090
```

---

# Creating a microvm cluster

We can now use `kubectl` to apply our manifest and create our cluster.

```bash
kubectl apply -f cluster.yaml
```

(If you have access to your MicroVM hosts, you can watch the MicroVMs coming up
by looking at the `/var/lib/flintlock/vm/<namespace>/<name>` directory.)

---

# Using our microvm cluster

- The microvm cluster's kubeconfig can be found in a secret
  - Named `<cluster-name>-kubeconfig`
  - This is created almost immediately by CAPI
    - The cluster may not be ready, by the config is
- We can extract and decode this config with `jq` and `base64 -d`

```bash
kubectl get secret $CLUSTER_NAME-kubeconfig -o json | \
  jq -r .data.value | \
  base64 -d > config.yaml
```

- Use this config to watch the nodes come up

```bash
kubectl --kubeconfig config.yaml get nodes
```

- And inspect the pods

```bash
kubectl --kubeconfig config.yaml get pods -A
```

---

# That's all folks

# Thank you for watching :)

# Questions?
