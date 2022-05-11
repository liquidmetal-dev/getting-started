# Demoing static placement on Equinix hosts

This demo shows how to create a liquid metal cluster across 2 Equinix hosts
reachable via a VPN on your local machine.

<!--
To update the TOC, install https://github.com/kubernetes-sigs/mdtoc
and run: mdtoc -inplace demos/static-equinix/presenter-notes.md
-->

<!-- toc -->
- [Demoing static placement on Equinix hosts](#demoing-static-placement-on-equinix-hosts)
  - [Demo layout and style](#demo-layout-and-style)
  - [Prepping for the demo](#prepping-for-the-demo)
    - [Deploying the Equinix hosts](#deploying-the-equinix-hosts)
    - [Tools to install](#tools-to-install)
      - [Locally](#locally)
      - [On the Equinix hosts](#on-the-equinix-hosts)
    - [Commands to pre-run](#commands-to-pre-run)
  - [Running the demo](#running-the-demo)
    - [Top right](#top-right)
    - [Bottom right](#bottom-right)
    - [Top left](#top-left)
    - [Bottom left](#bottom-left)
<!-- /toc -->

## Demo layout and style

I present from a single terminal window using `tmux` to split the pane into 4.

I use one of the panes for slides, one for running "local" commands, and 2 for
looking at things on my Equinix hosts.

There is a video of this in action [here](https://drive.google.com/file/d/1ItYfV2CtbMK-1sAnXfcZEh33i4UpR61L/view?usp=sharing). If you don't want
to do the demo yourself you can just play this and talk over it.

All the commands you need to run will either be present in the slides, or be run
as part of the automated runner thingy.

The slides will have prompts for all the things you will want to talk about.

## Prepping for the demo

There are a couple of things you will want to do ahead of time.

In addition to this doc, you may want to read the "getting started" tutorial
from the [`Bootstrapping Cluster API`](../../docs/capi.md#bootstrapping-cluster-api) section.
You will basically just be following the tutorial along from there.

### Deploying the Equinix hosts

Follow the [terraform docs](../../docs/intro.md#terraform-an-environment-on-equinix).

Take note of the 2 host ips printed in the output.

### Tools to install

#### Locally

Kubernetes things:
- [kind](https://kind.sigs.k8s.io/)
- [docker](https://docs.docker.com/engine/install/ubuntu/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl)

> Note: there is a [handy gist](https://gist.github.com/Callisto13/617240630944c96730d5151ed308d29a)
to install the above on Linux.

Demo things:
- [`lookatme`](https://github.com/d0c-s4vage/lookatme)
- [`tmux`](https://github.com/tmux/tmux)
- [`neovim`](https://neovim.io/) or [`vim`](https://www.vim.org/)

#### On the Equinix hosts

I install `tree` so that I can run `watch tree -d 1 /var/lib/flintlock/vm/default`
on both and see the state dirs being created as they come up. It looks quite cool.

### Commands to pre-run

There are a few commands to run ahead of time.

You should create the management cluster:
```
kind create cluster
```

If CAPMVM is still a private repo, you also need to set up some auth access to the
image etc. Follow the [`Authenticate` section](../../docs/capi.md#authenticate) of the docs.

The demo will create and write to `~/.cluster-api/clusterctl.yaml`, so either delete
that or make a backup somewhere.

Check the value of `CAPMVM_VERSION` in `auto-script.sh` and make sure it is using
one compatible with the flintlock running on your hosts.

## Running the demo

### Top right

SSH into `host0` using the key you set in the terraform vars.

### Bottom right

SSH into `host1` using the key you set in the terraform vars.

### Top left

Start the slides:
```bash
cd <PATH-TO-REPO>/getting-started/demos/static-equinix
lookatme --live slides.md
```

To go to the next slide press space or an arrow key.

You can scroll down the slides with arrows to reveal more text.

### Bottom left

Start the command runner script:

```bash
export GITHUB_TOKEN=<the token you used above>
cd <PATH-TO-REPO>/getting-started/demos/static-equinix
./auto-script.sh
```

Pressing `enter` will either type out the next command or execute the one typed out.
