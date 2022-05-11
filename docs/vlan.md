## Connect each server to the VLAN

### In the Equinix UI

Once your servers are created and have been assigned an IP, use the UI to assign the
VLAN to the server interface port.

From the 'Servers' tab on your project page, do this for each server you created:
- Select the server
- Click on the 'Network' tab on the left hand menu
- Click `Convert to Other Network Type`
- Select `Hybrid` and then choose `Bonded`
- Select your VLAN from the dropdown
- Click `Assign New VLAN and Convert to Hybrid Networking`

### On each device

Now configure each server to use the VLAN port. Use the key you assigned
earlier to SSH on to each:

```bash
ssh -i <path to private key> root@<ip> # or use the hostname if you have it set up
```

Perform the following steps to connect them to your VLAN.

Enable VLAN support:
```bash
modprobe 8021q
echo "8021q" >> /etc/modules-load.d/networking.conf
```

Add the VLAN to the `bond0` interface. Check your Equinix dash for the VNID.
```bash
ip link add link bond0 name bond0.<VLAN_ID> type vlan id <VLAN_ID>
```

Add an address from **an internal address block of your choosing** to the
VLAN **ensuring that you choose a different address within the range for each
device**. For this I am using `192.168.1.0/25` as I don't need much for the
purposes of this demo.
```bash
ip addr add <IP_ADDRESS> dev bond0.<VLAN_ID>
# for example: ip addr add 192.168.1.2/25 dev bond0.1000
```

Ensure the interface is up:
```bash
ip link set dev bond0.<VLAN_ID> up
```

And check that everything worked:
```bash
ip -d link show bond0.<VLAN_ID>
```

Optionally, you can make the changes survive restarts by adding the following
to `/etc/network/interfaces`:

```bash
cat <<FOE >> /etc/network/interfaces

auto bond0.VLAN_ID
iface bond0.VLAN_ID inet static
  pre-up sleep 5
  address <IP_ADDRESS>
  netmask <MASK>
  vlan-raw-device bond0
FOE
```

## Next Steps

Take a note of the of these VLAN addresses of your MicroVM Host(s) for use later.
You can now move to to the next section: [configuring your DHCP server](dhcp.md).
