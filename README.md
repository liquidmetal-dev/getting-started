# :runner: Getting started with Liquid Metal

Want help/advice on getting started with Liquid Metal? Well this the place for you!

## Equinix demo environment

Follow the public documentation [here][lm-docs].

The `Tutorial: Equinix Platform` sections will take you through:
- Provisioning infrastructure on Equinix
- Creating a management CAPI cluster
- Creating a MicroVM workload cluster
- A guide to the Equinix Environment
- Troubleshooting common problems

_Note: that as there is no publicly released way of creating a Liquid Metal cluster
through Weave GitOps (there is no published template), that process is not documented
yet._

The tutorial instructs users to create a `main.tf`. If you are a Weaveworks member,
please instead clone this repo and use the manifests provided at [`terraform/`](terraform/).

## CLI based demo

There are some scripts, slides, and instructions on how to perform a CLI based demo
[here](demos/static-equinix).

## Step by step provisioning guide

A breakdown of how the Equinix build came to be can be found [here](docs/README.md). This is mainly
a record for posterity, or in case we need to remember something.

## Issues

The resources here will be expanding over time. We also :heart: contributions and suggestions.

If you see any issues with the getting started resources please [create a new issue](https://github.com/weaveworks-liquidmetal/getting-started/issues/new/choose).

[lm-docs]: https://weaveworks-liquidmetal.github.io/site/docs/category/tutorial-equinix-platform/
