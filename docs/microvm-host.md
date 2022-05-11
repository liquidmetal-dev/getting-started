## Configure your MicroVM Host

This tutorial will use the Flintlock provisioning tool to bootstrap hosts in
one action. For explicit details on how to configure your hosts,
follow the ['Step-by-step manual tutorial'](manual.md).

> Note: Liquid metal MicroVMs can **only** be run on Linux.

Each MicroVM host will be provisioned with the following:

- A direct-lvm thinpool
- [Firecracker](https://github.com/weaveworks-liquidmetal/firecracker/releases) (you must use a release from the feature fork)
- [Containerd](https://github.com/containerd/containerd/releases)
- [Flintlock](https://github.com/weaveworks-liquidmetal/flintlock/releases)

Use the key you assigned earlier to SSH on to your MicroVM host(s):

```bash
ssh -i <path to private key> root@<ip> # or use the hostname if you have it set up
```

Download the Flintlock provisioning tool:
```bash
wget https://raw.githubusercontent.com/weaveworks-liquidmetal/flintlock/main/hack/scripts/provision.sh
chmod +x provision.sh
```

Determine the name of a spare unmounted and unpartitioned device:

```bash
# locate an unused disk
lsblk # or fdisk -l
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 447.1G  0 disk
├─sda1   8:1    0     2M  0 part
├─sda2   8:2    0   1.9G  0 part [SWAP]
└─sda3   8:3    0 445.2G  0 part /
sdb      8:16   0 447.1G  0 disk        # <---- this one looks good
```

> Note: the provision tool can autodetect a free disk, but relying on this is
not recommended. During the bootstrapping process this disk will have all its data
overwritten, therefore it is preferred that users ensure the disk is available.

Determine the host's public IP (the one you used to SSH).

Determine the VLAN tagged interface. This will be the device you added the above
address to. In my case this is `bond0.1000` where `1000` is my VLAN id as noted
in my Equinix dash.

Our Liquid Metal system will use Cluster API Provider MicroVM to connect to the
Flintlock daemon on our bare-metal hosts. Consult the [compatibility table](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/blob/main/docs/compatibility.md)
and select the latest Flintlock version from the table. Note the corresponding
CAPMVM version for later.

```bash
export FLINTLOCK=<flintlock-version>
```

TODO: auth

Run the tool **as root**:

```bash
./provision.sh all --disk <disk name> --grpc-address <host ip> --parent-iface <interface>
```

> Note: docs for the provision tool can be found [here](https://github.com/weaveworks-liquidmetal/flintlock/blob/provision/hack/scripts/README.md).

Once the tool has run, the host is ready.

You can verify that the flintlockd server is running with:

```bash
systemctl status flintlockd.service
```

If you like you can test it out by creating a microvm
with [this tool](https://github.com/Callisto13/hammertime).

```bash
hammertime -a <address> create
```

## Troubleshooting

To investigate potential issues with Flintlock, Firecracker, Containerd or your
MicroVMs, read the guide [here](troubleshooting-hosts.md).

## Next Steps

Take a note of the of the address(es) of your MicroVM Host(s) for use later.
You can now move to to the next section: [configuring your CAPI management cluster](capi.md).
