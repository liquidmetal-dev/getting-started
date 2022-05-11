# Bootstrapping Cluster API

Liquid Metal's orchestrator, which will interact with our new host(s) and flintlock
service(s), is [CAPMVM](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm).
This works as part of Cluster API, so we need to use both to create our bare-metal cluster.

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/capi.md
-->

<!-- toc -->
- [Setup](#setup)
  - [Install required tools](#install-required-tools)
  - [Set configuration](#set-configuration)
  - [Apply the CAPI and CAPMVM controllers](#apply-the-capi-and-capmvm-controllers)
  - [Next Steps](#next-steps)
<!-- /toc -->

# Setup

For the purposes of this tutorial, and for simplicity, we are going to use a Kind
cluster to run our CAPI management cluster. You can create this cluster anywhere,
including on your local machine.

If you set up a Tailscale VPN earlier in the tutorial, you can follow the rest of
the walkthrough from your local machine (or any other which you connected to your
Tailscale network).

If you did **not** set up a VPN, first you need to SSH back on to your `dhcp-nat`
device and complete the remainder of the tutorial from there.

## Install required tools

Install the following:
- [kind](https://kind.sigs.k8s.io/)
- [docker](https://docs.docker.com/engine/install/ubuntu/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl)

> Note: there is a [handy gist](https://gist.github.com/Callisto13/617240630944c96730d5151ed308d29a)
to install the above on Linux.

And run:
```bash
kind create cluster
```

## Set configuration

To add the Cluster API Provider MicroVM, we first need to create a `clusterctl` config file.

Set the version of CAPMVM to that which is [compatible](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/blob/main/docs/compatibility.md)
with the version of Flintlock you provisioned your metal hosts with.

```bash
export CAPMVM_VERSION=<version>
```

And create the file:

```sh
mkdir -p ~/.cluster-api

cat << EOF >>~/.cluster-api/clusterctl.yaml
providers:
  - name: "microvm"
    url: "https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/releases/$CAPMVM_VERSION/infrastructure-components.yaml"
    type: "InfrastructureProvider"
EOF
```

Enable the Cluster Resource Set feature flag (this is so we can use [Cilium](https://cilium.io/) in the
next step):

```bash
export EXP_CLUSTER_RESOURCE_SET=true
```

## Apply the CAPI and CAPMVM controllers

We can now initialize the management cluster:

```sh
clusterctl init -i microvm
```

> Note: if you do not have access to the [cluster-api-provider-microvm repo](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm)
you will not be able to install this provider.

## Next Steps

You are now ready to [create microvm based Kubernetes clusters](create.md).
