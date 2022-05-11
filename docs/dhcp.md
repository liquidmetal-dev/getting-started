## Configure your DHCP server, NAT routing, and VPN

> Note: Check with your administrator for a DHCP server or any NAT routing
which may already exist in this VLAN.

Use the key you assigned earlier to SSH on to your `dhcp` host:

```bash
ssh -i <path to private key> root@<ip> # or use the hostname if you have it set up
```

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/dhcp.md
-->

<!-- toc -->
  - [DHCP](#dhcp)
  - [NAT](#nat)
  - [VPN (optional)](#vpn-optional)
    - [Set up the subnet router](#set-up-the-subnet-router)
- [Next Steps](#next-steps)
<!-- /toc -->

### DHCP

Install the server we will be using:

```bash
apt install -y isc-dhcp-server
```

Create a backup of the dhcp config file:

```bash
mv /etc/dhcp/dhcpd.conf{,.backup}
```

Write a new config file using a pool from our [VLAN address block's](vlan.md#on-each-device)
subnet:

```bash
cat <<EOF >/etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.1.0 netmask 255.255.255.128 {
  range 192.168.1.26 192.168.1.126;
  option routers 192.168.1.2;
  option domain-name-servers 147.75.207.207, 147.75.207.208;
}
EOF
```
Edit the file to match your settings.

Here I have taken the last 100 available IPs from my `/25` block and used
them as my lease pool range.
The `option routers` (gateway) is set to the address I assigned to the device
that the DHCP server will run on.

For convenience I am using the upstream `domain-name-servers` as used by this device
(you can find this by running `resolvectl status`), but you may configure this to
point to others if you wish.

Open `/etc/default/isc-dhcp-server` and set the v4 interface to our tagged VLAN one:

```
INTERFACESv4="bond0.<VLAN_ID>"
```

Finally we can restart the server and check the status:

```bash
systemctl restart isc-dhcp-server.service
systemctl status isc-dhcp-server.service
```

### NAT

Our MicroVMs will only receive private addresses from our VLAN pool. We need to set
routes so that they are able to download the images required to run Kubernetes
pods.

For this I am using `firewall-cmd` but you may use whichever tool you wish to
set these rules.

Install `firewall-cmd`:
```bash
apt install -y firewalld
```

Enable port forwarding by opening `/etc/sysctl.conf` and setting `ip_forward` to `1`:
```
net.ipv4.ip_forward = 1
```

Set the changes:

```bash
sysctl -p
```

Add a rule to forward any traffic from our internal VLAN interface to the external
parent interface (don't forget to replace the `VLAN_ID` with your own):
```bash
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i bond0.<VLAN_ID> -o bond0 -j ACCEPT
```

Add a rule to ensure that return packets are sent back to the internal address
which made the original call out through the public interface:
```bash
firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -o bond0 -j MASQUERADE
```

Make the changes take effect:
```bash
firewall-cmd --reload
```

### VPN (optional)

> Note: This section is only required if you want to connect to your Liquid Metal
cluster from outside the private VLAN, eg from your work station. You can skip this
if you plan to connect to your cluster from inside an Equinix host.

For this we are going to use [Tailscale](https://tailscale.com/), a super magical
VPN which requires the most minimal of config.

First, sign up for a free account, and [install Tailscale](https://tailscale.com/download/linux)
on your local machine.

**If you are running on Linux**, when it comes to the instruction to run
`tailscale up` add the `--accept-routes` flag. This is because we are going
to set up a subnet router in the next step:

```bash
# required for linux only, other OSes can skip that flag.
sudo tailscale up --accept-routes
```

#### Set up the subnet router

SSH back on to your `dhcp-nat` host.

[Install Tailscale](https://tailscale.com/download/linux) onto the host.
**Do not start the service** just yet (do not run `tailscale up`).

Navigate to your Tailscale dashboard, and [create a new Auth key](https://login.tailscale.com/admin/settings/keys).
Copy the key.

Start the Tailscale service with both the auth key and the subnet we used earlier
to create our VLAN, in my case this was `192.168.1.0/25`:

```bash
tailscale up --advertise-routes=<PRIVATE_VLAN_RANGE> --authkey <YOUR_AUTH_KEY>
```

Lastly, navigate back to your Tailscale dash, and locate your `dhcp-nat` machine
which should have just come online in your network. On the machine page, click
`Review` under the 'Subnets' section, and toggle your range to 'enabled'.

## Next Steps

You can now move to to the next section: [configuring your MicroVM hosts](microvm-host.md).
