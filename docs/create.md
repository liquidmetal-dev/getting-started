# Creating Liquid Metal clusters


If you have [provisioned your Liquid Metal systems](provision.md)
you can now create a cluster.

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace docs/create.md
-->

<!-- toc -->
- [Configuration](#configuration)
- [Create](#create)
- [Use your new cluster](#use-your-new-cluster)
- [Delete](#delete)
- [Troubleshooting](#troubleshooting)
<!-- /toc -->

## Configuration

Configure your cluster with your preferred settings. The following fields are required:

```sh
export CLUSTER_NAME=mvm-test
export WORKER_MACHINE_COUNT=1
```

Select an IP from your VLAN IP block range to use for the control plane address.
(For example, I am using a `192.168.1.0/25` CIDR and have set aside `192.168.1.26`
to `192.168.1.126` for my MicroVMs, so I can set `192.168.1.25` as my cluster
endpoint address. This is a naive configuration for the purposes of this demonstration.):
```sh
export CONTROL_PLANE_VIP=<ADDRESS>
```

Set the `HOST_ENDPOINT` to the address that the `flintlockd` server is
running on. (This is the one you configured when provisioning your host device.)
```sh
export HOST_ENDPOINT=<FLINTLOCK_ADDRESS>:9090
```

> Note: that the below template generation will use the `HOST_ENDPOINT` var to
add just one bare-metal host for static placement. If you created multiple hosts
in the previous steps of the tutorial you will need to edit the `cluster.yaml`
which will be generated in the next step and add to the static pool hosts list
in `MicrovmCluster`.

Again, ensure that the version is [compatible](https://github.com/weaveworks-liquidmetal/cluster-api-provider-microvm/blob/main/docs/compatibility.md) with that of Flintlock:

```bash
export CAPMVM_VERSION=<version>
```

Use `clusterctl` to generate a cluster manifest from the CAPMVM release template:

```sh
clusterctl generate cluster -i microvm:$CAPMVM_VERSION -f cilium $CLUSTER_NAME > cluster.yaml
```

> Note: The CAPMVM repo is private. If you do not have access, you will not be able to
download this template.

## Create

Perform a dry-run:

```sh
kubectl apply -f cluster.yaml --dry-run=server
```

And if you are happy, apply the manifest to create your cluster:

```sh
kubectl apply -f cluster.yaml
```

## Use your new cluster

CAPI will create a secret containing your new Liquid Metal cluster's kubeconfig
in the same namespace.

The secret will be named `<cluster-name>-kubeconfig` of type `cluster.x-k8s.io/secret`.

Use `jq` to extract the `base64` encoded config and save it to a file (set the namespace
if you changed it for your cluster previously):

```bash
kubectl get secret $CLUSTER_NAME-kubeconfig -o json | jq -r .data.value | base64 -d > config.yaml
```

We can then use that kubeconfig to interact with our Liquid Metal cluster:

```bash
kubectl --kubeconfig config.yaml get pods -A
NAMESPACE     NAME                                                   READY   STATUS    RESTARTS   AGE
kube-system   cilium-cls92                                           1/1     Running   0          1m
kube-system   cilium-nrqsd                                           1/1     Running   0          1m
kube-system   cilium-operator-595485c9f9-n2rxw                       1/1     Running   0          1m
kube-system   cilium-rvlwg                                           1/1     Running   0          1m
kube-system   coredns-558bd4d5db-bjzz4                               1/1     Running   0          1m
kube-system   coredns-558bd4d5db-jm4jl                               1/1     Running   0          1m
kube-system   etcd-mvm-test-control-plane-2dkqr                      1/1     Running   0          1m
kube-system   kube-apiserver-mvm-test-control-plane-2dkqr            1/1     Running   0          1m
kube-system   kube-controller-manager-mvm-test-control-plane-2dkqr   1/1     Running   0          1m
kube-system   kube-proxy-7zs6s                                       1/1     Running   0          1m
kube-system   kube-proxy-ghwdr                                       1/1     Running   0          1m
kube-system   kube-proxy-xrmfv                                       1/1     Running   0          1m
kube-system   kube-scheduler-mvm-test-control-plane-2dkqr            1/1     Running   0          1m
kube-system   kube-vip-mvm-test-control-plane-2dkqr                  1/1     Running   0          1m
```

> Note: you will either have to be connected to a VPN or be in the same network as
your MicroVMs to be able to connect to your cluster, depending on your network
setup.

## Delete

To delete your cluster, run:

```sh
kubectl delete clusters.cluster.x-k8s.io $CLUSTER_NAME
```

And to delete the cilium resource set:
```sh
kubectl delete clusterresourceset.addons.cluster.x-k8s.io/crs-cilium
kubectl delete configmap/cilium-addon
```

## Troubleshooting

To troubleshoot issues with your MicroVMs or hosts, see the [troubleshooting guide](troubleshooting-hosts.md).
