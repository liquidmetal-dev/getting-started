# Bootstrap host manually

If you would rather bootstrap your hosts manually, or wish to develop your own
automation, follow this step-by-step guide.

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/manual.md
-->

<!-- toc -->
- [Bootstrap host manually](#bootstrap-host-manually)
  - [Firecracker](#firecracker)
  - [Thinpool](#thinpool)
  - [Containerd](#containerd)
  - [Flintlock](#flintlock)
<!-- /toc -->

SSH onto your host:

```bash
ssh -i <path to private key> root@<ip> # or use the hostname if you have it set up
```

> Note: You will have to run most, if not all, the following bootstrap commands as
a privileged user.

## Firecracker

Liquid Metal relies on a feature of firecracker which is not yet released in the
upstream repo. Therefore we maintain our own fork, and create releases based
on latest of the upstream project along with the feature we require.

Install the latest feature release from [here](https://github.com/weaveworks-liquidmetal/firecracker/releases).

## Thinpool

Flintlock uses containerd's devmapper snapshotter to manage microvm volume layers.
To store the layers and snapshots we need to provide a thinpool backed by a blank
block-device.

> Note: If you do not have a spare block device you can provision a thinpool
using sparse files and loop devices (see this script [here](https://github.com/weaveworks-liquidmetal/flintlock/blob/main/hack/scripts/devpool.sh)),
but please be aware that this is not a production-ready setup.

To provision the Direct LVM thinpool, you can run [this script](https://github.com/weaveworks-liquidmetal/flintlock/blob/main/hack/scripts/direct_lvm.sh)
on your device:

```sh
curl https://raw.githubusercontent.com/weaveworks-liquidmetal/flintlock/main/hack/scripts/direct_lvm.sh > direct_lvm.sh
chmod +x direct_lvm.sh

lsblk # discover name of spare block device

./direct_lvm.sh -d <device name>
```

This will create a thinpool named `flintlock-thinpool`.

You can read more about this setup, and see individual instructions, in the
[docker docs](https://docs.docker.com/storage/storagedriver/device-mapper-driver/#configure-direct-lvm-mode-for-production).

## Containerd

Install [containerd](https://github.com/containerd/containerd/releases) on the host
at `/usr/local/bin/containerd`.

Create containerd's state, config and run directories:

```bash
mkdir -p /var/lib/containerd/snapshotter/devmapper
mkdir -p /run/containerd/
mkdir -p /etc/containerd/
```

Create a file `/etc/containerd/config.toml` containing the following:

```sh
cat << 'EOF' >> /etc/containerd/config.toml
version = 2

root = "/var/lib/containerd"
state = "/run/containerd"

[grpc]
  address = "/run/containerd/containerd.sock"

[metrics]
  address = "127.0.0.1:1338"

[plugins]
  [plugins."io.containerd.snapshotter.v1.devmapper"]
    pool_name = "flintlock-thinpool"
    root_path = "/var/lib/containerd/snapshotter/devmapper"
    base_image_size = "10GB"
    discard_blocks = true

[debug]
  level = "trace"
EOF
```

> Note: remember to change the value of `pool_name` if you chose a different one.

We will be using systemd to run containerd.
Create a containerd service file:

```bash
curl https://raw.githubusercontent.com/containerd/containerd/main/containerd.service > /etc/systemd/system/containerd.service
chmod 0664 /etc/systemd/system/containerd.service
```

Enable and start the service:

```bash
systemctl enable containerd
systemctl start containerd
```

Verify that it is running with `systemctl status containerd`. Logs can be seen
with `journalctl -u containerd`.

## Flintlock

Install the [latest flintlock release](https://github.com/weaveworksliquidmetal/flintlock/releases)
on the host at `/usr/local/bin/flintlockd`.

We will also be using systemd to run flintlock.
Create a flintlock service and environment file:

```bash
curl https://raw.githubusercontent.com/weaveworks-liquidmetal/flintlock/main/flintlockd.service > /etc/systemd/system/flintlockd.service
chmod 0664 /etc/systemd/system/flintlockd.service
```

Set the correct network argument:
```bash
PARENT=$(ip route show | awk '/default/ {print $5}')
sed -i "s/PARENT_IFACE/$PARENT_IFACE/" /etc/systemd/system/flintlockd.service
```

Enable and start the service:

```bash
systemctl enable flintlockd
systemctl start flintlockd
```

Verify that it is running with `systemctl status flintlockd`. Logs can be seen
with `journalctl -u flintlockd`.

When you see that the flintlock service has successfully started, your host
is fully bootstrapped! If you like you can test it out by creating a microvm
with [this tool](https://github.com/Callisto13/hammertime).

If you created multiple hosts earlier, repeat all the steps above.
