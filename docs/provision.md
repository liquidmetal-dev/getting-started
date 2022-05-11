# Provisioning a Liquid Metal system

Users are responsible for managing and provisioning their own bare-metal hosts
and networks.
You may use any method or tool you like to provision your liquid metal hosts, but
note that initially only one provisioner will be natively supported by Liquid Metal's dynamic
scheduler: Tinkerbell.
If you are using another host provisioner or method to prepare your hosts and network, you will
also be responsible for registering those hosts with CAPI to make them available
to the cluster creator (see [Creating Liquid Metal Clusters](create.md)).

More provisioners will be supported in the future.

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/provision.md
-->

<!-- toc -->
- [Getting started tutorial](#getting-started-tutorial)
  - [Requirements](#requirements)
  - [Check location capacity](#check-location-capacity)
  - [Create a VLAN](#create-a-vlan)
  - [Create bare-metal hosts](#create-bare-metal-hosts)
  - [Bootstrapping](#bootstrapping)
<!-- /toc -->

## Getting started tutorial

In this tutorial we are going to manually create some hosts which can be used
to either statically or dynamically place Kubernetes cluster nodes.

This tutorial assumes you have no network or devices already set up. You may skip
any sections where you already have something in place, or would prefer your own
configuration.

We are going to use [Equinix](https://metal.equinix.com/) create (at least)
2 hosts to be used for the following:
- A DHCP server and NAT router
- A MicroVM/Liquid Metal host (_you can create as many of these as you like_)

These will all be connected to one VLAN.

### Requirements

- An Equinix org/account
- An Equinix project in that org

### Check location capacity

Before creating anything, check for a Metro (aka Location) which has capacity
for the type of device we need.
One way to do this is to use the [Equinix CLI tool](https://metal.equinix.com/developers/docs/libraries/cli/)
and run `metal capacity get`. You will want a Facility labelled `normal`.

The machine playing the part of the MicroVM host will require an additional
spare disk to back the thinpool which will store Flintlock's image layers.
In Equinix, we are therefore looking for a 'Server' type which:
- Comes with a second SSD...
- which is **not** part of a RAID array mounted at root.

In this example I am going to use a `c3.small.x86` server/plan in the `am6` facility
in the Amsterdam metro. This plan has 2 disks, one of which is mounted for root,
the other is spare.

> Note: a deploy will fail if it transpires that there is not enough
capacity at your first-choice location.

To know how disks for each server type will be mounted, you can check [this doc](https://metal.equinix.com/developers/docs/storage/storage-options/).
_(Alternatively, you can use one of Equinix's storage solution plans.)_

### Create a VLAN

> Note: Check with your administrator for any VLANs which already
exist in your chosen Metro.

Navigate to your project page and hover over the 'IPs and Networks' tab. Click `Layer 2`
in the dropdown and then `+ Add New VLAN` or `+ Add VLAN`.

Use the Location we determined had suitable capacity above, in my case this is
`Amsterdam`.

Set the Description to anything you like.

Optionally you can set a VNID between `2-3999`. If you leave this blank an id
will be auto-assigned starting from `1000`.

Click `Add`.

### Create bare-metal hosts

In the Equinix UI hosts are called 'servers', whereas their API (and any clients
built to work with the API) calls them 'devices'. This tutorial uses the UI
but you can use an API client if you wish.

Navigate to your project page and select the 'Servers' tab. Click `+ New Server`
and choose 'On Demand' from the 3 options available.

Choose the same Location as you did for your VLAN, IPs and Gateway in the previous sections.
In my case this is Amsterdam.

Select the 'Server' type that we determined in the [capacity](#check-location-capacity)
section above. In this case I am using `c3.small.x86`.

For an Operating System, anything Linux will be suitable. We have tested
extensively with Ubuntu 20.04.

Under 'Select Number and Name Your Server(s)', increment the counter to have
a minimum of 2 devices. Name one `dhcp-nat` and the other(s) as you like.

> Note: We are creating all our hosts at once for expediency, even though they could
be configured separately with different specs since we are going to use them
for different things. You may create your hosts one at a time with dedicated
configuration if you so desire.

Under 'Optional Settings' toggle 'Customize SSH Access' to the 'on' position.
For some maddening reason, Equinix will try to add every Key in your project, and the
keys of every collaborator in your Org, to devices created via the UI.
Even more annoyingly, at least one 'Collaborator Key' must be selected. There
is an option to not have any keys attached if you are using the API directly,
but I cannot seem to find it in the UI. C'est la vie.

Select an SSH key which you can use, and finally, click 'Deploy Now'.

For reference, the settings I chose for this tutorial are as follows:
- Location: Amsterdam
- Server: 2 x c3.small.x86 (named: `dhcp-nat`, `host-1`)
- OS: Ubuntu 20.04
- 1 personal SSH Key

### Bootstrapping

Once created, each server must be configured based on its purpose:

- [Connect your servers to the VLAN](vlan.md)
- [Configure your DHCP server and NAT router](dhcp.md)
- [Configure your MicroVM Hosts](microvm-host.md)
- [Configure your CAPI management cluster](capi.md)

> Note: the VLAN and DHCP sections are suggestions; you may copy-paste for speed, or you may
follow your own network configuration practices and skip to the subsequent sections.
