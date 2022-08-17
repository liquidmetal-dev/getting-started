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

## Terraform an environment on Equinix

The scripts provided in the [terraform](terraform/) directory will bootstrap the
environment as described in the above tutorial.

The following will be provisioned:
- A new project
- A VLAN in that project
- A device to run our DHCP server and other routing concerns
- 'N' devices to at as MicroVM hosts

The following networking configuration will be applied:
- All devices will be configured in a Hybrid Bonded mode
- All devices will have a port connected to a VLAN
- A DHCP server will assign MicroVM addresses from a private range of `192.168.10.0/25`
- NAT and filter rules will forward egress traffic from the private interface to the default public one on the host
- A Tailscale VPN subnet router will route traffic from local VPN-connected devices to MicroVMs

### Requirements

- An [Equinix Account](https://metal.equinix.com/)
- A [Tailscale account](https://tailscale.com/)
- [Terraform](https://www.terraform.io/downloads)
- [Tailscale](https://tailscale.com/download)
- [direnv](https://direnv.net/), to help manage your environment variables
- [tfenv](https://github.com/tfutils/tfenv) to install and use specific Terraform versions

### Configuration

1. Clone this repo and change into the `terraform` directory:

    ```bash
    git clone git@github.com:weaveworks-liquidmetal/getting-started.git
    cd getting-started/terraform
    ```

1. Set up the local terraform environment:

    ```bash
    direnv allow
    tfenv install && tfenv use
    ```

1. Create a new key pair.

1. Connect your local machine to tailscale:

    For Linux users:
    ```bash
    sudo tailscale up --accept-routes
    ```
    For other OS users:
    ```bash
    sudo tailscale up
    ```

1. Create a new Tailscale [auth key](https://login.tailscale.com/admin/settings/keys).

1. Create a file called `terraform.tfvars.json` with the following contents, edited
to match your details:

    ```json
    {
      "org_id": "<YOUR ORG ID>",
      "metal_auth_token": "<YOUR EQUINIX AUTH TOKEN>",
      "ts_auth_key": "<YOUR TAILSCALE AUTH KEY>",
      "public_key": "<YOUR PUBLIC SSH KEY AS A STRING>",
      "private_key_path": "<PATH TO YOUR PRIVATE SSH KEY>"
    }
    ```

    The above fields are required, you can also set the following which are otherwise
    defaulted:

    ```json
    ...
      "project_name": "",
      "metro": "",
      "host_device_count": "",
      "server_type": "",
      "flintlock_version": "",
      "firecracker_version": "",
    ...
    ```

    _Note: check the CAPMVM<->Flintlock and Flintlock<->Firecracker compatibility tables
    [here](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/blob/main/docs/compatibility.md) and [here](https://github.com/weaveworks-liquidmetal/flintlock#compatibility) when setting component versions._

    _Note: Some variables have default resource limits: modify or remove the `validation` rules if required._

### Apply

Once you have set your variables, you can apply the plan:

```bash
terraform init
terraform plan
terraform apply
```

This may take a few minutes.

Take note of the `host_ips` in the output, you will need them when creating you
bare-metal cluster.

Once your `dhcp-nat` host is provisioned, navigate to your [Tailscale dash](https://login.tailscale.com/admin/machines),
and locate your `dhcp-nat` machine which should have just come online in your
network. On the machine page, click `Review` under the 'Subnets' section, and
toggle your range to 'enabled'.

### Test

### Using fl

You can test your flintlock hosts by using [fl](https://github.com/weaveworks-liquidmetal/fl):

```bash
fl microvm get --host <one of your host IPs>:9090

fl microvm create --host <one of your host IPs>:9090 --name mytest

fl microvm delete --host <one of your host IPs>:9090 <created mvm uid>
```

### Using Hammertime

You can test your flintlock hosts by using [hammertime](https://github.com/Callisto13/hammertime):

```bash
hammertime -a <one of your host IPs> create

hammertime -a <one of your host IPs> delete -i <created mvm uid>
```

### Troubleshoot

To troubleshoot issues with your MicroVMs or hosts, see the [troubleshooting guide](troubleshooting-hosts.md).

### Use

To configure your CAPI management cluster and create bare-metal workload clusters,
continue from [this section](capi.md) of the tutorial.

