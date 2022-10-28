# Liquid Metal

> This is the original version of the Equinix build docs. There are now easier
  to use [terraform modules](/terraform/) and [docs](https://weaveworks-liquidmetal.github.io/site/docs/category/tutorial-equinix-platform/).
  This folder serves as an archive.

The Liquid Metal project encompasses a group of components which together can
be used to create and manage Kubernetes Clusters on bare metal.

These components are:
- **Cluster API Provider MicroVM (CAPMVM)**: An infrastructure provider which
  "plugs in" to Cluster API to declaratively create the bare-metal infrastructure
  for clusters.
- **Scheduler** (better name pending): A scheduler which dynamically places
  Kubernetes nodes on the most appropriate bare-metal host.
- **Flintlock**: A service for creating and managing the lifecycle of MicroVMs
- **Firecracker**: A tool to create MicroVMs

## Tutorial: getting started

This tutorial will take you through the manual steps of provisioning your Liquid
Metal system. For a "ready-made" environment, see below.

To complete this tutorial you will need an Equinix account. As part of this
tutorial we will be creating multiple servers and a rudimentary example network
setup.

There are 2 phases to preparing a Liquid Metal system:
1. [Host provisioning](provision.md)
2. [CAPI Bootstrapping](capi.md)

If you already have a set of bare-metal hosts running Flintlock in an appropriate
VLAN with a NAT router and DHCP server, you can skip to [phase 2](capi.md).

If you already have a set of hosts and a management CAPI cluster, you can skip
to [creating a bare-metal Kubernetes cluster](create.md).
