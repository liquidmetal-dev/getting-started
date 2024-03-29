# Liquid Metal

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


<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/intro.md
-->

<!-- toc -->
- [Liquid Metal](#liquid-metal)
  - [Tutorial: getting started](#tutorial-getting-started)
  - [Terraform an environment on Equinix](#terraform-an-environment-on-equinix)
    - [Requirements](#requirements)
    - [Configuration](#configuration)
    - [Apply](#apply)
    - [Test](#test)
    - [Using fl](#using-fl)
    - [Using Hammertime](#using-hammertime)
    - [Troubleshoot](#troubleshoot)
    - [Use](#use)
<!-- /toc -->

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
