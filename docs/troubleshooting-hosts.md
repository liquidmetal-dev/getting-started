# Troubleshooting

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/troubleshooting-hosts.md
-->

<!-- toc -->
- [Troubleshooting](#troubleshooting)
  - [Accessing MicroVMs](#accessing-microvms)
    - [Adding keys via CAPMVM](#adding-keys-via-capmvm)
    - [Adding keys via a GRPC client](#adding-keys-via-a-grpc-client)
  - [Containerd](#containerd)
  - [Firecracker](#firecracker)
  - [Flintlock](#flintlock)
  - [MicroVMs](#microvms)
  - [My microvm has no internet](#my-microvm-has-no-internet)
  - [My microvm cannot resolve](#my-microvm-cannot-resolve)
<!-- /toc -->

## Accessing MicroVMs

### Adding keys via CAPMVM

To add your Public key to your CAPMVM created MicroVMs, update the `MicrovmCluster`
part of your `cluster.yaml` to contain the following:

```yaml
...
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: MicrovmCluster
  ...
spec:
  sshPublicKey: "ssh-ed25519 foobar yourname@your.domain"
  controlPlaneEndpoint:
  ... etc
```

### Adding keys via a GRPC client

If you are using a GRPC client to connect with the flintlock service directly,
you will need to create a microvm with your public key base64 encoded into the
vendor-data of [the spec](https://github.com/Callisto13/hammertime/blob/main/example.json).

```
#cloud-config
hostname: mvm0
users:
- name: root
  ssh_authorized_keys:
  - |
    ssh-ed25519 foobar yourname@your.domain
final_message: The Liquid Metal booted system is good to go after $UPTIME seconds
bootcmd:
- ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

You can then pass your json to a client.

If you are using [hammertime](https://github.com/Callisto13/hammertime), you can
skip encoding your key, and simply pass a file to the create command:

```bash
hammertime -a <address> create -k <path to public key>
```
## Containerd

Liquid Metal uses [containerd](https://github.com/containerd/containerd) to manage
OS and Kernel images for MicroVMs.

If you provisioned your hosts following the instructions in this guide, then
Container will be running as a systemd service.

You can see the status of the service with `systemctl status containerd.service`.

Logs can be found by running `journalctl -u containerd.service`.

There is a cli tool [ctr](https://www.mankier.com/8/ctr) which will be present
on your hosts which you can use to inspect `images`, `snapshots` and `leases`.
They will be namespaced under `flintlock`.

## Firecracker

Liquid Metal is built around [Firecracker MicroVMs](https://github.com/firecracker-microvm/firecracker).
We use a [fork](https://github.com/weaveworks-liquidmetal/firecracker/tree/feature/macvtap)
which is regularly kept aligned with the upstream repo.

Firecracker MicroVMs run as processes which you can inspect, the PID is saved to
`/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.pid`.

> Note: If you are using Flintlock <= `v0.1.0-alpha.5`, then the state path does
not contain the `uuid` dir. Ie the path for the pid file, and all others,
will stop at `<name>`: `/var/lib/flintlock/vm/<namespace>/<name>/firecracker.pid`

The config a MicroVM is started with is written at `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.cfg`.
Firecracker logs to `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.log`.

Metrics can be found at `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.metrics`.

## Flintlock

Liquid Metal uses [Flintlock](https://github.com/weaveworks-liquidmetal/flintlock) to manage
the lifecycle of Firecracker MicroVMs.

If you provisioned your hosts following the instructions in this guide, then
Flintlock will be running as a systemd service.

You can see the status of the service with `systemctl status flintlockd.service`.

Logs can be found by running `journalctl -u flintlockd.service`.

The [hammertime](https://github.com/Callisto13/hammertime) cli tool can be used to inspect
and handle your MicroVMs if you wish to bypass CAPMVM.

## MicroVMs

Flintlock MicroVMs log to `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.stdout`
and `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.stderr`.

You can debug further by adding an SSH key to your MicroVMs. See below for instructions
based on your deployment method.

Once your MicroVM is created, you can discover the assigned IP by looking at the
stdout log file `/var/lib/flintlock/vm/<namespace>/<name>/<uuid>/firecracker.stdout`.

Example log output:
```
[   14.035547] cloud-init[948]: ci-info: ++++++++++++++++++++++++++++++++++++++++Net device info+++++++++++++++++++++++++++++++++++++++++
[   14.036201] cloud-init[948]: ci-info: +--------+-------+------------------------------+-----------------+--------+-------------------+
[   14.036823] cloud-init[948]: ci-info: | Device |   Up  |           Address            |       Mask      | Scope  |     Hw-Address    |
[   14.037447] cloud-init[948]: ci-info: +--------+-------+------------------------------+-----------------+--------+-------------------+
[   14.038071] cloud-init[948]: ci-info: | bond0  | False |              .               |        .        |   .    | 3e:51:d4:c2:cb:71 |
[   14.038692] cloud-init[948]: ci-info: | dummy0 | False |              .               |        .        |   .    | 82:c9:95:a0:b6:a8 |
[   14.039329] cloud-init[948]: ci-info: |  eth0  |  True |         169.254.0.1          |   255.255.0.0   | global | aa:ff:00:00:00:01 |
[   14.039954] cloud-init[948]: ci-info: |  eth0  |  True |   fe80::a8ff:ff:fe00:1/64    |        .        |  link  | aa:ff:00:00:00:01 |
[   14.040572] cloud-init[948]: ci-info: |  eth1  |  True |         192.168.10.92         | 255.255.255.128 | global | 72:bf:3d:dd:7b:f3 |
[   14.041193] cloud-init[948]: ci-info: |  eth1  |  True | fe80::70bf:3dff:fedd:7bf3/64 |        .        |  link  | 72:bf:3d:dd:7b:f3 |
[   14.041813] cloud-init[948]: ci-info: |   lo   |  True |          127.0.0.1           |    255.0.0.0    |  host  |         .         |
[   14.042429] cloud-init[948]: ci-info: |   lo   |  True |           ::1/128            |        .        |  host  |         .         |
[   14.043054] cloud-init[948]: ci-info: +--------+-------+------------------------------+-----------------+--------+-------------------+
```

In this case my assigned IP is `192.168.10.92`.

I can then use my private key to SSH: `ssh -i <private-key> root@192.168.10.92`.

## My microvm has no internet

If your mvm is failing to `ping`, SSH onto your `dhcp-nat` device and check your
firewall rules.

Go back to the [NAT](dhcp.md#nat) section and add the rules if you forgot them.

If this does not work, check your network interfaces:

```bash
ip a
```
If you do not see the `bond0.1000@bond0` interface, or if it does not have a
`192.168.10.x` address, go back to the [VLAN](vlan.md) section.

## My microvm cannot resolve

On your `dhcp-nat` device, heck your `/etc/dhcp/dhcpd.conf` settings and make sure
that your `domain-name-servers` are set correctly. This guide uses `147.75.207.207, 147.75.207.208`.
